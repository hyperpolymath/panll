// SPDX-License-Identifier: PMPL-1.0-or-later

/// A2ML manifest messages -- loading, validation, and listing of AI manifests.

type a2mlMsg =
  /// Load a specific A2ML manifest file.
  | LoadManifest(string)
  /// Manifest loaded result.
  | ManifestLoaded(result<string, string>)
  /// Validate a manifest file.
  | ValidateManifest(string)
  /// Validation result.
  | ManifestValidated(result<string, string>)
  /// List all A2ML manifests in the repo.
  | ListManifests
  /// List result.
  | ManifestsListed(result<string, string>)
  /// TypeLL cross-panel type check result for A2ML manifest types.
  | TypeCheckResult(result<string, string>)
