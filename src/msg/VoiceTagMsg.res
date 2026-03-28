// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI VoiceTag messages -- tag CRUD, voice input lifecycle, file I/O,
/// and filter controls. VoiceTag is an ambient annotation system (Layer 0)
/// that stores tags as portable `.mri.json` sidecar files.

open Model

type voiceTagMsg =
  /// Load tags from the .mri.json sidecar for the current file.
  | LoadFileTags
  /// Tags loaded from disk (or error).
  | TagsLoaded(result<string, string>)
  /// Tags saved to disk (or error).
  | TagsSaved(result<string, string>)
  /// Sidecar deleted (or error).
  | SidecarDeleted(result<string, string>)
  /// Project scan result (list of all .mri.json files).
  | ProjectScanned(result<string, string>)
  /// Select a tag by ID (for voice reference or click).
  | SelectTag(option<int>)
  /// Delete a tag by ID.
  | DeleteTagById(int)
  /// Resolve a tag by ID.
  | ResolveTagById(int)
  /// Set the type filter.
  | SetFilterType(option<mriTagType>)
  /// Toggle showing resolved tags.
  | ToggleShowResolved
  /// Start voice recognition.
  | StartVoice
  /// Stop voice recognition.
  | StopVoice
  /// Voice transcript received from Web Speech API.
  | VoiceTranscript(string)
  /// Voice recognition error.
  | VoiceError(string)
  /// Set current file path (when user opens a file).
  | SetCurrentFile(string)
  /// TypeLL cross-panel type check result for tag schema types.
  | TypeCheckResult(result<string, string>)
