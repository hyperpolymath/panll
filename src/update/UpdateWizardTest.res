// SPDX-License-Identifier: MPL-2.0

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
