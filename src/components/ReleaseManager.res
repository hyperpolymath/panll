// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Release Manager Component — view for versioning, changelog,
/// packaging, and distribution of IDApTIK builds.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: releaseManagerCategory,
  active: releaseManagerCategory,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(ReleaseManager(SetReleaseCategory(cat)))},
    list{text(label)},
  )
}

/// Render overview — version, channel, recent releases.
let renderOverview = (state: releaseManagerState): Tea_Vdom.t<msg> => {
  let channelCls = ReleaseManagerEngine.channelColour(state.channel)
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Version card
      div(
        list{Attrs.class_("p-4 bg-gray-800 rounded border border-gray-700")},
        list{
          div(
            list{Attrs.class_("grid grid-cols-3 gap-4")},
            list{
              div(
                list{},
                list{
                  div(
                    list{Attrs.class_("text-xs text-gray-500 mb-1")},
                    list{text("Current Version")},
                  ),
                  div(
                    list{Attrs.class_("text-2xl font-light text-gray-100 font-mono")},
                    list{text(state.currentVersion)},
                  ),
                },
              ),
              div(
                list{},
                list{
                  div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("Next Version")}),
                  div(
                    list{Attrs.class_("text-2xl font-light text-cyan-400 font-mono")},
                    list{text(state.nextVersion)},
                  ),
                },
              ),
              div(
                list{},
                list{
                  div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("Channel")}),
                  div(
                    list{Attrs.class_(`text-2xl font-light ${channelCls}`)},
                    list{text(ReleaseManagerEngine.channelLabel(state.channel))},
                  ),
                },
              ),
            },
          ),
          // Version bump buttons
          div(
            list{Attrs.class_("flex items-center gap-2 mt-4")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(ReleaseManager(BumpVersion("patch"))),
                },
                list{text("Patch")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(ReleaseManager(BumpVersion("minor"))),
                },
                list{text("Minor")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(ReleaseManager(BumpVersion("major"))),
                },
                list{text("Major")},
              ),
            },
          ),
        },
      ),
      // Recent releases
      if Array.length(state.releases) > 0 {
        div(
          list{Attrs.class_("space-y-2")},
          list{
            div(list{Attrs.class_("text-xs text-gray-400")}, list{text("Recent Releases")}),
            ...state.releases
            ->Array.map(rel => {
              let statusCls = ReleaseManagerEngine.statusColour(rel.status)
              let chCls = ReleaseManagerEngine.channelColour(rel.channel)
              div(
                list{
                  Attrs.class_(
                    "flex items-center gap-3 p-3 bg-gray-800 rounded border border-gray-700 cursor-pointer hover:border-gray-500",
                  ),
                  Events.onClick(ReleaseManager(SelectRelease(rel.version))),
                },
                list{
                  span(
                    list{Attrs.class_("text-sm font-mono text-gray-100")},
                    list{text(rel.version)},
                  ),
                  span(
                    list{Attrs.class_(`text-xs ${chCls}`)},
                    list{text(ReleaseManagerEngine.channelLabel(rel.channel))},
                  ),
                  span(
                    list{Attrs.class_(`text-xs ${statusCls}`)},
                    list{text(ReleaseManagerEngine.statusLabel(rel.status))},
                  ),
                  span(
                    list{Attrs.class_("text-xs text-gray-500 ml-auto")},
                    list{text(`${Int.toString(Array.length(rel.artifacts))} artifacts`)},
                  ),
                },
              )
            })
            ->List.fromArray,
          },
        )
      } else {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No releases yet")},
        )
      },
    },
  )
}

/// Render changelog view.
let renderChangelog = (state: releaseManagerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-cyan-700 text-white rounded hover:bg-cyan-600 cursor-pointer",
              ),
              Events.onClick(ReleaseManager(GenerateChangelog)),
              KeyboardNav.onActivate(ReleaseManager(GenerateChangelog)),
            },
            list{text("Generate from Git")},
          ),
          button(
            list{
              Attrs.class_(
                if state.autoChangelog {
                  "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded"
                } else {
                  "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded cursor-pointer"
                },
              ),
              Events.onClick(ReleaseManager(ToggleAutoChangelog)),
              KeyboardNav.onActivate(ReleaseManager(ToggleAutoChangelog)),
            },
            list{text("Auto-Generate")},
          ),
        },
      ),
      if Array.length(state.pendingChangelog) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{
            text(
              "No pending changelog entries — click 'Generate from Git' to create from commit history",
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("space-y-1")},
          state.pendingChangelog
          ->Array.map(entry =>
            div(
              list{Attrs.class_("p-2 bg-gray-800 rounded text-xs")},
              list{
                div(
                  list{Attrs.class_("flex items-center gap-2 mb-1")},
                  list{
                    span(
                      list{Attrs.class_("text-cyan-400 font-mono")},
                      list{text(entry.commitHash)},
                    ),
                    span(list{Attrs.class_("text-gray-500")}, list{text(entry.category)}),
                    span(list{Attrs.class_("text-gray-600")}, list{text(entry.date)}),
                  },
                ),
                div(list{Attrs.class_("text-gray-300")}, list{text(entry.description)}),
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render artifacts view.
let renderArtifacts = (state: releaseManagerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Platform toggles
      div(
        list{Attrs.class_("flex items-center gap-1 flex-wrap")},
        list{
          span(list{Attrs.class_("text-xs text-gray-400 mr-2")}, list{text("Platforms:")}),
          ...ReleaseManagerEngine.allPlatforms
          ->Array.map(platform => {
            let isEnabled = state.enabledPlatforms->Array.includes(platform)
            button(
              list{
                Attrs.class_(
                  if isEnabled {
                    "px-2 py-1 text-xs bg-cyan-700 text-white rounded"
                  } else {
                    "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                  },
                ),
                Events.onClick(ReleaseManager(TogglePlatform(platform))),
              },
              list{text(ReleaseManagerEngine.platformLabel(platform))},
            )
          })
          ->List.fromArray,
        },
      ),
      // Build button
      button(
        list{
          Attrs.class_(
            "px-4 py-2 text-sm bg-purple-700 text-white rounded hover:bg-purple-600 cursor-pointer",
          ),
          Events.onClick(ReleaseManager(BuildArtifacts)),
          KeyboardNav.onActivate(ReleaseManager(BuildArtifacts)),
        },
        list{text("Build Artifacts")},
      ),
      // Existing artifacts
      if Array.length(state.artifacts) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No artifacts built yet")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1")},
          state.artifacts
          ->Array.map(art =>
            div(
              list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800 rounded text-xs")},
              list{
                span(list{Attrs.class_("text-gray-200 flex-1")}, list{text(art.name)}),
                span(
                  list{Attrs.class_("text-gray-500")},
                  list{text(ReleaseManagerEngine.platformLabel(art.platform))},
                ),
                span(
                  list{Attrs.class_("text-gray-400 font-mono")},
                  list{text(ReleaseManagerEngine.formatSize(art.sizeBytes))},
                ),
                span(
                  list{Attrs.class_("text-gray-600 font-mono truncate w-24")},
                  list{text(art.checksum)},
                ),
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render distribution view.
let renderDistribution = (state: releaseManagerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Publish controls
      div(
        list{Attrs.class_("p-4 bg-gray-800 rounded border border-gray-700")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200 mb-3")}, list{text("Publish Release")}),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-lg font-mono text-gray-100")},
                list{text(state.nextVersion)},
              ),
              span(
                list{Attrs.class_(`text-sm ${ReleaseManagerEngine.channelColour(state.channel)}`)},
                list{text(ReleaseManagerEngine.channelLabel(state.channel))},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-4 py-2 text-sm bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
                  ),
                  Events.onClick(ReleaseManager(PublishRelease)),
                  KeyboardNav.onActivate(ReleaseManager(PublishRelease)),
                },
                list{text("Publish")},
              ),
            },
          ),
          // Sign toggle
          div(
            list{Attrs.class_("flex items-center gap-2 mt-3")},
            list{
              button(
                list{
                  Attrs.class_(
                    if state.signArtifacts {
                      "px-2 py-1 text-xs bg-emerald-700 text-white rounded"
                    } else {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(ReleaseManager(ToggleSignArtifacts)),
                  KeyboardNav.onActivate(ReleaseManager(ToggleSignArtifacts)),
                },
                list{
                  text(
                    if state.signArtifacts {
                      "Signing: On"
                    } else {
                      "Signing: Off"
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Channel selector
      div(
        list{Attrs.class_("flex items-center gap-1")},
        list{
          span(list{Attrs.class_("text-xs text-gray-400 mr-2")}, list{text("Channel:")}),
          ...[ChannelDev, ChannelAlpha, ChannelBeta, ChannelRC, ChannelStable]
          ->Array.map(ch => {
            let isActive = state.channel === ch
            let chCls = ReleaseManagerEngine.channelColour(ch)
            button(
              list{
                Attrs.class_(
                  if isActive {
                    `px-2 py-1 text-xs bg-gray-600 ${chCls} rounded`
                  } else {
                    "px-2 py-1 text-xs bg-gray-800 text-gray-500 rounded cursor-pointer hover:text-gray-300"
                  },
                ),
                Events.onClick(ReleaseManager(SetChannel(ch))),
              },
              list{text(ReleaseManagerEngine.channelLabel(ch))},
            )
          })
          ->List.fromArray,
        },
      ),
    },
  )
}

/// Main view function.
let view = (state: releaseManagerState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Release Manager panel"),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-lg font-semibold text-gray-100")},
                list{text("Release Manager")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500 font-mono")},
                list{text(state.currentVersion)},
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
              ),
              Events.onClick(ReleaseManager(LoadReleases)),
              KeyboardNav.onActivate(ReleaseManager(LoadReleases)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Overview", ReleaseOverview, state.activeCategory),
          renderTab("Changelog", ReleaseChangelog, state.activeCategory),
          renderTab("Artifacts", ReleaseArtifacts, state.activeCategory),
          renderTab("Distribution", ReleaseDistribution, state.activeCategory),
        },
      ),
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300",
            ),
          },
          list{text(err)},
        )
      | None => noNode
      },
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | ReleaseOverview => renderOverview(state)
          | ReleaseChangelog => renderChangelog(state)
          | ReleaseArtifacts => renderArtifacts(state)
          | ReleaseDistribution => renderDistribution(state)
          },
        },
      ),
    },
  )
}
