// SPDX-License-Identifier: MPL-2.0
// UpdateReleaseManager.res — Release Manager (versioning and distribution) sub-updater extracted from Update.res

open Model
open Msg

/// Handles all Release Manager (versioning and distribution) messages.
let updateReleaseManager = (model: model, msg: releaseManagerMsg): (model, Tea_Cmd.t<msg>) => {
  let rm = model.releaseManager
  switch msg {
  | SetReleaseCategory(cat) => (
      {...model, releaseManager: {...rm, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | BumpVersion(bumpType) => (
      {...model, releaseManager: {...rm, loading: true}},
      ReleaseManagerCmd.bumpVersion(bumpType, result => ReleaseManager(VersionBumped(result))),
    )
  | VersionBumped(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let currentVersion =
          obj
          ->Dict.get("currentVersion")
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr(rm.currentVersion)
        let nextVersion =
          obj
          ->Dict.get("nextVersion")
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr(rm.nextVersion)
        Some((currentVersion, nextVersion))

      | None => None
      }
      switch parsed {
      | Some((currentVersion, nextVersion)) => (
          {
            ...model,
            releaseManager: {...rm, currentVersion, nextVersion, loading: false, error: None},
          },
          Tea_Cmd.none,
        )
      | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | VersionBumped(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectRelease(version) => (
      {...model, releaseManager: {...rm, selectedRelease: Some(version)}},
      Tea_Cmd.none,
    )
  | GenerateChangelog => (
      {...model, releaseManager: {...rm, loading: true}},
      ReleaseManagerCmd.generateChangelog(rm.currentVersion, result => ReleaseManager(
        ChangelogGenerated(result),
      )),
    )
  | ChangelogGenerated(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let version =
            obj->Dict.get("version")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let date = obj->Dict.get("date")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let category =
            obj->Dict.get("category")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let description =
            obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let commitHash =
            obj->Dict.get("commitHash")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let author = obj->Dict.get("author")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          Some({
            ReleaseManagerModel.version,
            date,
            category,
            description,
            commitHash,
            author,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(entries) => (
          {
            ...model,
            releaseManager: {...rm, pendingChangelog: entries, loading: false, error: None},
          },
          Tea_Cmd.none,
        )
      | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | ChangelogGenerated(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleAutoChangelog => (
      {...model, releaseManager: {...rm, autoChangelog: !rm.autoChangelog}},
      Tea_Cmd.none,
    )
  | TogglePlatform(platform) => {
      let enabled = rm.enabledPlatforms->Array.includes(platform)
      let newPlatforms = if enabled {
        rm.enabledPlatforms->Array.filter(p => p !== platform)
      } else {
        Array.concat(rm.enabledPlatforms, [platform])
      }
      ({...model, releaseManager: {...rm, enabledPlatforms: newPlatforms}}, Tea_Cmd.none)
    }
  | BuildArtifacts => {
      let platformStr =
        rm.enabledPlatforms
        ->Array.map(ReleaseManagerEngine.platformLabel)
        ->Array.join(",")
      (
        {...model, releaseManager: {...rm, loading: true}},
        ReleaseManagerCmd.buildArtifacts(rm.nextVersion, platformStr, result => ReleaseManager(
          ArtifactsBuilt(result),
        )),
      )
    }
  | ArtifactsBuilt(Ok(jsonStr)) => {
      let parsePlatform = (s: string): ReleaseManagerModel.platformTarget =>
        switch s {
        | "web" => PlatformWeb
        | "linux" => PlatformDesktopLinux
        | "mac" => PlatformDesktopMac
        | "windows" => PlatformDesktopWindows
        | "android" => PlatformMobileAndroid
        | "ios" => PlatformMobileIOS
        | _ => PlatformWeb
        }
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let platformStr =
            obj->Dict.get("platform")->Option.flatMap(JSON.Decode.string)->Option.getOr("web")
          let platform = parsePlatform(platformStr)
          let filePath =
            obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let sizeBytes =
            obj->Dict.get("sizeBytes")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let checksum =
            obj->Dict.get("checksum")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let builtAt =
            obj->Dict.get("builtAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            ReleaseManagerModel.name,
            platform,
            filePath,
            sizeBytes: Float.toInt(sizeBytes),
            checksum,
            builtAt,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(artifacts) => (
          {...model, releaseManager: {...rm, artifacts, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | ArtifactsBuilt(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PublishRelease => (
      {...model, releaseManager: {...rm, loading: true}},
      Tea_Cmd.batch(list{
        ReleaseManagerCmd.publishRelease(
          rm.nextVersion,
          ReleaseManagerEngine.channelLabel(rm.channel),
          result => ReleaseManager(ReleasePublished(result)),
        ),
        TypeLLService.checkConfigTypes(rm.nextVersion, "release-manager", result => ReleaseManager(
          TypeCheckResult(result),
        )),
      }),
    )
  | ReleasePublished(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let version =
          obj->Dict.get("version")->Option.flatMap(JSON.Decode.string)->Option.getOr(rm.nextVersion)
        let publishedAt = obj->Dict.get("publishedAt")->Option.flatMap(JSON.Decode.float)
        let newRelease: ReleaseManagerModel.releaseVersion = {
          version,
          channel: rm.channel,
          status: ReleasePublished,
          artifacts: rm.artifacts,
          changelog: rm.pendingChangelog,
          createdAt: Date.now(),
          publishedAt,
        }
        Some(newRelease)

      | None => None
      }
      switch parsed {
      | Some(release) => (
          {
            ...model,
            releaseManager: {
              ...rm,
              releases: Array.concat([release], rm.releases),
              currentVersion: release.version,
              loading: false,
              error: None,
            },
          },
          Tea_Cmd.none,
        )
      | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | ReleasePublished(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetChannel(ch) => ({...model, releaseManager: {...rm, channel: ch}}, Tea_Cmd.none)
  | ToggleSignArtifacts => (
      {...model, releaseManager: {...rm, signArtifacts: !rm.signArtifacts}},
      Tea_Cmd.none,
    )
  | LoadReleases => (
      {...model, releaseManager: {...rm, loading: true}},
      ReleaseManagerCmd.readReleases(result => ReleaseManager(ReleasesLoaded(result))),
    )
  | ReleasesLoaded(Ok(jsonStr)) => {
      let parseChannel = (s: string): ReleaseManagerModel.releaseChannel =>
        switch s {
        | "dev" => ChannelDev
        | "alpha" => ChannelAlpha
        | "beta" => ChannelBeta
        | "rc" => ChannelRC
        | _ => ChannelStable
        }
      let parseStatus = (s: string): ReleaseManagerModel.releaseStatus =>
        switch s {
        | "draft" => ReleaseDraft
        | "building" => ReleaseBuilding
        | "ready" => ReleaseReady
        | "published" => ReleasePublished
        | _ => ReleaseDraft
        }
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let version =
            obj->Dict.get("version")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let channelStr =
            obj->Dict.get("channel")->Option.flatMap(JSON.Decode.string)->Option.getOr("stable")
          let channel = parseChannel(channelStr)
          let statusStr =
            obj->Dict.get("status")->Option.flatMap(JSON.Decode.string)->Option.getOr("draft")
          let status = parseStatus(statusStr)
          let createdAt =
            obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let publishedAt = obj->Dict.get("publishedAt")->Option.flatMap(JSON.Decode.float)
          Some({
            ReleaseManagerModel.version,
            channel,
            status,
            artifacts: [],
            changelog: [],
            createdAt,
            publishedAt,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(releases) => (
          {...model, releaseManager: {...rm, releases, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | ReleasesLoaded(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissReleaseError => ({...model, releaseManager: {...rm, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "releasemanager", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
