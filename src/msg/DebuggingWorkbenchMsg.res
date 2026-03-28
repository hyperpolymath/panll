// SPDX-License-Identifier: PMPL-1.0-or-later

/// Debugging Workbench messages -- time-travel debugging, state inspection, watches.

open Model

type debuggingWorkbenchMsg =
  | SetDwTab(debuggingWorkbenchTab)
  | DwStepBack
  | DwStepForward
  | DwGoToSnapshot(int)
  | DwCaptureSnapshot
  | DwAddWatch
  | DwRemoveWatch(string)
  | DwClearConsole
  | DismissDwError
