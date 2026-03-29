// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Asset Manager Component — PixiJS sprites, sounds, level templates.
/// Displays asset grid with thumbnails/icons, filter by kind, collection
/// organiser, and usage tracker.

open Model
open Msg
open Tea.Html

/// Render an asset kind label.
let assetKindLabel = (kind: assetKind): string => {
  switch kind {
  | Sprite => "Sprite"
  | SpriteSheet => "SpriteSheet"
  | Sound => "Sound"
  | Music => "Music"
  | Font => "Font"
  | LevelTemplate => "Template"
  | ParticleEffect => "Particle"
  }
}

/// Render an asset kind icon/colour.
let assetKindColor = (kind: assetKind): string => {
  switch kind {
  | Sprite => "text-pink-400"
  | SpriteSheet => "text-pink-300"
  | Sound => "text-yellow-400"
  | Music => "text-purple-400"
  | Font => "text-gray-400"
  | LevelTemplate => "text-green-400"
  | ParticleEffect => "text-cyan-400"
  }
}

/// Format file size in human-readable form.
let formatSize = (bytes: int): string => {
  if bytes >= 1048576 {
    Float.toFixed(Int.toFloat(bytes) /. 1048576.0, ~digits=1) ++ " MB"
  } else if bytes >= 1024 {
    Float.toFixed(Int.toFloat(bytes) /. 1024.0, ~digits=1) ++ " KB"
  } else {
    Int.toString(bytes) ++ " B"
  }
}

/// Main view function for the Asset Manager panel.
let view = (state: assetManagerState): Tea_Vdom.t<msg> => {
  let totalAssets = Array.length(state.assets)
  let collectionCount = Array.length(state.collections)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Asset Manager — Game Asset Library"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-pink-300")},
                list{text("Asset Manager")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(totalAssets) ++
                    " assets, " ++
                    Int.toString(collectionCount) ++ " collections",
                  ),
                },
              ),
              if state.importing {
                span(
                  list{Attrs.class_("text-xs text-yellow-400 animate-pulse")},
                  list{text("Importing...")},
                )
              } else {
                Tea_Html.noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-pink-800 hover:bg-pink-700 text-white rounded"),
              Events.onClick(AssetManager(AmStarted)),
              KeyboardNav.onActivate(AssetManager(AmStarted)),
            },
            list{text("Import")},
          ),
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Browse {
                  "bg-pink-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AssetManager(SetAmCategory(Browse))),
            },
            list{text("Browse")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Import {
                  "bg-pink-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AssetManager(SetAmCategory(Import))),
            },
            list{text("Import")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Collections {
                  "bg-pink-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AssetManager(SetAmCategory(Collections))),
            },
            list{text("Collections")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Usage {
                  "bg-pink-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AssetManager(SetAmCategory(Usage))),
            },
            list{text("Usage")},
          ),
        },
      ),
      // Filter bar
      div(
        list{Attrs.class_("flex items-center gap-2 px-4 py-2 border-b border-gray-800")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 bg-gray-900 border border-gray-700 rounded px-2 py-1 text-xs text-gray-200",
              ),
              Attrs.value(state.filter),
              Attrs.placeholder("Search assets..."),
            },
            list{},
          ),
          // Kind filter badges
          span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Kind:")}),
          switch state.kindFilter {
          | Some(k) =>
            span(
              list{Attrs.class_("px-2 py-0.5 text-xs bg-pink-900/50 text-pink-300 rounded")},
              list{text(assetKindLabel(k))},
            )
          | None => span(list{Attrs.class_("text-xs text-gray-500")}, list{text("All")})
          },
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200 flex justify-between items-center",
            ),
          },
          list{
            text(err),
            button(
              list{
                Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"),
                Events.onClick(AssetManager(DismissAmError)),
                KeyboardNav.onActivate(AssetManager(DismissAmError)),
              },
              list{text("Dismiss")},
            ),
          },
        )
      | None => Tea_Html.noNode
      },
      // Content area
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-4")},
        list{
          switch state.activeTab {
          | Browse =>
            // Asset grid
            div(
              list{Attrs.class_("grid grid-cols-3 gap-2")},
              state.assets
              ->Array.map(a => {
                let isSelected = state.selectedAsset == Some(a.id)
                div(
                  list{
                    Attrs.class_(
                      "px-2 py-2 border rounded cursor-pointer " ++ if isSelected {
                        "bg-pink-900/20 border-pink-700"
                      } else {
                        "bg-gray-900 border-gray-800 hover:border-gray-700"
                      },
                    ),
                  },
                  list{
                    // Thumbnail placeholder
                    div(
                      list{
                        Attrs.class_(
                          "w-full h-16 bg-gray-800 rounded flex items-center justify-center mb-1",
                        ),
                      },
                      list{
                        span(
                          list{Attrs.class_("text-xs font-mono " ++ assetKindColor(a.kind))},
                          list{text(assetKindLabel(a.kind))},
                        ),
                      },
                    ),
                    div(list{Attrs.class_("text-xs text-gray-200 truncate")}, list{text(a.name)}),
                    div(
                      list{Attrs.class_("text-xs text-gray-500")},
                      list{text(formatSize(a.sizeBytes))},
                    ),
                    if Array.length(a.tags) > 0 {
                      div(
                        list{Attrs.class_("flex flex-wrap gap-1 mt-1")},
                        a.tags
                        ->Array.map(t =>
                          span(
                            list{Attrs.class_("px-1 text-xs bg-gray-800 text-gray-500 rounded")},
                            list{text(t)},
                          )
                        )
                        ->List.fromArray,
                      )
                    } else {
                      Tea_Html.noNode
                    },
                  },
                )
              })
              ->List.fromArray,
            )
          | Import =>
            div(
              list{Attrs.class_("text-center py-8 space-y-4")},
              list{
                div(
                  list{
                    Attrs.class_(
                      "w-full h-32 border-2 border-dashed border-gray-700 rounded flex items-center justify-center",
                    ),
                  },
                  list{
                    span(
                      list{Attrs.class_("text-gray-500 text-sm")},
                      list{text("Drop files here or click Import to select")},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-500")},
                  list{text("Supports: PNG, WebP, WAV, OGG, MP3, TTF, WOFF2, JSON")},
                ),
              },
            )
          | Collections =>
            div(
              list{Attrs.class_("space-y-3")},
              state.collections
              ->Array.map(c =>
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between mb-1")},
                      list{
                        span(
                          list{Attrs.class_("text-sm font-bold text-pink-300")},
                          list{text(c.name)},
                        ),
                        span(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text(Int.toString(Array.length(c.assets)) ++ " assets")},
                        ),
                      },
                    ),
                    div(list{Attrs.class_("text-xs text-gray-500")}, list{text(c.description)}),
                  },
                )
              )
              ->List.fromArray,
            )
          | Usage =>
            div(
              list{Attrs.class_("space-y-1")},
              state.assets
              ->Array.filter(a => Array.length(a.usedInLevels) > 0)
              ->Array.map(a =>
                div(
                  list{Attrs.class_("flex items-center gap-3 py-1 border-b border-gray-800/50")},
                  list{
                    span(
                      list{Attrs.class_("text-xs " ++ assetKindColor(a.kind))},
                      list{text(assetKindLabel(a.kind))},
                    ),
                    span(list{Attrs.class_("text-sm text-gray-200 flex-1")}, list{text(a.name)}),
                    span(
                      list{Attrs.class_("text-xs text-gray-400")},
                      list{
                        text("Used in " ++ Int.toString(Array.length(a.usedInLevels)) ++ " levels"),
                      },
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          },
        },
      ),
    },
  )
}
