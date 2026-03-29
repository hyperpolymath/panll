// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Capture Engine — pure functions for screenshot, recording, demo,
/// cloning, and comparison operations (DD-022).
///
/// All functions are pure: (state, action) -> state. Actual screenshot/recording
/// side effects happen via CaptureCmd Gossamer wrappers.

open CaptureModel

// ============================================================================
// Capture Operations
// ============================================================================

/// Add a capture entry to the gallery.
let addCapture = (state: captureState, entry: captureEntry): captureState => {
  {...state, captures: Array.concat(state.captures, [entry])}
}

/// Remove a capture by ID.
let removeCapture = (state: captureState, captureId: string): captureState => {
  {...state, captures: Array.filter(state.captures, c => c.id !== captureId)}
}

/// Start recording a panel.
let startRecording = (state: captureState, panelId: string, timestamp: float): captureState => {
  {...state, recording: Recording(panelId, timestamp)}
}

/// Pause an ongoing recording.
let pauseRecording = (state: captureState, elapsed: float): captureState => {
  switch state.recording {
  | Recording(panelId, _) => {...state, recording: Paused(panelId, elapsed)}
  | _ => state
  }
}

/// Resume a paused recording.
let resumeRecording = (state: captureState, timestamp: float): captureState => {
  switch state.recording {
  | Paused(panelId, _) => {...state, recording: Recording(panelId, timestamp)}
  | _ => state
  }
}

/// Stop recording and produce a capture entry.
let stopRecording = (state: captureState): captureState => {
  {...state, recording: NotRecording}
}

/// Toggle a panel's selection for multi-panel capture.
let toggleCaptureSelection = (state: captureState, panelId: string): captureState => {
  let selected = state.selectedForCapture
  let alreadySelected = Array.some(selected, id => id === panelId)
  let newSelected = if alreadySelected {
    Array.filter(selected, id => id !== panelId)
  } else {
    Array.concat(selected, [panelId])
  }
  {...state, selectedForCapture: newSelected}
}

/// Clear multi-panel capture selection.
let clearSelection = (state: captureState): captureState => {
  {...state, selectedForCapture: []}
}

// ============================================================================
// Demo Operations
// ============================================================================

/// Add a demo package.
let addDemo = (state: captureState, demo: demoPackage): captureState => {
  {...state, demos: Array.concat(state.demos, [demo])}
}

/// Remove a demo by ID.
let removeDemo = (state: captureState, demoId: string): captureState => {
  {...state, demos: Array.filter(state.demos, d => d.id !== demoId)}
}

/// Start demo playback.
let startDemo = (state: captureState, demoId: string): captureState => {
  {...state, activeDemo: Some(demoId), activeDemoStep: 0}
}

/// Advance to the next demo step.
let nextDemoStep = (state: captureState): captureState => {
  switch state.activeDemo {
  | Some(demoId) => {
      let demo = Array.find(state.demos, d => d.id === demoId)
      switch demo {
      | Some(d) =>
        if state.activeDemoStep < Array.length(d.steps) - 1 {
          {...state, activeDemoStep: state.activeDemoStep + 1}
        } else {
          state
        }
      | None => state
      }
    }
  | None => state
  }
}

/// Go back to the previous demo step.
let prevDemoStep = (state: captureState): captureState => {
  if state.activeDemoStep > 0 {
    {...state, activeDemoStep: state.activeDemoStep - 1}
  } else {
    state
  }
}

/// Stop demo playback.
let stopDemo = (state: captureState): captureState => {
  {...state, activeDemo: None, activeDemoStep: 0, comparison: NoComparison}
}

// ============================================================================
// Comparison Operations
// ============================================================================

/// Enter side-by-side comparison mode.
let setSideBySide = (state: captureState, leftId: string, rightId: string): captureState => {
  {...state, comparison: SideBySide(leftId, rightId)}
}

/// Enter demo comparison mode (student vs golden output).
let setDemoComparison = (
  state: captureState,
  studentPanelId: string,
  demoStepCaptureId: string,
): captureState => {
  {...state, comparison: DemoComparison(studentPanelId, demoStepCaptureId)}
}

/// Enter before/after comparison mode.
let setBeforeAfter = (state: captureState, beforeId: string, afterId: string): captureState => {
  {...state, comparison: BeforeAfter(beforeId, afterId)}
}

/// Exit comparison mode.
let exitComparison = (state: captureState): captureState => {
  {...state, comparison: NoComparison}
}

// ============================================================================
// Clone Operations
// ============================================================================

/// Clone a panel's state.
let clonePanel = (state: captureState, clone: panelClone): captureState => {
  {...state, clones: Array.concat(state.clones, [clone])}
}

/// Remove a clone by ID.
let removeClone = (state: captureState, cloneId: string): captureState => {
  {...state, clones: Array.filter(state.clones, c => c.id !== cloneId)}
}

// ============================================================================
// Default State
// ============================================================================

/// Initial capture state.
let defaultState: captureState = {
  captures: [],
  recording: NotRecording,
  selectedForCapture: [],
  demos: [],
  activeDemo: None,
  activeDemoStep: 0,
  comparison: NoComparison,
  clones: [],
  activeCategory: CaptureGallery,
  captureBarVisible: true,
  fullEnvironmentCapture: false,
}
