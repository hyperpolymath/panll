// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Wizard Test Integration — Connects test suite to main update system.

open Model
open Msg
open WizardTest

module UpdateWizardTest = {
  /// Run wizard tests and return results via message
  let runTests = (tagger: string => msg): Tea_Cmd.t<msg> => {
    Tea_Cmd.call(callbacks => {
      // Run all tests
      let results = WizardTest.runAllTests()
      let report = WizardTest.generateTestReport(results)
      
      // Send results back via message
      callbacks.enqueue(tagger(report))
      Promise.resolve()
    })
  }

  /// Handle test-related messages
  let update = (model: model, msg: wizardTestMsg): (model, Tea_Cmd.t<msg>) => {
    switch msg {
    | RunWizardTests => {
        let cmd = runTests(result => WizardTest(TestResults(result)))
        (model, cmd)
      }
    | TestResults(report) => {
        // Store test results in model
        let newModel = {
          ...model,
          wizardTestResults: Some({
            report,
            timestamp: Date.now(),
          })
        }
        (newModel, Tea_Cmd.none)
      }
    }
  }
}