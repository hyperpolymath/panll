// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the VideoCoordination panel -- Drive-to-Photos batch transfers.

type videoCoordinationMsg =
  | StartTransfer(string, string) // source, destination
  | PauseTransfer(string) // batchId
  | RefreshStatus
  | StatusResult(result<string, string>)
  | TransferResult(result<string, string>)
  | ClearError
