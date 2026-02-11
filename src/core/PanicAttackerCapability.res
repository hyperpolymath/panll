// SPDX-License-Identifier: PMPL-1.0-or-later

/// panic-attacker capability parsing helpers.
///
/// Parses backend capability payload used by Pane-W status indicators.

type payload = {
  mode: string,
  binary: option<string>,
  detail: option<string>,
}

let parse = (raw: string): result<payload, string> => {
  try {
    let parsed = JSON.parseExn(raw)

    let getField = (obj, field) => {
      switch obj->JSON.Decode.object {
      | Some(dict) => dict->Dict.get(field)
      | None => None
      }
    }

    let getString = (obj, field, default) => {
      switch getField(obj, field) {
      | Some(value) =>
        switch value->JSON.Decode.string {
        | Some(str) => str
        | None => default
        }
      | None => default
      }
    }

    let getOptionString = (obj, field) => {
      switch getField(obj, field) {
      | Some(value) => value->JSON.Decode.string
      | None => None
      }
    }

    Ok({
      mode: getString(parsed, "mode", "unavailable"),
      binary: getOptionString(parsed, "binary"),
      detail: getOptionString(parsed, "detail"),
    })
  } catch {
  | _ => Error("Invalid panic-attacker capability payload")
  }
}

