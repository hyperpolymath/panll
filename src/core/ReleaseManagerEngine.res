// SPDX-License-Identifier: MPL-2.0

/// PanLL Release Manager Engine — pure computation and helpers for
/// versioning, changelog, packaging, and distribution.

open ReleaseManagerModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: releaseManagerCategory): string =>
  switch cat {
  | ReleaseOverview => "Overview"
  | ReleaseChangelog => "Changelog"
  | ReleaseArtifacts => "Artifacts"
  | ReleaseDistribution => "Distribution"
  }

/// Release channel label.
let channelLabel = (channel: releaseChannel): string =>
  switch channel {
  | ChannelDev => "Dev"
  | ChannelAlpha => "Alpha"
  | ChannelBeta => "Beta"
  | ChannelRC => "Release Candidate"
  | ChannelStable => "Stable"
  }

/// Channel colour.
let channelColour = (channel: releaseChannel): string =>
  switch channel {
  | ChannelDev => "text-gray-400"
  | ChannelAlpha => "text-amber-400"
  | ChannelBeta => "text-cyan-400"
  | ChannelRC => "text-purple-400"
  | ChannelStable => "text-emerald-400"
  }

/// Platform label.
let platformLabel = (platform: platformTarget): string =>
  switch platform {
  | PlatformWeb => "Web"
  | PlatformDesktopLinux => "Linux"
  | PlatformDesktopMac => "macOS"
  | PlatformDesktopWindows => "Windows"
  | PlatformMobileAndroid => "Android"
  | PlatformMobileIOS => "iOS"
  }

/// All platforms.
let allPlatforms: array<platformTarget> = [
  PlatformWeb,
  PlatformDesktopLinux,
  PlatformDesktopMac,
  PlatformDesktopWindows,
  PlatformMobileAndroid,
  PlatformMobileIOS,
]

/// Release status label.
let statusLabel = (status: releaseStatus): string =>
  switch status {
  | ReleaseDraft => "Draft"
  | ReleaseBuilding => "Building..."
  | ReleaseReady => "Ready"
  | ReleasePublished => "Published"
  | ReleaseFailed(err) => `Failed: ${err}`
  }

/// Release status colour.
let statusColour = (status: releaseStatus): string =>
  switch status {
  | ReleaseDraft => "text-gray-400"
  | ReleaseBuilding => "text-amber-400"
  | ReleaseReady => "text-cyan-400"
  | ReleasePublished => "text-emerald-400"
  | ReleaseFailed(_) => "text-red-400"
  }

/// Format file size.
let formatSize = (bytes: int): string => {
  if bytes < 1024 {
    `${Int.toString(bytes)}B`
  } else if bytes < 1024 * 1024 {
    `${Int.toString(bytes / 1024)}KB`
  } else {
    `${Int.toString(bytes / (1024 * 1024))}MB`
  }
}

/// Default state for the Release Manager panel.
let defaultState: releaseManagerState = {
  activeCategory: ReleaseOverview,
  currentVersion: "0.0.0",
  nextVersion: "0.1.0",
  channel: ChannelDev,
  releases: [],
  pendingChangelog: [],
  artifacts: [],
  selectedRelease: None,
  enabledPlatforms: [PlatformWeb, PlatformDesktopLinux],
  autoChangelog: true,
  signArtifacts: true,
  loading: false,
  error: None,
}
