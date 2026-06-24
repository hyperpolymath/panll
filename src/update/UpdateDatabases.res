// SPDX-License-Identifier: MPL-2.0
// UpdateDatabases.res — Databases (unified database management panel) sub-updater extracted from Update.res

open Model
open Msg

let updateDatabases = (model: model, msg: databasesMsg): (model, Tea_Cmd.t<msg>) => {
  let db = model.databases
  switch msg {
  | SetCategory(cat) => ({...model, databases: {...db, activeCategory: cat}}, Tea_Cmd.none)
  | SelectModule(id) => (
      {...model, databases: {...db, selectedModule: id, selectedEntity: None, entityDetail: None}},
      Tea_Cmd.none,
    )
  | ConnectAll => ({...model, databases: {...db, loading: true}}, Tea_Cmd.none)
  | RefreshHealth => ({...model, databases: {...db, loading: true}}, Tea_Cmd.none)
  | HealthResult(moduleId, Ok(_json)) =>
    let updated = DatabasesEngine.updateModule(db, moduleId, m => {
      ...m,
      connection: DatabaseModule.Connected(m.config.endpoint),
    })
    ({...model, databases: {...updated, loading: false, error: None}}, Tea_Cmd.none)
  | HealthResult(moduleId, Error(err)) =>
    let updated = DatabasesEngine.updateModule(db, moduleId, m => {
      ...m,
      connection: DatabaseModule.Error(err),
    })
    ({...model, databases: {...updated, loading: false}}, Tea_Cmd.none)
  | SetQueryInput(value) => ({...model, databases: {...db, queryInput: value}}, Tea_Cmd.none)
  | ExecuteQuery => ({...model, databases: {...db, queryLoading: true}}, Tea_Cmd.none)
  | QueryResult(Ok(json)) =>
    let entry: DatabasesModel.queryHistoryEntry = {
      moduleId: db.selectedModule,
      query: db.queryInput,
      durationMs: 0.0,
      rowCount: 0,
      success: true,
      timestamp: "",
    }
    let updated = DatabasesEngine.updateModule(db, db.selectedModule, m => {
      ...m,
      queryResult: Some({
        columns: [],
        rows: [],
        rowCount: 0,
        timingMs: 0.0,
        statementType: "SELECT",
        message: Some(json),
      }),
      queryError: None,
    })
    let withHistory = DatabasesEngine.addToHistory(updated, entry)
    ({...model, databases: {...withHistory, queryLoading: false}}, Tea_Cmd.none)
  | QueryResult(Error(err)) =>
    let entry: DatabasesModel.queryHistoryEntry = {
      moduleId: db.selectedModule,
      query: db.queryInput,
      durationMs: 0.0,
      rowCount: 0,
      success: false,
      timestamp: "",
    }
    let updated = DatabasesEngine.updateModule(db, db.selectedModule, m => {
      ...m,
      queryResult: None,
      queryError: Some(err),
    })
    let withHistory = DatabasesEngine.addToHistory(updated, entry)
    ({...model, databases: {...withHistory, queryLoading: false}}, Tea_Cmd.none)
  | ClearQuery =>
    let updated = DatabasesEngine.updateModule(db, db.selectedModule, m => {
      ...m,
      queryResult: None,
      queryError: None,
    })
    ({...model, databases: {...updated, queryInput: "", queryLoading: false}}, Tea_Cmd.none)
  | LoadExampleQuery(query) => (
      {...model, databases: {...db, queryInput: query, activeCategory: DatabasesModel.DbQuery}},
      Tea_Cmd.none,
    )
  | SetFilter(value) => ({...model, databases: {...db, filterText: value}}, Tea_Cmd.none)
  | SelectEntity(name) => (
      {...model, databases: {...db, selectedEntity: Some(name), entityDetail: None}},
      Tea_Cmd.none,
    )
  | LoadEntityDetail(_name) => ({...model, databases: {...db, loading: true}}, Tea_Cmd.none)
  | EntityDetailResult(Ok(json)) => (
      {...model, databases: {...db, entityDetail: Some(json), loading: false}},
      Tea_Cmd.none,
    )
  | EntityDetailResult(Error(err)) => (
      {...model, databases: {...db, error: Some(err), loading: false}},
      Tea_Cmd.none,
    )
  | RefreshDrift => ({...model, databases: {...db, loading: true}}, Tea_Cmd.none)
  | DriftResult(Ok(_json)) => ({...model, databases: {...db, loading: false}}, Tea_Cmd.none)
  | DriftResult(Error(err)) => (
      {...model, databases: {...db, error: Some(err), loading: false}},
      Tea_Cmd.none,
    )
  | NormaliseAll => ({...model, databases: {...db, loading: true}}, Tea_Cmd.none)
  | NormaliseResult(Ok(_)) => ({...model, databases: {...db, loading: false}}, Tea_Cmd.none)
  | NormaliseResult(Error(err)) => (
      {...model, databases: {...db, error: Some(err), loading: false}},
      Tea_Cmd.none,
    )
  | LoadTelemetry => ({...model, databases: {...db, loading: true}}, Tea_Cmd.none)
  | TelemetryResult(Ok(_json)) => ({...model, databases: {...db, loading: false}}, Tea_Cmd.none)
  | TelemetryResult(Error(err)) => (
      {...model, databases: {...db, error: Some(err), loading: false}},
      Tea_Cmd.none,
    )
  | ToggleBojRouting => ({...model, databases: {...db, bojRouting: !db.bojRouting}}, Tea_Cmd.none)
  | DismissError => ({...model, databases: {...db, error: None}}, Tea_Cmd.none)
  }
}
