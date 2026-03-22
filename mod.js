// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
// (PMPL-1.0-or-later preferred; MPL-2.0 required for JSR registry)

/**
 * @module @hyperpolymath/panll
 *
 * PanLL — Panel Layout Language runtime library.
 *
 * Provides the TEA (The Elm Architecture) framework for ReScript,
 * panel bus event system, and core panel infrastructure for building
 * tiling panel-based applications.
 *
 * @example
 * ```ts
 * import { Tea, PanelBus } from "@hyperpolymath/panll";
 * ```
 */

// TEA framework — ReScript-compiled ES modules
export * as Tea from "./src/tea/Tea.res.js";
export * as Tea_App from "./src/tea/Tea_App.res.js";
export * as Tea_Cmd from "./src/tea/Tea_Cmd.res.js";
export * as Tea_Sub from "./src/tea/Tea_Sub.res.js";
export * as Tea_Html from "./src/tea/Tea_Html.res.js";
export * as Tea_Svg from "./src/tea/Tea_Svg.res.js";
export * as Tea_Vdom from "./src/tea/Tea_Vdom.res.js";
export * as Tea_Render from "./src/tea/Tea_Render.res.js";
export * as Tea_Http from "./src/tea/Tea_Http.res.js";
export * as Tea_Json from "./src/tea/Tea_Json.res.js";
export * as Tea_Time from "./src/tea/Tea_Time.res.js";
export * as Tea_Keyboard from "./src/tea/Tea_Keyboard.res.js";
export * as Tea_Mouse from "./src/tea/Tea_Mouse.res.js";
export * as Tea_Window from "./src/tea/Tea_Window.res.js";
export * as Tea_Ssr from "./src/tea/Tea_Ssr.res.js";
export * as Tea_Debug from "./src/tea/Tea_Debug.res.js";
export * as Tea_Test from "./src/tea/Tea_Test.res.js";
export * as Tea_Animationframe from "./src/tea/Tea_Animationframe.res.js";

// Core panel infrastructure
export * as PanelBus from "./src/core/PanelBus.res.js";
export * as TilingEngine from "./src/core/TilingEngine.res.js";
export * as EventChain from "./src/core/EventChain.res.js";
export * as SmartRouter from "./src/core/SmartRouter.res.js";
export * as SafeMount from "./src/core/SafeMount.res.js";
export * as SafeDOMCore from "./src/core/SafeDOMCore.res.js";
export * as WindowBridge from "./src/core/WindowBridge.res.js";
export * as KeyboardUtil from "./src/core/KeyboardUtil.res.js";
export * as DebugLogger from "./src/core/DebugLogger.res.js";
export * as AntiCrash from "./src/core/AntiCrash.res.js";
export * as UndoEngine from "./src/core/UndoEngine.res.js";
export * as Decoders from "./src/core/Decoders.res.js";
