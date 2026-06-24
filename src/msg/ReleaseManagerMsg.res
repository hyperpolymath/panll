// SPDX-License-Identifier: MPL-2.0

/// Release Manager messages -- version bumping, changelog generation,
/// artifact building, signing, publishing, and channel management for
/// the IDApTIK release distribution panel.

open Model

type releaseManagerMsg =
  /// Switch the active category tab.
  | SetReleaseCategory(releaseManagerCategory)
  /// Bump the version (patch, minor, major).
  | BumpVersion(string)
  /// Version bumped (or failed).
  | VersionBumped(result<string, string>)
  /// Select a release to view details.
  | SelectRelease(string)
  /// Generate changelog from git history.
  | GenerateChangelog
  /// Changelog generated (or failed).
  | ChangelogGenerated(result<string, string>)
  /// Toggle auto-changelog generation.
  | ToggleAutoChangelog
  /// Toggle a platform target for artifact building.
  | TogglePlatform(platformTarget)
  /// Build artifacts for enabled platforms.
  | BuildArtifacts
  /// Artifacts built (or failed).
  | ArtifactsBuilt(result<string, string>)
  /// Publish a release.
  | PublishRelease
  /// Release published (or failed).
  | ReleasePublished(result<string, string>)
  /// Set the release channel.
  | SetChannel(releaseChannel)
  /// Toggle artifact signing.
  | ToggleSignArtifacts
  /// Load release history.
  | LoadReleases
  /// Releases loaded (or failed).
  | ReleasesLoaded(result<string, string>)
  /// Dismiss the error banner.
  | DismissReleaseError
  /// TypeLL cross-panel type check result for release types.
  | TypeCheckResult(result<string, string>)
