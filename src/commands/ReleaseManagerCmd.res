// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Release Manager Commands — backend invoke wrappers for versioning,
/// changelog generation, artifact building, and distribution.

let invoke = RuntimeBridge.invoke

/// Generate a changelog from git history.
let generateChangelog = (fromVersion: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("release_generate_changelog", {"fromVersion": fromVersion})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to generate changelog")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Build artifacts for the specified platforms.
let buildArtifacts = (
  version: string,
  platforms: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("release_build_artifacts", {"version": version, "platforms": platforms})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Artifact build failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Publish a release.
let publishRelease = (
  version: string,
  channel: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("release_publish", {"version": version, "channel": channel})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to publish release")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read release history.
let readReleases = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("release_read_history", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read releases")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Bump the version number.
let bumpVersion = (bumpType: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("release_bump_version", {"bumpType": bumpType})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to bump version")))
      Promise.resolve()
    })
    ->ignore
  })
}
