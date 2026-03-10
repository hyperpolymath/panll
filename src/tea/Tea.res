// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea.res — The Elm Architecture for ReScript
//
// A comprehensive, self-contained TEA implementation featuring:
// - Virtual DOM with keyed child diffing and fragment support
// - SVG namespace-aware rendering
// - Type-safe HTTP client and JSON decoders
// - Rich subscription modules (keyboard, mouse, window, time, animation)
// - Server-side rendering to HTML strings
// - Time-travel debugger
// - Testing helpers
//
// Built for PanLL eNSAID with integrated DOM safety (SafeMount, Trusted Types).

/// Commands (side effects) module
module Cmd = Tea_Cmd

/// Subscriptions (external event sources) module
module Sub = Tea_Sub

/// HTML element constructors, attributes, and events
module Html = Tea_Html

/// SVG element constructors and attributes
module Svg = Tea_Svg

/// Virtual DOM core types and constructors
module Vdom = Tea_Vdom

/// TEA application runtime (init/update/view/subscriptions loop)
module App = Tea_App

/// DOM rendering engine with virtual DOM diffing
module Render = Tea_Render

/// Type-safe HTTP client (fetch-based)
module Http = Tea_Http

/// Elm-style JSON decoders
module Json = Tea_Json

/// Time-based subscriptions (intervals, timeouts)
module Time = Tea_Time

/// Animation frame subscriptions (requestAnimationFrame)
module Animationframe = Tea_Animationframe

/// Keyboard event subscriptions
module Keyboard = Tea_Keyboard

/// Mouse event subscriptions
module Mouse = Tea_Mouse

/// Window/document event subscriptions (resize, focus, scroll, etc.)
module Window = Tea_Window

/// Server-side rendering (virtual DOM to HTML string)
module Ssr = Tea_Ssr

/// Time-travel debugger for TEA programs
module Debug = Tea_Debug

/// Testing helpers for TEA model-update-view cycle
module Test = Tea_Test

/// Create a standard TEA program with subscriptions
let standardProgram = Tea_App.standardProgram

/// Create a simple TEA program (no subscriptions)
let simpleProgram = Tea_App.simpleProgram
