// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// App — TEA (The Elm Architecture) entry point for the Clade Portal.
///
/// The THIRD application built natively for the Gossamer webview shell.
/// Provides a taxonomy browser for PanLL's 100+ panel clades with three
/// view modes (tree, list, graph), full-text search, relationship mapping,
/// and live health indicators.
///
/// Architecture:
///   - Model.res        — State types
///   - Msg.res          — Message types
///   - App.res          — init, update, view (this file)
///   - CladeCmd.res     — IPC commands to read clade metadata
///   - Capabilities.res — Gossamer capability token management
///   - RuntimeBridge.res — Gossamer-native IPC bridge
///
/// Layout:
///   +--------------------------------------------------+
///   | [Search bar]              [Tree|List|Graph] [Cap] |
///   +----------+---------------------------------------+
///   | Tree/    |  Detail panel: clade metadata,        |
///   | List     |  traits, capabilities, relationships, |
///   | sidebar  |  health status, panel integration     |
///   |          |                                       |
///   +----------+---------------------------------------+

// ---------------------------------------------------------------------------
// TEA command helpers
// ---------------------------------------------------------------------------

/// Wrap an async operation as a TEA command.
/// Runs the promise and dispatches the resulting message.
let cmdFromPromise = (
  promiseFn: unit => promise<string>,
  onOk: string => Msg.msg,
  onErr: string => Msg.msg,
): Tea_Cmd.t<Msg.msg> => {
  Tea_Cmd.call(dispatch => {
    promiseFn()
    ->Promise.thenResolve(result => dispatch(onOk(result)))
    ->Promise.catch(err => {
      let errMsg = switch err {
      | JsExn(jsErr) =>
        switch JsExn.message(jsErr) {
        | Some(m) => m
        | None => "Unknown error"
        }
      | _ => "Unknown error"
      }
      dispatch(onErr(errMsg))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Extract a filesystem capability token from the model.
/// Returns None if the filesystem capability has not been granted.
let getFilesystemToken = (model: Model.model): option<float> => {
  switch model.filesystemCap {
  | Granted(token) => Some(token)
  | _ => None
  }
}

/// Extract a network capability token from the model.
/// Returns None if the network capability has not been granted.
let getNetworkToken = (model: Model.model): option<float> => {
  switch model.networkCap {
  | Granted(token) => Some(token)
  | _ => None
  }
}

// ---------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------

/// Initialise the application. Starts with the capability grant panel
/// visible and no clades loaded (filesystem token required first).
let init = (): (Model.model, Tea_Cmd.t<Msg.msg>) => {
  (Model.initial, Tea_Cmd.none)
}

// ---------------------------------------------------------------------------
// Update
// ---------------------------------------------------------------------------

/// Process a message and return the new state plus any commands to execute.
let update = (model: Model.model, msg: Msg.msg): (Model.model, Tea_Cmd.t<Msg.msg>) => {
  switch msg {
  // --- Clade loading ---
  | LoadClades =>
    switch getFilesystemToken(model) {
    | Some(token) =>
      let cmd = cmdFromPromise(
        () => CladeCmd.loadAllCladeSummaries(token),
        result => Msg.CladesLoaded(Ok(result)),
        err => Msg.CladesLoaded(Error(err)),
      )
      ({...model, isLoading: true}, cmd)
    | None => (
        {...model, error: Some("Filesystem capability required. Grant it in the capability panel.")},
        Tea_Cmd.none,
      )
    }

  | CladesLoaded(Ok(_response)) =>
    // In a full implementation, parse the JSON response into cladeSummary records.
    // For now, mark loading complete and clear errors.
    ({...model, isLoading: false, error: None}, Tea_Cmd.none)

  | CladesLoaded(Error(err)) =>
    ({...model, isLoading: false, error: Some(`Failed to load clades: ${err}`)}, Tea_Cmd.none)

  // --- Clade selection ---
  | SelectClade(cladeId) =>
    switch getFilesystemToken(model) {
    | Some(token) =>
      let cmd = cmdFromPromise(
        () => CladeCmd.getCladeDetail(cladeId, token),
        result => Msg.CladeDetailLoaded(Ok(result)),
        err => Msg.CladeDetailLoaded(Error(err)),
      )
      (model, cmd)
    | None => ({...model, error: Some("Filesystem capability required.")}, Tea_Cmd.none)
    }

  | CladeDetailLoaded(Ok(_response)) =>
    // In a full implementation, parse JSON into cladeDetail and set selectedClade.
    ({...model, error: None}, Tea_Cmd.none)

  | CladeDetailLoaded(Error(err)) =>
    ({...model, error: Some(`Failed to load clade detail: ${err}`)}, Tea_Cmd.none)

  | DeselectClade =>
    ({...model, selectedClade: None}, Tea_Cmd.none)

  // --- Relationships ---
  | LoadRelationships(cladeId) =>
    switch getFilesystemToken(model) {
    | Some(token) =>
      let cmd = cmdFromPromise(
        () => CladeCmd.getCladeRelationships(cladeId, token),
        result => Msg.RelationshipsLoaded(Ok(result)),
        err => Msg.RelationshipsLoaded(Error(err)),
      )
      (model, cmd)
    | None => ({...model, error: Some("Filesystem capability required.")}, Tea_Cmd.none)
    }

  | RelationshipsLoaded(Ok(_response)) =>
    // In a full implementation, merge relationship data into selectedClade.
    ({...model, error: None}, Tea_Cmd.none)

  | RelationshipsLoaded(Error(err)) =>
    ({...model, error: Some(`Failed to load relationships: ${err}`)}, Tea_Cmd.none)

  // --- Search ---
  | UpdateSearchQuery(query) =>
    ({...model, searchQuery: query}, Tea_Cmd.none)

  | PerformSearch =>
    if String.length(model.searchQuery) == 0 {
      ({...model, searchResults: []}, Tea_Cmd.none)
    } else {
      switch getFilesystemToken(model) {
      | Some(token) =>
        let cmd = cmdFromPromise(
          () => CladeCmd.searchClades(model.searchQuery, token),
          result => Msg.SearchResultsLoaded(Ok(result)),
          err => Msg.SearchResultsLoaded(Error(err)),
        )
        (model, cmd)
      | None => ({...model, error: Some("Filesystem capability required.")}, Tea_Cmd.none)
      }
    }

  | SearchResultsLoaded(Ok(_response)) =>
    // In a full implementation, parse JSON into searchResult records.
    ({...model, error: None}, Tea_Cmd.none)

  | SearchResultsLoaded(Error(err)) =>
    ({...model, error: Some(`Search failed: ${err}`)}, Tea_Cmd.none)

  | ClearSearch =>
    ({...model, searchQuery: "", searchResults: []}, Tea_Cmd.none)

  // --- View mode ---
  | SetViewMode(mode) =>
    ({...model, viewMode: mode}, Tea_Cmd.none)

  // --- Tree expansion ---
  | ExpandNode(nodeId) =>
    let alreadyExpanded = Array.some(model.expandedNodes, n => n == nodeId)
    if alreadyExpanded {
      (model, Tea_Cmd.none)
    } else {
      ({...model, expandedNodes: Array.concat(model.expandedNodes, [nodeId])}, Tea_Cmd.none)
    }

  | CollapseNode(nodeId) =>
    (
      {...model, expandedNodes: Array.filter(model.expandedNodes, n => n != nodeId)},
      Tea_Cmd.none,
    )

  // --- Health ---
  | CheckCladeHealth(cladeId) =>
    switch getNetworkToken(model) {
    | Some(token) =>
      let cmd = cmdFromPromise(
        () => CladeCmd.getCladeHealth(cladeId, token),
        result => Msg.CladeHealthLoaded(cladeId, Ok(result)),
        err => Msg.CladeHealthLoaded(cladeId, Error(err)),
      )
      (model, cmd)
    | None => ({...model, error: Some("Network capability required for health checks.")}, Tea_Cmd.none)
    }

  | CladeHealthLoaded(_cladeId, Ok(_response)) =>
    // In a full implementation, parse health status and update healthMap.
    ({...model, error: None}, Tea_Cmd.none)

  | CladeHealthLoaded(_cladeId, Error(err)) =>
    ({...model, error: Some(`Health check failed: ${err}`)}, Tea_Cmd.none)

  | CheckAllHealth =>
    switch getNetworkToken(model) {
    | Some(token) =>
      let cmd = cmdFromPromise(
        () => CladeCmd.checkAllCladeHealth(token),
        result => Msg.AllHealthLoaded(Ok(result)),
        err => Msg.AllHealthLoaded(Error(err)),
      )
      (model, cmd)
    | None => ({...model, error: Some("Network capability required for health checks.")}, Tea_Cmd.none)
    }

  | AllHealthLoaded(Ok(_response)) =>
    // In a full implementation, parse batch health data into healthMap.
    ({...model, error: None}, Tea_Cmd.none)

  | AllHealthLoaded(Error(err)) =>
    ({...model, error: Some(`Batch health check failed: ${err}`)}, Tea_Cmd.none)

  // --- Gossamer capability tokens ---
  | RequestCapability(kind) =>
    let kindInt = switch kind {
    | "filesystem" => Capabilities.Kind.filesystem
    | "network" => Capabilities.Kind.network
    | _ => 0
    }
    let updatedModel = switch kind {
    | "filesystem" => {...model, filesystemCap: Pending}
    | "network" => {...model, networkCap: Pending}
    | _ => model
    }
    let cmd = cmdFromPromise(
      () => Capabilities.requestCapability(kindInt)->Promise.thenResolve(token => Float.toString(token)),
      tokenStr => {
        switch Float.fromString(tokenStr) {
        | Some(token) => Msg.CapGranted(kind, token)
        | None => Msg.ClearError
        }
      },
      _err => Msg.CapRevoked(kind),
    )
    (updatedModel, cmd)

  | CapGranted(kind, token) =>
    let updatedModel = switch kind {
    | "filesystem" => {...model, filesystemCap: Granted(token), error: None}
    | "network" => {...model, networkCap: Granted(token), error: None}
    | _ => model
    }
    // Auto-load clades once filesystem token is granted.
    let autoLoadCmd = switch kind {
    | "filesystem" =>
      cmdFromPromise(
        () => CladeCmd.loadAllCladeSummaries(token),
        result => Msg.CladesLoaded(Ok(result)),
        err => Msg.CladesLoaded(Error(err)),
      )
    | _ => Tea_Cmd.none
    }
    ({...updatedModel, isLoading: kind == "filesystem"}, autoLoadCmd)

  | CapRevoked(kind) =>
    switch kind {
    | "filesystem" => ({...model, filesystemCap: Denied}, Tea_Cmd.none)
    | "network" => ({...model, networkCap: Denied}, Tea_Cmd.none)
    | _ => (model, Tea_Cmd.none)
    }

  | DismissCapPanel =>
    ({...model, showCapPanel: false}, Tea_Cmd.none)

  | ShowCapPanel =>
    ({...model, showCapPanel: true}, Tea_Cmd.none)

  // --- UI ---
  | ClearError =>
    ({...model, error: None}, Tea_Cmd.none)

  | NoOp =>
    (model, Tea_Cmd.none)
  }
}

// ---------------------------------------------------------------------------
// View helpers
// ---------------------------------------------------------------------------

/// Render a health indicator dot with the appropriate colour.
let healthDot = (status: Model.healthStatus): Tea_Html.t<Msg.msg> => {
  let (label, className) = switch status {
  | Healthy => ("Healthy", "health-healthy")
  | Degraded => ("Degraded", "health-degraded")
  | Unhealthy => ("Unhealthy", "health-unhealthy")
  | Unknown => ("Unknown", "health-unknown")
  }
  Tea_Html.span(
    [
      Tea_Html.Attributes.class(`health-dot ${className}`),
      Tea_Html.Attributes.title(label),
    ],
    [],
  )
}

/// Render a capability row in the grant panel.
let capabilityRow = (
  kindName: string,
  kindInt: int,
  status: Model.capabilityStatus,
): Tea_Html.t<Msg.msg> => {
  let statusText = switch status {
  | NotRequested => "Not requested"
  | Pending => "Requesting..."
  | Granted(_) => "Granted"
  | Denied => "Denied"
  }
  let statusClass = switch status {
  | NotRequested => "cap-not-requested"
  | Pending => "cap-pending"
  | Granted(_) => "cap-granted"
  | Denied => "cap-denied"
  }
  let button = switch status {
  | NotRequested | Denied =>
    Tea_Html.button(
      [Tea_Html.Events.onClick(Msg.RequestCapability(kindName))],
      [Tea_Html.text("Grant")],
    )
  | Pending =>
    Tea_Html.button(
      [Tea_Html.Attributes.disabled(true)],
      [Tea_Html.text("Pending...")],
    )
  | Granted(_) =>
    Tea_Html.button(
      [Tea_Html.Attributes.disabled(true)],
      [Tea_Html.text("Active")],
    )
  }
  Tea_Html.div(
    [Tea_Html.Attributes.class("cap-row")],
    [
      Tea_Html.div(
        [Tea_Html.Attributes.class("cap-info")],
        [
          Tea_Html.strong([], [Tea_Html.text(Capabilities.Kind.toString(kindInt))]),
          Tea_Html.p([], [Tea_Html.text(Capabilities.Kind.description(kindInt))]),
          Tea_Html.span([Tea_Html.Attributes.class(statusClass)], [Tea_Html.text(statusText)]),
        ],
      ),
      button,
    ],
  )
}

/// Render a single clade entry in the sidebar tree/list.
let cladeEntry = (clade: Model.cladeSummary, isExpanded: bool): Tea_Html.t<Msg.msg> => {
  Tea_Html.div(
    [
      Tea_Html.Attributes.class("clade-entry"),
      Tea_Html.Events.onClick(Msg.SelectClade(clade.id)),
    ],
    [
      Tea_Html.div(
        [Tea_Html.Attributes.class("clade-entry-header")],
        [
          // Expand/collapse toggle for tree view.
          Tea_Html.button(
            [
              Tea_Html.Attributes.class("tree-toggle"),
              Tea_Html.Events.onClick(
                if isExpanded {
                  Msg.CollapseNode(clade.id)
                } else {
                  Msg.ExpandNode(clade.id)
                },
              ),
            ],
            [Tea_Html.text(if isExpanded { "v" } else { ">" })],
          ),
          healthDot(clade.health),
          Tea_Html.span(
            [Tea_Html.Attributes.class("clade-name")],
            [Tea_Html.text(clade.name)],
          ),
          Tea_Html.span(
            [Tea_Html.Attributes.class("clade-kind-badge")],
            [Tea_Html.text(clade.kind)],
          ),
        ],
      ),
      if isExpanded {
        Tea_Html.div(
          [Tea_Html.Attributes.class("clade-entry-detail")],
          [
            Tea_Html.p(
              [Tea_Html.Attributes.class("clade-description")],
              [Tea_Html.text(clade.description)],
            ),
            Tea_Html.span(
              [Tea_Html.Attributes.class("panel-count")],
              [Tea_Html.text(`${Int.toString(clade.panelCount)} panels`)],
            ),
          ],
        )
      } else {
        Tea_Html.noNode
      },
    ],
  )
}

/// Render the view mode toggle buttons.
let viewModeToggle = (current: Model.viewMode): Tea_Html.t<Msg.msg> => {
  let modeButton = (mode: Model.viewMode, label: string) => {
    let isActive = current == mode
    Tea_Html.button(
      [
        Tea_Html.Attributes.class(
          if isActive {
            "view-mode-btn active"
          } else {
            "view-mode-btn"
          },
        ),
        Tea_Html.Events.onClick(Msg.SetViewMode(mode)),
      ],
      [Tea_Html.text(label)],
    )
  }
  Tea_Html.div(
    [Tea_Html.Attributes.class("view-mode-toggle")],
    [
      modeButton(Tree, "Tree"),
      modeButton(List, "List"),
      modeButton(Graph, "Graph"),
    ],
  )
}

/// Render the search bar.
let searchBar = (query: string): Tea_Html.t<Msg.msg> => {
  Tea_Html.div(
    [Tea_Html.Attributes.class("search-bar")],
    [
      Tea_Html.input(
        [
          Tea_Html.Attributes.type_("text"),
          Tea_Html.Attributes.placeholder("Search clades by name, kind, or description..."),
          Tea_Html.Attributes.value(query),
          Tea_Html.Events.onInput(value => Msg.UpdateSearchQuery(value)),
        ],
      ),
      Tea_Html.button(
        [Tea_Html.Events.onClick(Msg.PerformSearch)],
        [Tea_Html.text("Search")],
      ),
      if String.length(query) > 0 {
        Tea_Html.button(
          [
            Tea_Html.Attributes.class("search-clear"),
            Tea_Html.Events.onClick(Msg.ClearSearch),
          ],
          [Tea_Html.text("Clear")],
        )
      } else {
        Tea_Html.noNode
      },
    ],
  )
}

/// Render search results list.
let searchResultsList = (results: array<Model.searchResult>): Tea_Html.t<Msg.msg> => {
  if Array.length(results) == 0 {
    Tea_Html.noNode
  } else {
    Tea_Html.div(
      [Tea_Html.Attributes.class("search-results")],
      [
        Tea_Html.h3([], [Tea_Html.text(`${Int.toString(Array.length(results))} results`)]),
        Tea_Html.div(
          [Tea_Html.Attributes.class("results-list")],
          Array.map(results, result =>
            Tea_Html.div(
              [
                Tea_Html.Attributes.class("search-result-item"),
                Tea_Html.Events.onClick(Msg.SelectClade(result.cladeId)),
              ],
              [
                Tea_Html.strong([], [Tea_Html.text(result.name)]),
                Tea_Html.span(
                  [Tea_Html.Attributes.class("result-kind")],
                  [Tea_Html.text(result.kind)],
                ),
                Tea_Html.p(
                  [Tea_Html.Attributes.class("result-snippet")],
                  [Tea_Html.text(result.matchSnippet)],
                ),
                Tea_Html.span(
                  [Tea_Html.Attributes.class("result-field")],
                  [Tea_Html.text(`Matched: ${result.matchField}`)],
                ),
              ],
            )
          )
          ->Array.toList
          ->List.toArray,
        ),
      ],
    )
  }
}

/// Render trait badges for the detail panel.
let traitBadge = (label: string, isActive: bool): Tea_Html.t<Msg.msg> => {
  Tea_Html.span(
    [
      Tea_Html.Attributes.class(
        if isActive {
          "trait-badge trait-active"
        } else {
          "trait-badge trait-inactive"
        },
      ),
    ],
    [Tea_Html.text(label)],
  )
}

/// Render the detail panel for a selected clade.
let detailPanel = (detail: Model.cladeDetail): Tea_Html.t<Msg.msg> => {
  Tea_Html.div(
    [Tea_Html.Attributes.class("detail-panel")],
    [
      // Header with name, kind badge, and health.
      Tea_Html.div(
        [Tea_Html.Attributes.class("detail-header")],
        [
          Tea_Html.h2([], [Tea_Html.text(detail.name)]),
          Tea_Html.span(
            [Tea_Html.Attributes.class("detail-short-name")],
            [Tea_Html.text(`[${detail.shortName}]`)],
          ),
          Tea_Html.span(
            [Tea_Html.Attributes.class("clade-kind-badge detail-kind")],
            [Tea_Html.text(detail.kind)],
          ),
          healthDot(detail.health),
          Tea_Html.span(
            [Tea_Html.Attributes.class("detail-version")],
            [Tea_Html.text(`v${detail.version}`)],
          ),
        ],
      ),
      // Description.
      Tea_Html.p(
        [Tea_Html.Attributes.class("detail-description")],
        [Tea_Html.text(detail.description)],
      ),
      // Traits grid.
      Tea_Html.div(
        [Tea_Html.Attributes.class("detail-section")],
        [
          Tea_Html.h3([], [Tea_Html.text("Traits")]),
          Tea_Html.div(
            [Tea_Html.Attributes.class("traits-grid")],
            [
              traitBadge("Backend", detail.traits.hasBackend),
              traitBadge("Scanning", detail.traits.hasScanning),
              traitBadge("Persistence", detail.traits.hasPersistence),
              traitBadge("Work Items", detail.traits.hasWorkItems),
              traitBadge("Priority Ordering", detail.traits.hasPriorityOrdering),
              traitBadge("Customisation", detail.traits.hasCustomisation),
              traitBadge("Directive", detail.traits.isDirective),
              traitBadge("Read-only", detail.traits.isReadonly),
            ],
          ),
        ],
      ),
      // Capabilities.
      Tea_Html.div(
        [Tea_Html.Attributes.class("detail-section")],
        [
          Tea_Html.h3([], [Tea_Html.text("Capabilities")]),
          Tea_Html.div(
            [Tea_Html.Attributes.class("capabilities-list")],
            Array.map(detail.capabilities, cap =>
              Tea_Html.span(
                [Tea_Html.Attributes.class("capability-tag")],
                [Tea_Html.text(cap)],
              )
            )
            ->Array.toList
            ->List.toArray,
          ),
        ],
      ),
      // Panel integration.
      Tea_Html.div(
        [Tea_Html.Attributes.class("detail-section")],
        [
          Tea_Html.h3([], [Tea_Html.text("Panel Integration")]),
          Tea_Html.dl(
            [Tea_Html.Attributes.class("integration-list")],
            [
              switch detail.panelId {
              | Some(pid) =>
                Tea_Html.div(
                  [],
                  [
                    Tea_Html.dt([], [Tea_Html.text("Panel ID")]),
                    Tea_Html.dd([], [Tea_Html.text(pid)]),
                  ],
                )
              | None => Tea_Html.noNode
              },
              switch detail.modelModule {
              | Some(m) =>
                Tea_Html.div(
                  [],
                  [
                    Tea_Html.dt([], [Tea_Html.text("Model Module")]),
                    Tea_Html.dd([], [Tea_Html.text(m)]),
                  ],
                )
              | None => Tea_Html.noNode
              },
              switch detail.componentModule {
              | Some(c) =>
                Tea_Html.div(
                  [],
                  [
                    Tea_Html.dt([], [Tea_Html.text("Component Module")]),
                    Tea_Html.dd([], [Tea_Html.text(c)]),
                  ],
                )
              | None => Tea_Html.noNode
              },
              switch detail.commandModule {
              | Some(c) =>
                Tea_Html.div(
                  [],
                  [
                    Tea_Html.dt([], [Tea_Html.text("Command Module")]),
                    Tea_Html.dd([], [Tea_Html.text(c)]),
                  ],
                )
              | None => Tea_Html.noNode
              },
            ],
          ),
        ],
      ),
      // Relationships.
      Tea_Html.div(
        [Tea_Html.Attributes.class("detail-section")],
        [
          Tea_Html.h3([], [Tea_Html.text("Relationships")]),
          switch detail.relationships.parent {
          | Some(parent) =>
            Tea_Html.div(
              [Tea_Html.Attributes.class("relationship-row")],
              [
                Tea_Html.span([Tea_Html.Attributes.class("rel-label")], [Tea_Html.text("Parent:")]),
                Tea_Html.a(
                  [Tea_Html.Events.onClick(Msg.SelectClade(parent))],
                  [Tea_Html.text(parent)],
                ),
              ],
            )
          | None => Tea_Html.noNode
          },
          if Array.length(detail.relationships.siblings) > 0 {
            Tea_Html.div(
              [Tea_Html.Attributes.class("relationship-row")],
              [
                Tea_Html.span(
                  [Tea_Html.Attributes.class("rel-label")],
                  [Tea_Html.text(`Siblings (${Int.toString(Array.length(detail.relationships.siblings))})`)],
                ),
                Tea_Html.div(
                  [Tea_Html.Attributes.class("rel-links")],
                  Array.map(detail.relationships.siblings, sib =>
                    Tea_Html.a(
                      [
                        Tea_Html.Attributes.class("rel-link"),
                        Tea_Html.Events.onClick(Msg.SelectClade(sib)),
                      ],
                      [Tea_Html.text(sib)],
                    )
                  )
                  ->Array.toList
                  ->List.toArray,
                ),
              ],
            )
          } else {
            Tea_Html.noNode
          },
          if Array.length(detail.relationships.children) > 0 {
            Tea_Html.div(
              [Tea_Html.Attributes.class("relationship-row")],
              [
                Tea_Html.span(
                  [Tea_Html.Attributes.class("rel-label")],
                  [Tea_Html.text(`Children (${Int.toString(Array.length(detail.relationships.children))})`)],
                ),
                Tea_Html.div(
                  [Tea_Html.Attributes.class("rel-links")],
                  Array.map(detail.relationships.children, child =>
                    Tea_Html.a(
                      [
                        Tea_Html.Attributes.class("rel-link"),
                        Tea_Html.Events.onClick(Msg.SelectClade(child)),
                      ],
                      [Tea_Html.text(child)],
                    )
                  )
                  ->Array.toList
                  ->List.toArray,
                ),
              ],
            )
          } else {
            Tea_Html.noNode
          },
        ],
      ),
      // File presence indicators.
      Tea_Html.div(
        [Tea_Html.Attributes.class("detail-section")],
        [
          Tea_Html.h3([], [Tea_Html.text("Files")]),
          Tea_Html.div(
            [Tea_Html.Attributes.class("file-indicators")],
            [
              Tea_Html.span(
                [
                  Tea_Html.Attributes.class(
                    if detail.hasK9Config {
                      "file-present"
                    } else {
                      "file-absent"
                    },
                  ),
                ],
                [Tea_Html.text("config.k9.ncl")],
              ),
              Tea_Html.span(
                [
                  Tea_Html.Attributes.class(
                    if detail.hasReadme {
                      "file-present"
                    } else {
                      "file-absent"
                    },
                  ),
                ],
                [Tea_Html.text("README.adoc")],
              ),
            ],
          ),
        ],
      ),
      // Actions.
      Tea_Html.div(
        [Tea_Html.Attributes.class("detail-actions")],
        [
          Tea_Html.button(
            [Tea_Html.Events.onClick(Msg.CheckCladeHealth(detail.id))],
            [Tea_Html.text("Check Health")],
          ),
          Tea_Html.button(
            [Tea_Html.Events.onClick(Msg.LoadRelationships(detail.id))],
            [Tea_Html.text("Refresh Relationships")],
          ),
          Tea_Html.button(
            [
              Tea_Html.Attributes.class("detail-close"),
              Tea_Html.Events.onClick(Msg.DeselectClade),
            ],
            [Tea_Html.text("Close")],
          ),
        ],
      ),
    ],
  )
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

/// Render the complete Clade Portal UI.
let view = (model: Model.model): Tea_Html.t<Msg.msg> => {
  Tea_Html.div(
    [Tea_Html.Attributes.class("clade-portal")],
    [
      // --- Header ---
      Tea_Html.header(
        [Tea_Html.Attributes.class("portal-header")],
        [
          Tea_Html.h1([], [Tea_Html.text("Clade Portal")]),
          Tea_Html.div(
            [Tea_Html.Attributes.class("header-controls")],
            [
              searchBar(model.searchQuery),
              viewModeToggle(model.viewMode),
              Tea_Html.span(
                [Tea_Html.Attributes.class("runtime-badge")],
                [Tea_Html.text(`Runtime: ${RuntimeBridge.runtimeName()}`)],
              ),
              Tea_Html.span(
                [Tea_Html.Attributes.class("clade-count")],
                [Tea_Html.text(`${Int.toString(Array.length(model.clades))} clades`)],
              ),
              Tea_Html.button(
                [Tea_Html.Events.onClick(Msg.CheckAllHealth)],
                [Tea_Html.text("Health Check")],
              ),
              Tea_Html.button(
                [Tea_Html.Events.onClick(Msg.ShowCapPanel)],
                [Tea_Html.text("Capabilities")],
              ),
            ],
          ),
        ],
      ),

      // --- Error bar ---
      switch model.error {
      | Some(err) =>
        Tea_Html.div(
          [Tea_Html.Attributes.class("error-bar")],
          [
            Tea_Html.text(err),
            Tea_Html.button(
              [Tea_Html.Events.onClick(Msg.ClearError)],
              [Tea_Html.text("Dismiss")],
            ),
          ],
        )
      | None => Tea_Html.noNode
      },

      // --- Capability grant panel ---
      if model.showCapPanel {
        Tea_Html.div(
          [Tea_Html.Attributes.class("cap-panel")],
          [
            Tea_Html.h2([], [Tea_Html.text("Gossamer Capability Tokens")]),
            Tea_Html.p(
              [Tea_Html.Attributes.class("cap-description")],
              [
                Tea_Html.text(
                  "Clade Portal runs in a sandboxed Gossamer webview. " ++
                  "Grant capabilities below to enable clade browsing and health monitoring. " ++
                  "Filesystem access is required to read clade metadata. " ++
                  "Network access enables live health indicators.",
                ),
              ],
            ),
            capabilityRow("filesystem", Capabilities.Kind.filesystem, model.filesystemCap),
            capabilityRow("network", Capabilities.Kind.network, model.networkCap),
            Tea_Html.button(
              [
                Tea_Html.Attributes.class("cap-dismiss"),
                Tea_Html.Events.onClick(Msg.DismissCapPanel),
              ],
              [Tea_Html.text("Continue to Clade Portal")],
            ),
          ],
        )
      } else {
        Tea_Html.noNode
      },

      // --- Search results overlay ---
      searchResultsList(model.searchResults),

      // --- Loading indicator ---
      if model.isLoading {
        Tea_Html.div(
          [Tea_Html.Attributes.class("loading-indicator")],
          [Tea_Html.text("Loading clade taxonomy...")],
        )
      } else {
        Tea_Html.noNode
      },

      // --- Main content ---
      Tea_Html.main(
        [Tea_Html.Attributes.class("portal-main")],
        [
          // Sidebar: clade tree/list.
          Tea_Html.aside(
            [Tea_Html.Attributes.class("clade-sidebar")],
            [
              Tea_Html.div(
                [Tea_Html.Attributes.class("sidebar-header")],
                [
                  Tea_Html.h2(
                    [],
                    [
                      Tea_Html.text(
                        switch model.viewMode {
                        | Tree => "Clade Tree"
                        | List => "Clade List"
                        | Graph => "Clade Graph"
                        },
                      ),
                    ],
                  ),
                  Tea_Html.button(
                    [Tea_Html.Events.onClick(Msg.LoadClades)],
                    [Tea_Html.text("Refresh")],
                  ),
                ],
              ),
              Tea_Html.div(
                [Tea_Html.Attributes.class("clade-list")],
                Array.map(model.clades, clade => {
                  let isExpanded = Array.some(model.expandedNodes, n => n == clade.id)
                  cladeEntry(clade, isExpanded)
                })
                ->Array.toList
                ->List.toArray,
              ),
            ],
          ),

          // Detail panel: selected clade or placeholder.
          Tea_Html.section(
            [Tea_Html.Attributes.class("content-panel")],
            [
              switch model.selectedClade {
              | Some(detail) => detailPanel(detail)
              | None =>
                Tea_Html.div(
                  [Tea_Html.Attributes.class("placeholder")],
                  [
                    Tea_Html.h2([], [Tea_Html.text("PanLL Clade Taxonomy")]),
                    Tea_Html.p(
                      [],
                      [
                        Tea_Html.text(
                          "Select a clade from the sidebar to view its metadata, " ++
                          "traits, capabilities, panel integration details, and " ++
                          "relationships to other clades.",
                        ),
                      ],
                    ),
                    Tea_Html.p(
                      [Tea_Html.Attributes.class("placeholder-stats")],
                      [
                        Tea_Html.text(
                          `${Int.toString(Array.length(model.clades))} clades loaded`,
                        ),
                      ],
                    ),
                  ],
                )
              },
            ],
          ),
        ],
      ),
    ],
  )
}

// ---------------------------------------------------------------------------
// Main — TEA program registration
// ---------------------------------------------------------------------------

/// Start the Clade Portal TEA application.
/// Mounts into the #app element in public/index.html.
let main = Tea_App.standardProgram({
  init: () => init(),
  update: update,
  view: view,
  subscriptions: _model => Tea_Sub.none,
})
