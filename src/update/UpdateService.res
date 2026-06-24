// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// UpdateService — TEA state transitions for the PanLL service registry.
///
/// Pure updater for service health checks, URL changes, and registry refresh.
/// Follows the standard (model, msg) => (model, cmd) pattern.

open Model
open Msg

/// Parse a service status string from the backend JSON into a serviceStatus variant.
let parseServiceStatus = (json: JSON.t): serviceStatus => {
  switch JSON.Classify.classify(json) {
  | Object(d) =>
    switch d->Dict.get("status") {
    | Some(v) =>
      switch JSON.Classify.classify(v) {
      | String("Running") => Running
      | String("Stopped") => Stopped
      | String("Checking") => Checking
      | String("Error") =>
        switch d->Dict.get("message") {
        | Some(m) =>
          switch JSON.Classify.classify(m) {
          | String(s) => Error(s)
          | _ => Error("Unknown error")
          }
        | None => Error("Unknown error")
        }
      | _ => Stopped
      }
    | None => Stopped
    }
  | _ => Stopped
  }
}

/// Parse a single service entry from backend JSON.
let parseServiceEntry = (json: JSON.t): option<serviceEntry> => {
  switch JSON.Classify.classify(json) {
  | Object(d) => {
      let name =
        d->Dict.get("name")->Option.flatMap(v =>
          switch JSON.Classify.classify(v) {
          | String(s) => Some(s)
          | _ => None
          }
        )
      let url =
        d->Dict.get("url")->Option.flatMap(v =>
          switch JSON.Classify.classify(v) {
          | String(s) => Some(s)
          | _ => None
          }
        )
      let healthPath =
        d
        ->Dict.get("health_path")
        ->Option.flatMap(v =>
          switch JSON.Classify.classify(v) {
          | String(s) => Some(s)
          | _ => None
          }
        )
      switch (name, url, healthPath) {
      | (Some(n), Some(u), Some(hp)) =>
        Some({
          name: n,
          url: u,
          healthPath: hp,
          status: parseServiceStatus(json),
        })
      | _ => None
      }
    }
  | _ => None
  }
}

/// Parse the full registry response from the backend.
/// The backend returns a JSON object keyed by service identifier.
let parseRegistryResponse = (jsonStr: string): Dict.t<serviceEntry> => {
  try {
    let parsed = JSON.parseExn(jsonStr)
    switch JSON.Classify.classify(parsed) {
    | Object(d) => {
        let result = Dict.make()
        let keys = d->Dict.keysToArray
        keys->Array.forEach(key => {
          switch d->Dict.get(key) {
          | Some(value) =>
            switch parseServiceEntry(value) {
            | Some(entry) => result->Dict.set(key, entry)
            | None => ()
            }
          | None => ()
          }
        })
        result
      }
    | _ => Dict.make()
    }
  } catch {
  | _ => Dict.make()
  }
}

/// Service registry updater — routes service messages to state transitions.
let updateService = (model: model, subMsg: serviceMsg): (model, Tea_Cmd.t<msg>) => {
  let reg = model.serviceRegistry
  switch subMsg {
  | RefreshAll => (
      {...model, serviceRegistry: {...reg, isRefreshing: true}},
      ServiceCmd.refreshAll(result => Service(RefreshAllResult(result))),
    )
  | RefreshAllResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let services = parseRegistryResponse(jsonStr)
        (
          {
            ...model,
            serviceRegistry: {
              services,
              lastChecked: Some(Date.now()),
              isRefreshing: false,
            },
          },
          Tea_Cmd.none,
        )
      }
    | Error(_) => ({...model, serviceRegistry: {...reg, isRefreshing: false}}, Tea_Cmd.none)
    }
  | CheckService(key) => {
      // Mark as checking
      let services = Dict.make()
      reg.services->Dict.forEachWithKey((v, k) => {
        if k === key {
          services->Dict.set(k, {...v, status: Checking})
        } else {
          services->Dict.set(k, v)
        }
      })
      (
        {...model, serviceRegistry: {...reg, services}},
        ServiceCmd.checkService(key, result => Service(CheckServiceResult(key, result))),
      )
    }
  | CheckServiceResult(key, result) =>
    switch result {
    | Ok(jsonStr) => {
        let services = Dict.make()
        reg.services->Dict.forEachWithKey((v, k) => {
          if k === key {
            switch parseServiceEntry(JSON.parseExn(jsonStr)) {
            | Some(entry) => services->Dict.set(k, entry)
            | None => services->Dict.set(k, v)
            }
          } else {
            services->Dict.set(k, v)
          }
        })
        ({...model, serviceRegistry: {...reg, services}}, Tea_Cmd.none)
      }
    | Error(err) => {
        let services = Dict.make()
        reg.services->Dict.forEachWithKey((v, k) => {
          if k === key {
            services->Dict.set(k, {...v, status: Error(err)})
          } else {
            services->Dict.set(k, v)
          }
        })
        ({...model, serviceRegistry: {...reg, services}}, Tea_Cmd.none)
      }
    }
  | UpdateServiceUrl(key, newUrl) => {
      let services = Dict.make()
      reg.services->Dict.forEachWithKey((v, k) => {
        if k === key {
          services->Dict.set(k, {...v, url: newUrl, status: Stopped})
        } else {
          services->Dict.set(k, v)
        }
      })
      (
        {...model, serviceRegistry: {...reg, services}},
        ServiceCmd.updateServiceUrl(key, newUrl, result => Service(UpdateServiceUrlResult(result))),
      )
    }
  | UpdateServiceUrlResult(_) => (model, Tea_Cmd.none)
  | RegistryLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let services = parseRegistryResponse(jsonStr)
        ({...model, serviceRegistry: {...reg, services}}, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  }
}
