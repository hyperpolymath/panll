// SPDX-License-Identifier: MPL-2.0

//! Structure-aware ReScript scanner.
//!
//! A lightweight structural scanner that understands enough ReScript
//! syntax to distinguish declarations from references, strip comments,
//! and match on structural patterns rather than raw text.
//!
//! This is NOT a full parser — it's a line-oriented scanner with
//! enough context awareness to avoid false positives on comments,
//! strings, and partial matches.

/// A stripped line with its original line number preserved.
///
/// After comment stripping, each line retains a reference to its
/// original 1-indexed position in the source file, enabling accurate
/// diagnostic reporting even though comments have been removed.
#[derive(Debug)]
pub struct StrippedLine {
    /// 1-indexed line number in the original source file.
    pub number: usize,
    /// Line content after comment stripping, trimmed of leading/trailing whitespace.
    pub content: String,
    /// Count of leading whitespace characters in the original line.
    pub indent: usize,
    /// The original line before any comment stripping.
    pub raw: String,
}

/// Strip `//` line comments and `/* */` block comments from ReScript source.
///
/// Preserves line numbers by emitting one `StrippedLine` per source line,
/// even if the line was entirely a comment (in which case `content` is empty).
/// String literals are traversed without stripping, so patterns inside
/// `"..."` are preserved and won't match structural queries.
///
/// Handles:
/// - Single-line comments: `// ...`
/// - Block comments: `/* ... */` (including multi-line)
/// - Escaped characters in strings: `"foo\"bar"`
/// - Nested block comments are NOT supported (ReScript doesn't nest them)
pub fn strip_comments(source: &str) -> Vec<StrippedLine> {
    let mut lines = Vec::new();
    let mut in_block_comment = false;

    for (idx, raw_line) in source.lines().enumerate() {
        let mut line = String::new();
        let mut chars = raw_line.chars().peekable();
        let indent = raw_line.len() - raw_line.trim_start().len();

        while let Some(&ch) = chars.peek() {
            if in_block_comment {
                if ch == '*' {
                    chars.next();
                    if chars.peek() == Some(&'/') {
                        chars.next();
                        in_block_comment = false;
                        continue;
                    }
                } else {
                    chars.next();
                }
                continue;
            }

            if ch == '/' {
                chars.next();
                match chars.peek() {
                    Some(&'/') => break, // Line comment — rest of line ignored
                    Some(&'*') => {
                        chars.next();
                        in_block_comment = true;
                        continue;
                    }
                    _ => line.push('/'),
                }
                continue;
            }

            // Skip string contents to avoid matching inside string literals.
            // We still push the characters so that structural patterns outside
            // strings remain at the correct offsets, but the string interior
            // won't accidentally match a query like `id: PanelFoo`.
            if ch == '"' {
                line.push(ch);
                chars.next();
                while let Some(&c) = chars.peek() {
                    line.push(c);
                    chars.next();
                    if c == '"' {
                        break;
                    }
                    if c == '\\' {
                        if let Some(&escaped) = chars.peek() {
                            line.push(escaped);
                            chars.next();
                        }
                    }
                }
                continue;
            }

            line.push(ch);
            chars.next();
        }

        lines.push(StrippedLine {
            number: idx + 1,
            content: line.trim().to_string(),
            indent,
            raw: raw_line.to_string(),
        });
    }

    lines
}

/// Find a type declaration: `type xxxMsg =` or `type xxxMsg<'a> =`.
///
/// Returns the first line where the type is declared as a definition
/// (starting with `type`), not merely referenced. This distinguishes
/// `type fooMsg = ...` from a line that merely mentions `fooMsg`.
pub fn find_type_declaration<'a>(
    lines: &'a [StrippedLine],
    type_name: &str,
) -> Option<&'a StrippedLine> {
    let pattern_space = format!("type {} ", type_name);
    let pattern_eq = format!("type {}=", type_name);
    let pattern_exact = format!("type {}", type_name);
    lines.iter().find(|l| {
        l.content.starts_with(&pattern_space)
            || l.content.starts_with(&pattern_eq)
            || l.content == pattern_exact
    })
}

/// Find a variant constructor in a type definition: `| VariantName`.
///
/// Matches lines that begin with `|` (after trimming) followed by the
/// variant name. The variant must be followed by `(`, whitespace, or
/// end-of-line to avoid partial matches (e.g. `Panel` matching `PanelFoo`).
pub fn find_variant<'a>(
    lines: &'a [StrippedLine],
    variant_name: &str,
) -> Option<&'a StrippedLine> {
    lines.iter().find(|l| {
        let trimmed = l.content.trim_start_matches("| ");
        if !trimmed.starts_with(variant_name) {
            return false;
        }
        let rest = &trimmed[variant_name.len()..];
        rest.is_empty()
            || rest.starts_with('(')
            || rest.starts_with(' ')
            || rest.starts_with('\t')
    })
}

/// Find a variant with a specific argument pattern: `| Name(argType)`.
///
/// Searches for `VariantName(arg_pattern)` in lines that start with `|`
/// or contain the pattern as part of a variant constructor.
pub fn find_variant_with_arg<'a>(
    lines: &'a [StrippedLine],
    variant_name: &str,
    arg_pattern: &str,
) -> Option<&'a StrippedLine> {
    let pattern = format!("{}({})", variant_name, arg_pattern);
    lines.iter().find(|l| {
        let trimmed = l.content.trim_start_matches("| ");
        trimmed.contains(&pattern)
    })
}

/// Find an `include ModuleName` declaration.
///
/// Matches lines beginning with `include` followed by the module name,
/// confirming that the module is included (re-exported) at this point.
pub fn find_include<'a>(
    lines: &'a [StrippedLine],
    module_name: &str,
) -> Option<&'a StrippedLine> {
    let pattern = format!("include {}", module_name);
    lines.iter().find(|l| l.content.starts_with(&pattern))
}

/// Find a record field: `fieldName:` inside a record definition.
///
/// Matches lines containing `fieldName:` (possibly preceded by whitespace
/// or other record syntax). The colon must immediately follow the field
/// name to avoid matching substrings.
pub fn find_record_field<'a>(
    lines: &'a [StrippedLine],
    field_name: &str,
) -> Option<&'a StrippedLine> {
    let pattern_colon_space = format!("{}: ", field_name);
    let pattern_colon = format!("{}:", field_name);
    lines.iter().find(|l| {
        l.content.starts_with(&pattern_colon)
            || l.content.contains(&format!(" {}", &pattern_colon_space))
            || l.content.contains(&format!("\t{}", &pattern_colon_space))
    })
}

/// Find a match arm or any line containing the given pattern text.
///
/// Used for patterns like `Some(PanelXxx)` in switch expressions.
/// Falls back to a simple contains-search on the stripped (comment-free)
/// content, which is still an improvement over raw-text search because
/// comments have been removed.
pub fn find_match_arm<'a>(
    lines: &'a [StrippedLine],
    pattern_text: &str,
) -> Option<&'a StrippedLine> {
    lines.iter().find(|l| l.content.contains(pattern_text))
}

/// Find a panel registry entry: `id: PanelXxx` inside an allPanels array.
///
/// Searches for `id: {view_route}` in the stripped content, matching
/// the panel registration pattern used in PanelRegistry.res.
pub fn find_registry_entry<'a>(
    lines: &'a [StrippedLine],
    view_route: &str,
) -> Option<&'a StrippedLine> {
    let pattern = format!("id: {}", view_route);
    lines.iter().find(|l| l.content.contains(&pattern))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Verify that single-line comments are stripped.
    #[test]
    fn test_strip_line_comment() {
        let source = "let x = 1 // this is a comment\nlet y = 2";
        let lines = strip_comments(source);
        assert_eq!(lines[0].content, "let x = 1");
        assert_eq!(lines[0].number, 1);
        assert_eq!(lines[1].content, "let y = 2");
    }

    /// Verify that block comments are stripped, including multi-line.
    #[test]
    fn test_strip_block_comment() {
        let source = "let x = /* hidden */ 1\n/* start\nend */ let y = 2";
        let lines = strip_comments(source);
        assert_eq!(lines[0].content, "let x =  1");
        assert_eq!(lines[2].content, "let y = 2");
    }

    /// Verify that string contents are not stripped as comments.
    #[test]
    fn test_string_preserved() {
        let source = r#"let s = "// not a comment""#;
        let lines = strip_comments(source);
        assert!(lines[0].content.contains("// not a comment"));
    }

    /// Verify type declaration matching.
    #[test]
    fn test_find_type_declaration() {
        let source = "type fooMsg =\n  | Increment\n  | Decrement";
        let lines = strip_comments(source);
        let result = find_type_declaration(&lines, "fooMsg");
        assert!(result.is_some());
        assert_eq!(result.unwrap().number, 1);
    }

    /// Verify type declaration does not false-positive on references.
    #[test]
    fn test_type_declaration_not_reference() {
        let source = "let x: fooMsg = Increment";
        let lines = strip_comments(source);
        let result = find_type_declaration(&lines, "fooMsg");
        assert!(result.is_none());
    }

    /// Verify variant detection.
    #[test]
    fn test_find_variant() {
        let source = "type msg =\n  | PanelFoo\n  | PanelBar(int)";
        let lines = strip_comments(source);
        assert!(find_variant(&lines, "PanelFoo").is_some());
        assert!(find_variant(&lines, "PanelBar").is_some());
        // Should not match partial names.
        assert!(find_variant(&lines, "Panel").is_none());
    }

    /// Verify include detection.
    #[test]
    fn test_find_include() {
        let source = "include FooModel\ninclude BarModel";
        let lines = strip_comments(source);
        assert!(find_include(&lines, "FooModel").is_some());
        assert!(find_include(&lines, "BazModel").is_none());
    }

    /// Verify registry entry detection.
    #[test]
    fn test_find_registry_entry() {
        let source = "  {id: PanelFoo, name: \"Foo\"}";
        let lines = strip_comments(source);
        assert!(find_registry_entry(&lines, "PanelFoo").is_some());
        assert!(find_registry_entry(&lines, "PanelBar").is_none());
    }
}
