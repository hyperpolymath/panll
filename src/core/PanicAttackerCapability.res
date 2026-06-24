// SPDX-License-Identifier: MPL-2.0

/// panic-attacker capability parsing helpers.
///
/// Parses backend capability payload used by Pane-W status indicators.

type payload = {
  mode: string,
  binary: option<string>,
  detail: option<string>,
}

/// Tea_Json decoder for a panic-attacker capability payload.
let payloadDecoder: Tea_Json.decoder<payload> = {
  open Decoders
  open Tea_Json
  map3((mode, binary, detail): payload => {
    mode,
    binary,
    detail,
  }, fieldWithDefault(
    "mode",
    string,
    "unavailable",
  ), optionalFieldDecoder("binary", string), optionalFieldDecoder("detail", string))
}

/// Parse a panic-attacker capability payload from JSON.
let parse = (raw: string): result<payload, string> => Decoders.decode(payloadDecoder, raw)
