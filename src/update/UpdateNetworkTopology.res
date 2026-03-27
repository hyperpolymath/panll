// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for the Network Topology panel.
/// Manages the IDApTIK network topology visualisation — device/connection parsing,
/// DNS table, packet flow animation, SVG export, and security level overlays.

open Model
open Msg

let updateNetworkTopology = (model: model, msg: networkTopologyMsg): (model, Tea_Cmd.t<msg>) => {
  let nt = model.networkTopology
  switch msg {
  | SetTopologyCategory(cat) => (
      {...model, networkTopology: {...nt, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | RefreshTopology => (
      {...model, networkTopology: {...nt, loading: true}},
      Tea_Cmd.batch(list{
        NetworkTopologyCmd.readTopology(result => NetworkTopology(TopologyReceived(result))),
        TypeLLService.checkGameDataTypes("topology", "network-topology", result => NetworkTopology(
          TypeCheckResult(result),
        )),
      }),
    )
  | TopologyReceived(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let devArr = obj->Dict.get("devices")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let devices = devArr->Array.filterMap(d => {
          let dObj = d->JSON.Decode.object->Option.getOr(Dict.make())
          let id = dObj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = dObj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let deviceType =
            dObj->Dict.get("deviceType")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let zoneStr =
            dObj->Dict.get("zone")->Option.flatMap(JSON.Decode.string)->Option.getOr("public")
          let zone = switch zoneStr {
          | "dmz" => NetworkTopologyModel.ZoneDmz
          | "internal" => ZoneInternal
          | "restricted" => ZoneRestricted
          | "air_gapped" => ZoneAirGapped
          | _ => ZonePublic
          }
          let securityLevel =
            dObj->Dict.get("securityLevel")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let x = dObj->Dict.get("x")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let y = dObj->Dict.get("y")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let flagsArr =
            dObj->Dict.get("defenceFlags")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
          let defenceFlags = flagsArr->Array.filterMap(f => f->JSON.Decode.string)
          let compromised =
            dObj->Dict.get("compromised")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let active =
            dObj->Dict.get("active")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
          Some({
            NetworkTopologyModel.id,
            name,
            deviceType,
            zone,
            securityLevel: Float.toInt(securityLevel),
            x,
            y,
            defenceFlags,
            compromised,
            active,
          })
        })
        let connArr =
          obj->Dict.get("connections")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let connections = connArr->Array.filterMap(c => {
          let cObj = c->JSON.Decode.object->Option.getOr(Dict.make())
          let sourceId =
            cObj->Dict.get("sourceId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let targetId =
            cObj->Dict.get("targetId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let protoStr =
            cObj->Dict.get("protocol")->Option.flatMap(JSON.Decode.string)->Option.getOr("custom")
          let protocol = switch protoStr {
          | "ssh" => NetworkTopologyModel.ProtoSSH
          | "https" => ProtoHTTPS
          | "ftp" => ProtoFTP
          | "dns" => ProtoDNS
          | other => ProtoCustom(other)
          }
          let encrypted =
            cObj->Dict.get("encrypted")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let packetCount =
            cObj->Dict.get("packetCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let latencyMs =
            cObj->Dict.get("latencyMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let active =
            cObj->Dict.get("active")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
          Some({
            NetworkTopologyModel.sourceId,
            targetId,
            protocol,
            encrypted,
            packetCount: Float.toInt(packetCount),
            latencyMs,
            active,
          })
        })
        Some((devices, connections))

      | None => None
      }
      switch parsed {
      | Some((devices, connections)) => (
          {
            ...model,
            networkTopology: {
              ...nt,
              devices,
              connections,
              loading: false,
              error: None,
            },
          },
          Tea_Cmd.none,
        )
      | None => ({...model, networkTopology: {...nt, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | TopologyReceived(Error(err)) => (
      {...model, networkTopology: {...nt, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectDevice(id) => (
      {...model, networkTopology: {...nt, selectedDeviceId: Some(id)}},
      Tea_Cmd.none,
    )
  | DeselectDevice => ({...model, networkTopology: {...nt, selectedDeviceId: None}}, Tea_Cmd.none)
  | RefreshDns => (
      {...model, networkTopology: {...nt, loading: true}},
      NetworkTopologyCmd.readDnsTable(result => NetworkTopology(DnsReceived(result))),
    )
  | DnsReceived(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let entries = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let hostname =
            obj->Dict.get("hostname")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let resolvedIp =
            obj->Dict.get("resolvedIp")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let recordType =
            obj->Dict.get("recordType")->Option.flatMap(JSON.Decode.string)->Option.getOr("A")
          let ttl = obj->Dict.get("ttl")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            NetworkTopologyModel.hostname,
            resolvedIp,
            recordType,
            ttl: Float.toInt(ttl),
          })
        })
        Some(entries)

      | None => None
      }
      switch parsed {
      | Some(entries) => (
          {...model, networkTopology: {...nt, dnsEntries: entries, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, networkTopology: {...nt, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | DnsReceived(Error(err)) => (
      {...model, networkTopology: {...nt, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | TogglePacketAnimation => (
      {...model, networkTopology: {...nt, animatePackets: !nt.animatePackets}},
      if !nt.animatePackets {
        NetworkTopologyCmd.readPacketFlow(result => NetworkTopology(PacketFlowReceived(result)))
      } else {
        Tea_Cmd.none
      },
    )
  | PacketFlowReceived(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let events = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let connectionId =
            obj->Dict.get("connectionId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let timestamp =
            obj->Dict.get("timestamp")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let size = obj->Dict.get("size")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let blocked =
            obj->Dict.get("blocked")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          Some({
            NetworkTopologyModel.connectionId,
            timestamp,
            size: Float.toInt(size),
            blocked,
          })
        })
        Some(events)

      | None => None
      }
      switch parsed {
      | Some(events) => (
          {...model, networkTopology: {...nt, packetFlow: events, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, networkTopology: {...nt, error: None}}, Tea_Cmd.none)
      }
    }
  | PacketFlowReceived(Error(err)) => (
      {...model, networkTopology: {...nt, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleLabels => ({...model, networkTopology: {...nt, showLabels: !nt.showLabels}}, Tea_Cmd.none)
  | ToggleSecurityLevels => (
      {...model, networkTopology: {...nt, showSecurityLevels: !nt.showSecurityLevels}},
      Tea_Cmd.none,
    )
  | ExportTopologySvg => (
      model,
      NetworkTopologyCmd.exportSvg(result => NetworkTopology(TopologySvgExported(result))),
    )
  | TopologySvgExported(Ok(_)) => (model, Tea_Cmd.none)
  | TopologySvgExported(Error(err)) => (
      {...model, networkTopology: {...nt, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissTopoError => ({...model, networkTopology: {...nt, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "networktopology", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
