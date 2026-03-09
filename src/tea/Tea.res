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

module Cmd = Tea_Cmd
module Sub = Tea_Sub
module Html = Tea_Html
module Svg = Tea_Svg
module Vdom = Tea_Vdom
module App = Tea_App
module Render = Tea_Render
module Http = Tea_Http
module Json = Tea_Json
module Time = Tea_Time
module Animationframe = Tea_Animationframe
module Keyboard = Tea_Keyboard
module Mouse = Tea_Mouse
module Window = Tea_Window
module Ssr = Tea_Ssr
module Debug = Tea_Debug
module Test = Tea_Test

let standardProgram = Tea_App.standardProgram
let simpleProgram = Tea_App.simpleProgram
