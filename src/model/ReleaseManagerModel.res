// SPDX-License-Identifier: MPL-2.0

/// PanLL Release Manager Model — types for versioning, changelog
/// generation, packaging, and distribution of IDApTIK builds.

/// Release channel.
type releaseChannel =
  | ChannelDev
  | ChannelAlpha
  | ChannelBeta
  | ChannelRC
  | ChannelStable

/// Platform target for builds.
type platformTarget =
  | PlatformWeb
  | PlatformDesktopLinux
  | PlatformDesktopMac
  | PlatformDesktopWindows
  | PlatformMobileAndroid
  | PlatformMobileIOS

/// Build artifact.
type releaseArtifact = {
  name: string,
  platform: platformTarget,
  filePath: string,
  sizeBytes: int,
  checksum: string,
  builtAt: float,
}

/// Changelog entry.
type changelogEntry = {
  version: string,
  date: string,
  category: string,
  description: string,
  commitHash: string,
  author: string,
}

/// Release status.
type releaseStatus =
  | ReleaseDraft
  | ReleaseBuilding
  | ReleaseReady
  | ReleasePublished
  | ReleaseFailed(string)

/// A release version.
type releaseVersion = {
  version: string,
  channel: releaseChannel,
  status: releaseStatus,
  artifacts: array<releaseArtifact>,
  changelog: array<changelogEntry>,
  createdAt: float,
  publishedAt: option<float>,
}

/// Category tabs for the Release Manager panel.
type releaseManagerCategory =
  | ReleaseOverview
  | ReleaseChangelog
  | ReleaseArtifacts
  | ReleaseDistribution

/// Root state for the Release Manager panel.
type releaseManagerState = {
  activeCategory: releaseManagerCategory,
  currentVersion: string,
  nextVersion: string,
  channel: releaseChannel,
  releases: array<releaseVersion>,
  pendingChangelog: array<changelogEntry>,
  artifacts: array<releaseArtifact>,
  selectedRelease: option<string>,
  enabledPlatforms: array<platformTarget>,
  autoChangelog: bool,
  signArtifacts: bool,
  loading: bool,
  error: option<string>,
}
