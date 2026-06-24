// SPDX-License-Identifier: MPL-2.0

/// Extracted sub-updater for VideoCoordination panel.
/// Manages batch transfer lifecycle, status polling, and error handling.

open Model
open Msg

let updateVideoCoordination = (model: model, subMsg: videoCoordinationMsg): (model, Tea_Cmd.t<msg>) => {
  let vc = model.videoCoordination
  switch subMsg {
  | StartTransfer(source, destination) =>
    let newState = VideoCoordinationEngine.addBatch(vc, source, destination, 0)
    ({...model, videoCoordination: {...newState, loading: true}}, Tea_Cmd.none)
  | PauseTransfer(_batchId) => (model, Tea_Cmd.none)
  | RefreshStatus => ({...model, videoCoordination: {...vc, loading: true}}, Tea_Cmd.none)
  | StatusResult(Ok(_json)) => ({...model, videoCoordination: {...vc, loading: false}}, Tea_Cmd.none)
  | StatusResult(Error(err)) => (
      {...model, videoCoordination: {...vc, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | TransferResult(Ok(_json)) => (
      {...model, videoCoordination: {...vc, loading: false}},
      Tea_Cmd.none,
    )
  | TransferResult(Error(err)) => (
      {...model, videoCoordination: {...vc, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ClearError => ({...model, videoCoordination: {...vc, error: None}}, Tea_Cmd.none)
  }
}
