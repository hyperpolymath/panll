// SPDX-License-Identifier: MPL-2.0

/// Sub-updater for Security — redaction, vault, 2FA, Trustfile, shoulder-safe.

open Model
open Msg

let updateSecurity = (model: model, msg: securityMsg): (model, Tea_Cmd.t<msg>) => {
  let sec = model.security
  switch msg {
  | TogglePattern(id) => ({...model, security: SecurityEngine.togglePattern(sec, id)}, Tea_Cmd.none)
  | AddPattern(pattern) => (
      {...model, security: SecurityEngine.addPattern(sec, pattern)},
      Tea_Cmd.none,
    )
  | RemovePattern(id) => ({...model, security: SecurityEngine.removePattern(sec, id)}, Tea_Cmd.none)
  | SetRedactionMode(mode) => (
      {...model, security: SecurityEngine.setRedactionMode(sec, mode)},
      Tea_Cmd.none,
    )
  | RedactText(text, panelId) => {
      let activePatterns = sec.patterns->Array.filter(p => p.enabled)
      let patternsJson =
        "[" ++
        activePatterns
        ->Array.map(p => `{"id":"${p.id}","pattern":"${p.pattern}"}`)
        ->Array.join(",") ++ "]"
      (model, SecurityCmd.redactText(text, panelId, patternsJson))
    }
  | RedactionResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          let arr = json->JSON.Decode.array->Option.getOr([])
          let secrets = arr->Array.filterMap(item => {
            let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
            let patternId =
              obj->Dict.get("patternId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let panelId =
              obj->Dict.get("panelId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let offset =
              obj->Dict.get("offset")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let length =
              obj->Dict.get("length")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let placeholder =
              obj
              ->Dict.get("placeholder")
              ->Option.flatMap(JSON.Decode.string)
              ->Option.getOr("[REDACTED]")
            Some({
              SecurityModel.patternId,
              panelId,
              offset: Float.toInt(offset),
              length: Float.toInt(length),
              placeholder,
            })
          })
          Some(secrets)

        | None => None
        }
        switch parsed {
        | Some(detectedSecrets) => ({...model, security: {...sec, detectedSecrets}}, Tea_Cmd.none)
        | None => (model, Tea_Cmd.none)
        }
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | VaultStore(key, value) => (model, SecurityCmd.vaultStore(key, value))
  | VaultStoreResult(result) => switch result {
    | Ok(_) => ({...model, security: {...sec, error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, security: {...sec, error: Some(e)}}, Tea_Cmd.none)
    }
  | VaultRetrieve(key) => (model, SecurityCmd.vaultRetrieve(key))
  | VaultRetrieveResult(result) => switch result {
    | Ok(_value) => // Value is used by the caller, not stored in frontend state.
      ({...model, security: {...sec, error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, security: {...sec, error: Some(e)}}, Tea_Cmd.none)
    }
  | VaultList => (model, SecurityCmd.vaultList())
  | VaultListResult(result) => switch result {
    | Ok(jsonStr) => {
        let keys = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          json
          ->JSON.Decode.array
          ->Option.getOr([])
          ->Array.filterMap(item => {
            let o = item->JSON.Decode.object->Option.getOr(Dict.make())
            let k = o->Dict.get("key")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            if k !== "" {
              Some(
                (
                  {
                    key: k,
                    description: o
                    ->Dict.get("description")
                    ->Option.flatMap(JSON.Decode.string)
                    ->Option.getOr(""),
                    lastUpdated: o
                    ->Dict.get("lastUpdated")
                    ->Option.flatMap(JSON.Decode.float)
                    ->Option.getOr(0.0),
                  }: vaultKey
                ),
              )
            } else {
              None
            }
          })

        | None => []
        }
        ({...model, security: {...sec, vaultStatus: VaultUnlocked, vaultKeys: keys}}, Tea_Cmd.none)
      }
    | Error(e) => (
        {...model, security: {...sec, error: Some(e), vaultStatus: VaultError(e)}},
        Tea_Cmd.none,
      )
    }
  | SubmitTotp(code) => {
      // Submit the TOTP code for verification; result comes back via TotpResult.
      let cmd = Tea_Cmd.call(callbacks => {
        SecurityCmd.invoke("verify_totp", {"code": code})
        ->Promise.then(result => {
          callbacks.enqueue(Security(TotpResult(Ok(result))))
          Promise.resolve()
        })
        ->Promise.catch(_err => {
          callbacks.enqueue(Security(TotpResult(Error("TOTP verification failed"))))
          Promise.resolve()
        })
        ->ignore
      })
      ({...model, security: {...sec, totpInput: ""}}, cmd)
    }
  | TotpResult(result) => switch result {
    | Ok(_) => (
        {...model, security: {...sec, twoFactorStatus: TwoFactorAuthenticated(0.0)}},
        Tea_Cmd.none,
      )
    | Error(e) => ({...model, security: {...sec, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetTotpInput(input) => ({...model, security: {...sec, totpInput: input}}, Tea_Cmd.none)
  | LoadTrustfile(repoPath) => (
      model,
      Tea_Cmd.batch(list{
        SecurityCmd.loadTrustfile(repoPath),
        TypeLLService.checkSecurityTypes(repoPath, "security", result => Security(
          TypeCheckResult(result),
        )),
      }),
    )
  | TrustfileLoaded(result) => switch result {
    | Ok(jsonStr) => {
        let policy = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          let o = json->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let gb = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let sl = switch gs(o, "securityLevel") {
          | "low" => SecurityLow
          | "high" => SecurityHigh
          | "maximum" => SecurityMaximum
          | _ => SecurityMedium
          }
          let rm = switch gs(o, "redactionMode") {
          | "always" => RedactAlways
          | "on_save" => RedactOnSave
          | "on_display" => RedactOnDisplay
          | _ => RedactOnShare
          }
          let patterns =
            o
            ->Dict.get("customPatterns")
            ->Option.flatMap(JSON.Decode.array)
            ->Option.getOr([])
            ->Array.filterMap(p => {
              let po = p->JSON.Decode.object->Option.getOr(Dict.make())
              let pid = gs(po, "id")
              if pid !== "" {
                Some(
                  (
                    {
                      id: pid,
                      label: gs(po, "label"),
                      pattern: gs(po, "pattern"),
                      enabled: gb(po, "enabled"),
                      builtIn: gb(po, "builtIn"),
                    }: redactionPattern
                  ),
                )
              } else {
                None
              }
            })
          Some(
            (
              {
                securityLevel: sl,
                redactionMode: rm,
                customPatterns: patterns,
                twoFactorRequirements: [],
                defaultSharingPermission: ViewOnly,
                requireApproval: gb(o, "requireApproval"),
                loaded: true,
                filePath: o->Dict.get("filePath")->Option.flatMap(JSON.Decode.string),
              }: trustfilePolicy
            ),
          )

        | None => None
        }
        switch policy {
        | Some(p) => ({...model, security: SecurityEngine.applyTrustfile(sec, p)}, Tea_Cmd.none)
        | None => (
            {...model, security: {...sec, error: Some("Failed to parse Trustfile")}},
            Tea_Cmd.none,
          )
        }
      }
    | Error(e) => ({...model, security: {...sec, error: Some(e)}}, Tea_Cmd.none)
    }
  | ToggleShoulderSafe => (
      {...model, security: SecurityEngine.toggleShoulderSafe(sec)},
      Tea_Cmd.none,
    )
  | SetSecurityCategory(cat) => ({...model, security: {...sec, activeCategory: cat}}, Tea_Cmd.none)
  | SetNewPatternLabel(v) => ({...model, security: {...sec, newPatternLabel: v}}, Tea_Cmd.none)
  | SetNewPatternRegex(v) => ({...model, security: {...sec, newPatternRegex: v}}, Tea_Cmd.none)
  | SubmitNewPattern => if sec.newPatternLabel != "" && sec.newPatternRegex != "" {
      let pattern: redactionPattern = {
        id: "custom-" ++ Float.toString(Date.now()),
        label: sec.newPatternLabel,
        pattern: sec.newPatternRegex,
        enabled: true,
        builtIn: false,
      }
      (
        {
          ...model,
          security: SecurityEngine.addPattern(
            {...sec, newPatternLabel: "", newPatternRegex: ""},
            pattern,
          ),
        },
        Tea_Cmd.none,
      )
    } else {
      (model, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "security", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
