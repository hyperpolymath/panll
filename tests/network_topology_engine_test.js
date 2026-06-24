// SPDX-License-Identifier: MPL-2.0

/**
 * NetworkTopologyEngine Tests — category labels, zone labels, zone colours,
 * protocol labels, device/connection filtering, and default state validation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  categoryLabel,
  zoneLabel,
  zoneColour,
  zoneBgColour,
  protocolLabel,
  devicesByZone,
  connectionsForDevice,
  defaultState,
} from "../src/core/NetworkTopologyEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("TopologyGraph"), "Graph");
  assertEquals(categoryLabel("TopologyZones"), "Zones");
  assertEquals(categoryLabel("TopologyDns"), "DNS");
  assertEquals(categoryLabel("TopologyPacketFlow"), "Packet Flow");
});

// -- zoneLabel --

Deno.test("zoneLabel returns correct strings for all zones", () => {
  assertEquals(zoneLabel("ZonePublic"), "Public");
  assertEquals(zoneLabel("ZoneDmz"), "DMZ");
  assertEquals(zoneLabel("ZoneInternal"), "Internal");
  assertEquals(zoneLabel("ZoneRestricted"), "Restricted");
  assertEquals(zoneLabel("ZoneAirGapped"), "Air-Gapped");
});

// -- zoneColour --

Deno.test("zoneColour returns Tailwind text-colour classes", () => {
  assertEquals(zoneColour("ZonePublic"), "text-red-400");
  assertEquals(zoneColour("ZoneDmz"), "text-amber-400");
  assertEquals(zoneColour("ZoneInternal"), "text-emerald-400");
  assertEquals(zoneColour("ZoneRestricted"), "text-blue-400");
  assertEquals(zoneColour("ZoneAirGapped"), "text-purple-400");
});

// -- zoneBgColour --

Deno.test("zoneBgColour returns Tailwind background classes", () => {
  assertEquals(zoneBgColour("ZonePublic"), "bg-red-900/30");
  assertEquals(zoneBgColour("ZoneDmz"), "bg-amber-900/30");
  assertEquals(zoneBgColour("ZoneInternal"), "bg-emerald-900/30");
  assertEquals(zoneBgColour("ZoneRestricted"), "bg-blue-900/30");
  assertEquals(zoneBgColour("ZoneAirGapped"), "bg-purple-900/30");
});

// -- protocolLabel --

Deno.test("protocolLabel returns correct strings for standard protocols", () => {
  assertEquals(protocolLabel("ProtoSSH"), "SSH");
  assertEquals(protocolLabel("ProtoHTTPS"), "HTTPS");
  assertEquals(protocolLabel("ProtoFTP"), "FTP");
  assertEquals(protocolLabel("ProtoDNS"), "DNS");
});

Deno.test("protocolLabel returns custom name for ProtoCustom", () => {
  assertEquals(protocolLabel({ TAG: "ProtoCustom", _0: "MQTT" }), "MQTT");
  assertEquals(protocolLabel({ TAG: "ProtoCustom", _0: "gRPC" }), "gRPC");
});

// -- devicesByZone --

Deno.test("devicesByZone filters devices by zone", () => {
  const devices = [
    { id: "d1", zone: "ZonePublic", name: "Web Server" },
    { id: "d2", zone: "ZoneInternal", name: "DB Server" },
    { id: "d3", zone: "ZonePublic", name: "Load Balancer" },
    { id: "d4", zone: "ZoneDmz", name: "Proxy" },
  ];
  const result = devicesByZone(devices, "ZonePublic");
  assertEquals(result.length, 2);
  assertEquals(result[0].id, "d1");
  assertEquals(result[1].id, "d3");
});

Deno.test("devicesByZone returns empty array when no matches", () => {
  const devices = [
    { id: "d1", zone: "ZonePublic", name: "Web Server" },
  ];
  const result = devicesByZone(devices, "ZoneAirGapped");
  assertEquals(result.length, 0);
});

Deno.test("devicesByZone returns empty array for empty devices", () => {
  const result = devicesByZone([], "ZonePublic");
  assertEquals(result.length, 0);
});

// -- connectionsForDevice --

Deno.test("connectionsForDevice finds connections where device is source", () => {
  const connections = [
    { sourceId: "d1", targetId: "d2", protocol: "ProtoSSH" },
    { sourceId: "d3", targetId: "d4", protocol: "ProtoHTTPS" },
  ];
  const result = connectionsForDevice(connections, "d1");
  assertEquals(result.length, 1);
  assertEquals(result[0].sourceId, "d1");
});

Deno.test("connectionsForDevice finds connections where device is target", () => {
  const connections = [
    { sourceId: "d1", targetId: "d2", protocol: "ProtoSSH" },
    { sourceId: "d3", targetId: "d2", protocol: "ProtoHTTPS" },
  ];
  const result = connectionsForDevice(connections, "d2");
  assertEquals(result.length, 2);
});

Deno.test("connectionsForDevice finds connections as both source and target", () => {
  const connections = [
    { sourceId: "d1", targetId: "d2", protocol: "ProtoSSH" },
    { sourceId: "d2", targetId: "d3", protocol: "ProtoHTTPS" },
    { sourceId: "d4", targetId: "d5", protocol: "ProtoFTP" },
  ];
  const result = connectionsForDevice(connections, "d2");
  assertEquals(result.length, 2);
});

Deno.test("connectionsForDevice returns empty array when no matches", () => {
  const connections = [
    { sourceId: "d1", targetId: "d2", protocol: "ProtoSSH" },
  ];
  const result = connectionsForDevice(connections, "d99");
  assertEquals(result.length, 0);
});

Deno.test("connectionsForDevice returns empty array for empty connections", () => {
  const result = connectionsForDevice([], "d1");
  assertEquals(result.length, 0);
});

// -- defaultState --

Deno.test("defaultState activeCategory is TopologyGraph", () => {
  assertEquals(defaultState.activeCategory, "TopologyGraph");
});

Deno.test("defaultState has empty devices", () => {
  assertEquals(defaultState.devices.length, 0);
});

Deno.test("defaultState has empty connections", () => {
  assertEquals(defaultState.connections.length, 0);
});

Deno.test("defaultState has empty dnsEntries", () => {
  assertEquals(defaultState.dnsEntries.length, 0);
});

Deno.test("defaultState has empty packetFlow", () => {
  assertEquals(defaultState.packetFlow.length, 0);
});

Deno.test("defaultState selectedDeviceId is undefined (None)", () => {
  assertEquals(defaultState.selectedDeviceId, undefined);
});

Deno.test("defaultState has empty highlightedPath", () => {
  assertEquals(defaultState.highlightedPath.length, 0);
});

Deno.test("defaultState showLabels is true", () => {
  assertEquals(defaultState.showLabels, true);
});

Deno.test("defaultState showSecurityLevels is true", () => {
  assertEquals(defaultState.showSecurityLevels, true);
});

Deno.test("defaultState animatePackets is false", () => {
  assertEquals(defaultState.animatePackets, false);
});

Deno.test("defaultState zoomLevel is 1.0", () => {
  assertEquals(defaultState.zoomLevel, 1.0);
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});
