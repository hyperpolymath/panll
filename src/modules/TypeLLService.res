// SPDX-License-Identifier: MPL-2.0

/// PanLL TypeLL Service — cross-panel type intelligence layer.
///
/// This is what makes TypeLL different from every other panel. It isn't just
/// a visible panel — it's an invisible verification backbone that any panel
/// can query. When you write a VCL query in VeriSimDB, TypeLL checks its
/// dependent types. When you analyse a schema in Protocol-Squisher, TypeLL
/// verifies the type compatibility. When you write code in My-Lang, TypeLL
/// provides the type inference.
///
/// ## Integration Points
///
/// | Panel              | What TypeLL provides                                    |
/// |--------------------|---------------------------------------------------------|
/// | VeriSimDB          | VCL-total proof obligations, query type safety             |
/// | Protocol-Squisher  | Schema type compatibility, adapter type safety           |
/// | My-Lang            | Full type checking across all 4 dialects                |
/// | Anti-Crash         | Type-level validation before token acceptance            |
/// | Pane-L             | Type constraints as first-class symbolic constraints     |
/// | Pane-N             | Type-guided inference — suggest types, explain errors    |
/// | BoJ                | Cartridge ABI type checking (Idris2 formal specs)        |
/// | ECHIDNA            | Proof obligation dispatch — TypeLL generates, ECHIDNA proves |
/// | Build Dashboard    | Type error aggregation across all sub-projects           |
/// | Playgrounds        | Interactive type checking in code sandboxes              |
///
/// ## Architecture
///
/// The service is stateless — it wraps TypeLLCmd calls with panel-specific
/// message taggers. Each panel doesn't need to know about TypeLL's internal
/// protocol; it just calls these helpers and gets back results in its own
/// message type.
///
/// The TypeLL panel's `queriesServed` counter tracks cross-panel usage.

/// Check types for a VCL query expression.
/// Used by VeriSimDB panel to validate queries before execution.
let checkVclTypes = (query: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  let context = `{"language":"vcl","dialect":"vcl-total","features":["dependent","linear","proof-carrying"]}`
  TypeLLCmd.check(query, Some(context), tagger)
}

/// Check types for a protocol schema.
/// Used by Protocol-Squisher to verify schema type compatibility.
let checkSchemaTypes = (
  schema: string,
  format: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let context = `{"language":"schema","format":"${format}","features":["dependent","session"]}`
  TypeLLCmd.check(schema, Some(context), tagger)
}

/// Check types for my-lang source code.
/// Used by My-Lang panel for type checking across dialects.
let checkMyLangTypes = (
  source: string,
  dialect: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let features = switch dialect {
  | "solo" => `["dependent"]`
  | "duet" => `["dependent","effect"]`
  | "ensemble" => `["dependent","session","effect"]`
  | "me" => `["dependent","session","effect","linear"]`
  | _ => `["dependent"]`
  }
  let context = `{"language":"my-lang","dialect":"${dialect}","features":${features}}`
  TypeLLCmd.check(source, Some(context), tagger)
}

/// Validate a token against type constraints.
/// Used by Anti-Crash to add type-level validation to the circuit breaker.
let validateToken = (
  tokenContent: string,
  constraintExpressions: array<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let constraintsJson =
    constraintExpressions
    ->Array.map(c => `"${c}"`)
    ->Array.join(",")
  let _context = `{"language":"constraint","features":["dependent","refinement"]}`
  TypeLLCmd.refine(tokenContent, Some(`[${constraintsJson}]`), tagger)
}

/// Infer types for a Pane-L constraint expression.
/// Used by Pane-L to show the type of constraint expressions.
let inferConstraintType = (expression: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  TypeLLCmd.infer(expression, tagger)
}

/// Check types for a BoJ cartridge ABI definition.
/// Used by BoJ panel to validate Idris2 formal specs.
let checkCartridgeAbi = (abiSpec: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  let context = `{"language":"idris2","features":["dependent","linear","quantitative"]}`
  TypeLLCmd.check(abiSpec, Some(context), tagger)
}

/// Generate proof obligations for an expression.
/// Used by ECHIDNA integration — TypeLL generates, ECHIDNA proves.
let generateProofObligations = (
  expression: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let context = `{"language":"proof","features":["dependent","proof-carrying"],"mode":"obligation-generation"}`
  TypeLLCmd.check(expression, Some(context), tagger)
}

/// Apply refinement types interactively.
/// Used by the Refinement tab in the TypeLL panel and by any panel
/// that needs to narrow a type with constraints.
let applyRefinement = (
  baseType: string,
  constraints: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  TypeLLCmd.refine(baseType, Some(constraints), tagger)
}

/// Check types for configuration data (CloudGuard, Provisioner, Workspace, etc.).
let checkConfigTypes = (
  configJson: string,
  domain: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let context = `{"language":"config","domain":"${domain}","features":["dependent","refinement"]}`
  TypeLLCmd.check(configJson, Some(context), tagger)
}

/// Check types for security policy data (Trustfile, attack vectors, directives).
let checkSecurityTypes = (
  policyData: string,
  domain: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let context = `{"language":"policy","domain":"${domain}","features":["dependent","linear","proof-carrying"]}`
  TypeLLCmd.check(policyData, Some(context), tagger)
}

/// Check types for UMS ABI validation results.
/// Used by Universal Modding Studio to type-check level data against the
/// 14 Idris2 ABI module interface (dependent types, quantitative erasure).
let checkUmsAbi = (levelData: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  let context = `{"language":"idris2","domain":"ums-level-abi","features":["dependent","quantitative","erasure","proof-carrying"],"modules":14}`
  TypeLLCmd.check(levelData, Some(context), tagger)
}

/// Check types for game data (levels, topology, VM state, puzzles).
let checkGameDataTypes = (
  gameData: string,
  domain: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let context = `{"language":"game-data","domain":"${domain}","features":["dependent","session"]}`
  TypeLLCmd.check(gameData, Some(context), tagger)
}

/// Check types for code or source expressions (playground, REPL, commands).
let checkCodeTypes = (
  source: string,
  language: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let context = `{"language":"${language}","features":["dependent","effect"]}`
  TypeLLCmd.check(source, Some(context), tagger)
}

/// Check types for metadata (tags, clades, manifests, migration specs).
let checkMetadataTypes = (
  metadata: string,
  domain: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let context = `{"language":"metadata","domain":"${domain}","features":["dependent"]}`
  TypeLLCmd.check(metadata, Some(context), tagger)
}
