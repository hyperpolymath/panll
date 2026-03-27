// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Decoders.res — Extended Tea_Json decoder combinators and domain-specific
// decoders for PanLL Tauri command responses.
//
// Provides map6–map13 for records with more than 5 fields, plus convenience
// wrappers used across Update.res and engine modules.

open Tea_Json

// ── Extended map combinators ───────────────────────────────────────────
//
// Tea_Json provides map–map5. These extend coverage for larger records
// by composing map5 + mapN internally.

/// Combine six decoders with a function.
let map6 = (
  f: ('a, 'b, 'c, 'd, 'e, 'f) => 'g,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
  d6: decoder<'f>,
): decoder<'g> => {
  json => {
    switch (d1(json), d2(json), d3(json), d4(json), d5(json), d6(json)) {
    | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(fv)) => Ok(f(a, b, c, d, e, fv))
    | (Error(e), _, _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _, _) => Error(e)
    | (_, _, Error(e), _, _, _) => Error(e)
    | (_, _, _, Error(e), _, _) => Error(e)
    | (_, _, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, _, Error(e)) => Error(e)
    }
  }
}

/// Combine seven decoders with a function.
let map7 = (
  f: ('a, 'b, 'c, 'd, 'e, 'f, 'g) => 'h,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
  d6: decoder<'f>,
  d7: decoder<'g>,
): decoder<'h> => {
  json => {
    switch (d1(json), d2(json), d3(json), d4(json), d5(json), d6(json), d7(json)) {
    | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(fv), Ok(g)) => Ok(f(a, b, c, d, e, fv, g))
    | (Error(e), _, _, _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _, _, _) => Error(e)
    | (_, _, Error(e), _, _, _, _) => Error(e)
    | (_, _, _, Error(e), _, _, _) => Error(e)
    | (_, _, _, _, Error(e), _, _) => Error(e)
    | (_, _, _, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, _, _, Error(e)) => Error(e)
    }
  }
}

/// Combine eight decoders with a function.
let map8 = (
  f: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h) => 'i,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
  d6: decoder<'f>,
  d7: decoder<'g>,
  d8: decoder<'h>,
): decoder<'i> => {
  json => {
    switch (d1(json), d2(json), d3(json), d4(json), d5(json), d6(json), d7(json), d8(json)) {
    | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(fv), Ok(g), Ok(h)) => Ok(f(a, b, c, d, e, fv, g, h))
    | (Error(e), _, _, _, _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _, _, _, _) => Error(e)
    | (_, _, Error(e), _, _, _, _, _) => Error(e)
    | (_, _, _, Error(e), _, _, _, _) => Error(e)
    | (_, _, _, _, Error(e), _, _, _) => Error(e)
    | (_, _, _, _, _, Error(e), _, _) => Error(e)
    | (_, _, _, _, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, _, _, _, Error(e)) => Error(e)
    }
  }
}

/// Combine nine decoders with a function.
let map9 = (
  f: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'i) => 'j,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
  d6: decoder<'f>,
  d7: decoder<'g>,
  d8: decoder<'h>,
  d9: decoder<'i>,
): decoder<'j> => {
  json => {
    switch (
      d1(json),
      d2(json),
      d3(json),
      d4(json),
      d5(json),
      d6(json),
      d7(json),
      d8(json),
      d9(json),
    ) {
    | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(fv), Ok(g), Ok(h), Ok(i)) =>
      Ok(f(a, b, c, d, e, fv, g, h, i))
    | (Error(e), _, _, _, _, _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _, _, _, _, _) => Error(e)
    | (_, _, Error(e), _, _, _, _, _, _) => Error(e)
    | (_, _, _, Error(e), _, _, _, _, _) => Error(e)
    | (_, _, _, _, Error(e), _, _, _, _) => Error(e)
    | (_, _, _, _, _, Error(e), _, _, _) => Error(e)
    | (_, _, _, _, _, _, Error(e), _, _) => Error(e)
    | (_, _, _, _, _, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, _, _, _, _, Error(e)) => Error(e)
    }
  }
}

/// Combine ten decoders with a function.
let map10 = (
  f: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'i, 'j) => 'k,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
  d6: decoder<'f>,
  d7: decoder<'g>,
  d8: decoder<'h>,
  d9: decoder<'i>,
  d10: decoder<'j>,
): decoder<'k> => {
  json => {
    switch (
      d1(json),
      d2(json),
      d3(json),
      d4(json),
      d5(json),
      d6(json),
      d7(json),
      d8(json),
      d9(json),
      d10(json),
    ) {
    | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(fv), Ok(g), Ok(h), Ok(i), Ok(j)) =>
      Ok(f(a, b, c, d, e, fv, g, h, i, j))
    | (Error(e), _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, Error(e), _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, Error(e), _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, Error(e), _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, Error(e), _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, Error(e), _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, Error(e), _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, Error(e)) => Error(e)
    }
  }
}

/// Combine eleven decoders with a function.
let map11 = (
  f: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'i, 'j, 'k) => 'l,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
  d6: decoder<'f>,
  d7: decoder<'g>,
  d8: decoder<'h>,
  d9: decoder<'i>,
  d10: decoder<'j>,
  d11: decoder<'k>,
): decoder<'l> => {
  json => {
    switch (
      d1(json),
      d2(json),
      d3(json),
      d4(json),
      d5(json),
      d6(json),
      d7(json),
      d8(json),
      d9(json),
      d10(json),
      d11(json),
    ) {
    | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(fv), Ok(g), Ok(h), Ok(i), Ok(j), Ok(k)) =>
      Ok(f(a, b, c, d, e, fv, g, h, i, j, k))
    | (Error(e), _, _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, Error(e), _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, Error(e), _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, Error(e), _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, Error(e), _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, Error(e), _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, Error(e), _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, Error(e), _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, _, Error(e)) => Error(e)
    }
  }
}

/// Combine twelve decoders with a function.
let map12 = (
  f: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'i, 'j, 'k, 'l) => 'm,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
  d6: decoder<'f>,
  d7: decoder<'g>,
  d8: decoder<'h>,
  d9: decoder<'i>,
  d10: decoder<'j>,
  d11: decoder<'k>,
  d12: decoder<'l>,
): decoder<'m> => {
  json => {
    switch (
      d1(json),
      d2(json),
      d3(json),
      d4(json),
      d5(json),
      d6(json),
      d7(json),
      d8(json),
      d9(json),
      d10(json),
      d11(json),
      d12(json),
    ) {
    | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(fv), Ok(g), Ok(h), Ok(i), Ok(j), Ok(k), Ok(l)) =>
      Ok(f(a, b, c, d, e, fv, g, h, i, j, k, l))
    | (Error(e), _, _, _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, Error(e), _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, Error(e), _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, Error(e), _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, Error(e), _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, Error(e), _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, Error(e), _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, Error(e), _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, Error(e), _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, _, _, Error(e)) => Error(e)
    }
  }
}

/// Combine thirteen decoders with a function.
let map13 = (
  f: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'i, 'j, 'k, 'l, 'm) => 'n,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
  d6: decoder<'f>,
  d7: decoder<'g>,
  d8: decoder<'h>,
  d9: decoder<'i>,
  d10: decoder<'j>,
  d11: decoder<'k>,
  d12: decoder<'l>,
  d13: decoder<'m>,
): decoder<'n> => {
  json => {
    switch (
      d1(json),
      d2(json),
      d3(json),
      d4(json),
      d5(json),
      d6(json),
      d7(json),
      d8(json),
      d9(json),
      d10(json),
      d11(json),
      d12(json),
      d13(json),
    ) {
    | (
        Ok(a),
        Ok(b),
        Ok(c),
        Ok(d),
        Ok(e),
        Ok(fv),
        Ok(g),
        Ok(h),
        Ok(i),
        Ok(j),
        Ok(k),
        Ok(l),
        Ok(m),
      ) =>
      Ok(f(a, b, c, d, e, fv, g, h, i, j, k, l, m))
    | (Error(e), _, _, _, _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, Error(e), _, _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, Error(e), _, _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, Error(e), _, _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, Error(e), _, _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, Error(e), _, _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, Error(e), _, _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, Error(e), _, _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, Error(e), _, _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, _, Error(e), _, _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, _, _, _, _, _, _, _, _, Error(e)) => Error(e)
    }
  }
}

// ── Convenience wrappers ────────────────────────────────────────────────

/// Decode a JSON string, returning Ok(value) or Error(formatted message).
/// Wraps Tea_Json.decodeString with human-readable error output.
let decode = (decoder: decoder<'a>, jsonString: string): result<'a, string> => {
  switch decodeString(decoder, jsonString) {
  | Ok(v) => Ok(v)
  | Error(e) => Error(errorToString(e))
  }
}

/// Decode a JSON string, returning Some(value) or None on failure.
/// Use when you only need the happy path and failures map to defaults.
let decodeOption = (decoder: decoder<'a>, jsonString: string): option<'a> => {
  switch decodeString(decoder, jsonString) {
  | Ok(v) => Some(v)
  | Error(_) => None
  }
}

/// Decode a JSON string, returning the value or a default on failure.
let decodeWithDefault = (decoder: decoder<'a>, default: 'a, jsonString: string): 'a => {
  switch decodeString(decoder, jsonString) {
  | Ok(v) => v
  | Error(_) => default
  }
}

/// Field with default value — returns default if field is missing or wrong type.
let fieldWithDefault = (name: string, decoder: decoder<'a>, default: 'a): decoder<'a> => {
  json => {
    switch field(name, decoder)(json) {
    | Ok(v) => Ok(v)
    | Error(_) => Ok(default)
    }
  }
}

/// Decode a string field, defaulting to "" if missing.
let stringField = (name: string): decoder<string> => fieldWithDefault(name, string, "")

/// Decode a float field, defaulting to 0.0 if missing.
let floatField = (name: string): decoder<float> => fieldWithDefault(name, float, 0.0)

/// Decode an int field, defaulting to 0 if missing.
let intField = (name: string): decoder<int> => fieldWithDefault(name, int, 0)

/// Decode a bool field, defaulting to false if missing.
let boolField = (name: string): decoder<bool> => fieldWithDefault(name, bool, false)

/// Decode an array field, defaulting to empty array if missing.
let arrayField = (name: string, itemDecoder: decoder<'a>): decoder<array<'a>> =>
  fieldWithDefault(name, array(itemDecoder), [])

/// Decode an array, silently skipping elements that fail to decode.
/// Use instead of Tea_Json.array when malformed elements should be
/// dropped rather than failing the entire decode.
let lenientArray = (decoder: decoder<'a>): decoder<array<'a>> => {
  json => {
    switch json {
    | Array(arr) =>
      Ok(
        Array.filterMap(arr, item => {
          switch decoder(item) {
          | Ok(v) => Some(v)
          | Error(_) => None
          }
        }),
      )
    | _ => Error(Failure("Expected an array", json))
    }
  }
}

/// Decode a string array field, defaulting to empty array.
/// Common pattern for proversUsed, goals, proofScript, tacticsApplied, etc.
let stringArrayField = (name: string): decoder<array<string>> =>
  fieldWithDefault(name, lenientArray(string), [])

/// Map a decoded value through a transformation function.
/// Useful for variant mapping (e.g., int → trustLevel variant).
let mapValue = (decoder: decoder<'a>, f: 'a => 'b): decoder<'b> => map(decoder, f)

/// Decode the "result" wrapper common in Cloudflare-style API responses.
/// Handles both `[...]` and `{ "result": [...] }` shapes.
let resultArrayOrDirect = (itemDecoder: decoder<'a>): decoder<array<'a>> => {
  oneOf([lenientArray(itemDecoder), field("result", lenientArray(itemDecoder))])
}

/// Decode an optional field — returns Some(value) if present and decodable,
/// None otherwise. Useful for fields like "priority" or "comment" that may
/// be absent or null.
let optionalFieldDecoder = (name: string, decoder: decoder<'a>): decoder<option<'a>> => {
  json => {
    switch field(name, decoder)(json) {
    | Ok(v) => Ok(Some(v))
    | Error(_) => Ok(None)
    }
  }
}

/// Decode a string-keyed dict from a JSON object, extracting values as floats.
/// Used for heatmaps and score objects.
let floatDict: decoder<array<(string, float)>> = json => {
  switch json {
  | Object(d) => {
      let pairs = []
      Dict.forEachWithKey(d, (val, key) => {
        switch float(val) {
        | Ok(n) => Array.push(pairs, (key, n))->ignore
        | Error(_) => ()
        }
      })
      Ok(pairs)
    }
  | _ => Error(Failure("Expected an object", json))
  }
}

/// Decode a string-keyed dict from a JSON object, extracting values as ints.
/// Used for query pattern and proof type counts.
let intDict: decoder<array<(string, int)>> = json => {
  switch json {
  | Object(d) => {
      let pairs = []
      Dict.forEachWithKey(d, (val, key) => {
        switch int(val) {
        | Ok(n) => Array.push(pairs, (key, n))->ignore
        | Error(_) => ()
        }
      })
      Ok(pairs)
    }
  | _ => Error(Failure("Expected an object", json))
  }
}
