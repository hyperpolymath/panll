// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

let updateStapeln = (model: model, msg: stapelnMsg): (model, Tea_Cmd.t<msg>) => {
  let st = model.stapeln
  switch msg {
  | SetPipelineUrl(url) => ({...model, stapeln: {...st, pipelineUrl: url}}, Tea_Cmd.none)
  | Connect => (
      {...model, stapeln: {...st, loading: true, error: None}},
      StapelnCmd.connect(st.pipelineUrl, r => Stapeln(Connected(Result.isOk(r)))),
    )
  | Connected(ok) => (
      {
        ...model,
        stapeln: {
          ...st,
          connected: ok,
          loading: false,
          error: ok ? None : Some("Connection failed"),
        },
      },
      Tea_Cmd.none,
    )
  | UpdateConstraint(key, value) => {
      // Simple constraint updates by key name. The detailed constraint editor
      // lives in stapeln's own frontend; PanLL provides high-level overrides.
      let c = st.constraints
      let newConstraints = switch key {
      | "maxImageSizeMb" => {
          ...c,
          maxImageSizeMb: Int.fromString(value)->Option.getOr(c.maxImageSizeMb),
        }
      | "memoryLimitMb" => {
          ...c,
          memoryLimitMb: Int.fromString(value)->Option.getOr(c.memoryLimitMb),
        }
      | "cpuLimit" => {...c, cpuLimit: Float.fromString(value)->Option.getOr(c.cpuLimit)}
      | "requireHealthcheck" => {...c, requireHealthcheck: value === "true"}
      | "requireNonRoot" => {...c, requireNonRoot: value === "true"}
      | _ => c
      }
      ({...model, stapeln: {...st, constraints: newConstraints}}, Tea_Cmd.none)
    }
  | RequestValidation => (
      {...model, stapeln: {...st, loading: true}},
      StapelnCmd.requestValidation(st.pipelineUrl, r => Stapeln(
        switch r {
        | Ok(json) => {
            // Parse validation summary from JSON response.
            // For now, create a minimal summary — full parsing comes with
            // the stapeln backend integration.
            ignore(json)
            ValidationReceived({
              passed: true,
              errorCount: 0,
              warningCount: 0,
              infoCount: 0,
              findings: [],
              scanTimestamp: Date.now(),
            })
          }
        | Error(err) => {
            ignore(err)
            ValidationReceived({
              passed: false,
              errorCount: 1,
              warningCount: 0,
              infoCount: 0,
              findings: [
                {
                  id: "conn-err",
                  level: "error",
                  rule: "CONN",
                  message: "Could not reach validation endpoint",
                  line: None,
                  autoFixAvailable: false,
                },
              ],
              scanTimestamp: Date.now(),
            })
          }
        },
      )),
    )
  | ValidationReceived(summary) => (
      {...model, stapeln: {...st, lastValidation: Some(summary), loading: false}},
      Tea_Cmd.none,
    )
  | RequestGenerate(format) => (
      {...model, stapeln: {...st, loading: true}},
      StapelnCmd.requestGenerate(st.pipelineUrl, format, r =>
        switch r {
        | Ok(content) => Stapeln(GenerateReceived(content))
        | Error(err) => Stapeln(GenerateReceived("# Error: " ++ err))
        }
      ),
    )
  | GenerateReceived(content) => (
      {...model, stapeln: {...st, generatedArtifact: Some(content), loading: false}},
      Tea_Cmd.none,
    )
  | RefreshStatus => (
      {...model, stapeln: {...st, loading: true}},
      StapelnCmd.refreshStatus(st.pipelineUrl, r =>
        switch r {
        | Ok(json) => {
            // Parse pipeline status from JSON response.
            // Minimal stub — full parsing comes with backend integration.
            ignore(json)
            Stapeln(
              StatusReceived({
                health: PipelineUnknown,
                nodeCount: 0,
                connectionCount: 0,
                validationPassing: false,
                suggestions: [],
                securityPosture: {
                  score: 0.0,
                  slsaCompliant: false,
                  sbomPresent: false,
                  signatureValid: false,
                  vulnerabilities: 0,
                  criticalVulns: 0,
                },
                dependencies: [],
                lastUpdated: Date.now(),
              }),
            )
          }
        | Error(_) =>
          Stapeln(
            StatusReceived({
              health: PipelineUnknown,
              nodeCount: 0,
              connectionCount: 0,
              validationPassing: false,
              suggestions: [],
              securityPosture: {
                score: 0.0,
                slsaCompliant: false,
                sbomPresent: false,
                signatureValid: false,
                vulnerabilities: 0,
                criticalVulns: 0,
              },
              dependencies: [],
              lastUpdated: Date.now(),
            }),
          )
        }
      ),
    )
  | StatusReceived(status) => (
      {...model, stapeln: {...st, pipelineStatus: Some(status), loading: false}},
      Tea_Cmd.none,
    )
  | SetActiveTab(tab) => ({...model, stapeln: {...st, activeTab: tab}}, Tea_Cmd.none)
  | DismissError => ({...model, stapeln: {...st, error: None}}, Tea_Cmd.none)
  }
}
