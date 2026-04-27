// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Wizard Test Integration — stub; wizard test dispatch lives in UpdateWizard.res.

open Model
open Msg
open WizardTest

module UpdateWizardTest = {
  let runTests = (tagger: string => msg): Tea_Cmd.t<msg> => {
    Tea_Cmd.call(callbacks => {
      let results = WizardTest.runAllTests()
      let report = WizardTest.generateTestReport(results)
      callbacks.enqueue(tagger(report))
    })
  }
}
