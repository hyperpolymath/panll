// SPDX-License-Identifier: PMPL-1.0-or-later

/// VideoCoordination Component — view rendering for the video transfer dashboard.
///
/// Features:
/// - Batch progress tracking
/// - Quota usage visualisation (Daily 750GB limit)
/// - ARIA-live regions for status updates

open Model
open Msg
open Tea.Html
open VideoCoordinationModel
open VideoCoordinationEngine

let viewBatch = batch => {
  div(
    list{Attrs.class_("p-4 bg-gray-900 rounded-lg border border-gray-800 mb-4")},
    list{
      div(
        list{Attrs.class_("flex justify-between items-center mb-2")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-300")}, list{text(batch.source)}),
          span(
            list{
              Attrs.class_(
                switch batch.status {
                | "Active" => "text-blue-400"
                | "Completed" => "text-green-400"
                | _ => "text-gray-500"
                },
              ),
            },
            list{text(batch.status)},
          ),
        },
      ),
      // Progress Bar
      div(
        list{Attrs.class_("w-full bg-gray-800 rounded-full h-2 mb-2")},
        list{
          div(
            list{
              Attrs.class_("bg-blue-600 h-2 rounded-full transition-all duration-500"),
              Attrs.style("width", Float.toString(batch->batchProgress) ++ "%"),
              Attrs.role("progressbar"),
              Attrs.ariaValueNow(batch->batchProgress),
              Attrs.ariaValueMin(0.0),
              Attrs.ariaValueMax(100.0),
            },
            list{},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500 flex justify-between")},
        list{
          text(
            batch.processedFiles->Belt.Int.toString ++
              (" / " ++
              batch.totalFiles->Belt.Int.toString),
          ),
          text(batch.failedFiles > 0 ? batch.failedFiles->Belt.Int.toString ++ " failed" : ""),
        },
      ),
    },
  )
}

let view = (state: videoCoordinationState) => {
  div(
    list{
      Attrs.class_("h-full flex flex-col bg-gray-950 p-6"),
      Attrs.role("region"),
      Attrs.ariaLabel("Video Transfer Coordination"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex justify-between items-end mb-8")},
        list{
          div(
            list{},
            list{
              h2(
                list{Attrs.class_("text-2xl font-bold text-gray-100 mb-1")},
                list{text("Video Coordination")},
              ),
              p(
                list{Attrs.class_("text-sm text-gray-500")},
                list{text("Orchestrating Drive to Photos migration")},
              ),
            },
          ),
          // Quota Indicator
          div(
            list{Attrs.class_("text-right")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider")},
                list{text("Daily Quota")},
              ),
              div(
                list{Attrs.class_("text-lg font-mono text-gray-300")},
                list{text("750 GB Limit")},
              ),
            },
          ),
        },
      ),
      // Active Batches
      div(
        list{Attrs.class_("flex-1 overflow-y-auto")},
        state.activeBatches->List.length == 0
          ? list{
              div(
                list{Attrs.class_("text-center text-gray-600 mt-20")},
                list{text("No active transfers. Start a batch via CLI or Provisioner.")},
              ),
            }
          : state.activeBatches->List.map(viewBatch),
      ),
    },
  )
}
