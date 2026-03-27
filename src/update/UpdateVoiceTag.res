// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for VoiceTag panel — file tag loading, voice commands,
/// tag CRUD, project scanning, and TypeLL integration.

open Model
open Msg

let updateVoiceTag = (model: model, msg: voiceTagMsg): (model, Tea_Cmd.t<msg>) => {
  let vt = model.voiceTag
  switch msg {
  | LoadFileTags =>
    switch vt.currentFile {
    | Some(filePath) => (
        {...model, voiceTag: {...vt, error: None}},
        Tea_Cmd.batch(list{
          VoiceTagCmd.loadTags(filePath, result => VoiceTag(TagsLoaded(result))),
          TypeLLService.checkMetadataTypes(filePath, "voicetag", result => VoiceTag(
            TypeCheckResult(result),
          )),
        }),
      )
    | None => ({...model, voiceTag: {...vt, error: Some("No file selected")}}, Tea_Cmd.none)
    }
  | TagsLoaded(result) =>
    switch result {
    | Ok(jsonStr) => // Parse the .mri.json content. For now, extract tags array from JSON.
      // Full parsing deferred to when we have proper JSON codec — store raw.
      switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(parsed) =>
        switch JSON.Classify.classify(parsed) {
        | JSON.Classify.Object(dict) => {
            let tags = switch dict->Dict.get("tags") {
            | Some(tagsJson) =>
              switch JSON.Classify.classify(tagsJson) {
              | JSON.Classify.Array(arr) =>
                arr->Array.mapWithIndex((json, idx) => {
                  // Minimal tag parsing — extract what we can from each JSON object
                  switch JSON.Classify.classify(json) {
                  | JSON.Classify.Object(tagDict) => {
                      let getStr = (key: string): string =>
                        switch tagDict->Dict.get(key) {
                        | Some(v) =>
                          switch JSON.Classify.classify(v) {
                          | JSON.Classify.String(s) => s
                          | _ => ""
                          }
                        | None => ""
                        }
                      let getInt = (key: string): int =>
                        switch tagDict->Dict.get(key) {
                        | Some(v) =>
                          switch JSON.Classify.classify(v) {
                          | JSON.Classify.Number(n) => Float.toInt(n)
                          | _ => 0
                          }
                        | None => 0
                        }
                      let getBool = (key: string): bool =>
                        switch tagDict->Dict.get(key) {
                        | Some(v) =>
                          switch JSON.Classify.classify(v) {
                          | JSON.Classify.Bool(b) => b
                          | _ => false
                          }
                        | None => false
                        }
                      let getOptStr = (key: string): option<string> =>
                        switch tagDict->Dict.get(key) {
                        | Some(v) =>
                          switch JSON.Classify.classify(v) {
                          | JSON.Classify.String(s) => Some(s)
                          | JSON.Classify.Null => None
                          | _ => None
                          }
                        | None => None
                        }
                      let tag: mriTag = {
                        id: getInt("id") > 0 ? getInt("id") : idx + 1,
                        startLine: getInt("startLine"),
                        endLine: getInt("endLine"),
                        tagType: VoiceTagEngine.tagTypeFromString(getStr("tagType")),
                        message: getOptStr("message"),
                        attribution: {
                          agent: getStr("agent") === "" ? "human" : getStr("agent"),
                          method: VoiceTagEngine.methodFromString(getStr("method")),
                          timestamp: switch tagDict->Dict.get("timestamp") {
                          | Some(v) =>
                            switch JSON.Classify.classify(v) {
                            | JSON.Classify.Number(n) => n
                            | _ => 0.0
                            }
                          | None => 0.0
                          },
                          sessionId: None,
                        },
                        codeAuthor: None,
                        resolved: getBool("resolved"),
                        resolvedBy: None,
                      }
                      tag
                    }
                  | _ => {
                      let fallback: mriTag = {
                        id: idx + 1,
                        startLine: 0,
                        endLine: 0,
                        tagType: Note,
                        message: Some("(malformed tag)"),
                        attribution: {
                          agent: "unknown",
                          method: Import("parse-error"),
                          timestamp: 0.0,
                          sessionId: None,
                        },
                        codeAuthor: None,
                        resolved: false,
                        resolvedBy: None,
                      }
                      fallback
                    }
                  }
                })
              | _ => []
              }
            | None => []
            }
            let summary = VoiceTagEngine.computeSummary(tags)
            (
              {
                ...model,
                voiceTag: {
                  ...vt,
                  tags,
                  summary,
                  error: None,
                },
              },
              Tea_Cmd.none,
            )
          }
        | _ => ({...model, voiceTag: {...vt, tags: [], error: None}}, Tea_Cmd.none)
        }

      | None => (
          {...model, voiceTag: {...vt, error: Some("Failed to parse .mri.json")}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => ({...model, voiceTag: {...vt, error: Some(e)}}, Tea_Cmd.none)
    }
  | TagsSaved(result) =>
    switch result {
    | Ok(_) => ({...model, voiceTag: {...vt, error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, voiceTag: {...vt, error: Some(e)}}, Tea_Cmd.none)
    }
  | SidecarDeleted(result) =>
    switch result {
    | Ok(_) => ({...model, voiceTag: {...vt, error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, voiceTag: {...vt, error: Some(e)}}, Tea_Cmd.none)
    }
  | ProjectScanned(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
          let getInt = key =>
            obj->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          Some({
            VoiceTagModel.totalTags: getInt("totalTags"),
            unresolvedTags: getInt("unresolvedTags"),
            todoCount: getInt("todoCount"),
            fixmeCount: getInt("fixmeCount"),
            careOnRegions: getInt("careOnRegions"),
            ecoModeRegions: getInt("ecoModeRegions"),
            burdenRegions: getInt("burdenRegions"),
            aiTagCount: getInt("aiTagCount"),
            humanTagCount: getInt("humanTagCount"),
          })

        | None => None
        }
        switch parsed {
        | Some(summary) => ({...model, voiceTag: {...vt, summary}}, Tea_Cmd.none)
        | None => (model, Tea_Cmd.none)
        }
      }
    | Error(e) => ({...model, voiceTag: {...vt, error: Some(e)}}, Tea_Cmd.none)
    }
  | SelectTag(id) => ({...model, voiceTag: {...vt, selectedTagId: id}}, Tea_Cmd.none)
  | DeleteTagById(id) => {
      let newTags = VoiceTagEngine.removeTag(vt.tags, id)
      let newSummary = VoiceTagEngine.computeSummary(newTags)
      let newModel = {
        ...model,
        voiceTag: {...vt, tags: newTags, summary: newSummary, selectedTagId: None},
      }
      // Auto-save after deletion. If no tags remain, delete the sidecar.
      switch vt.currentFile {
      | Some(filePath) =>
        if Array.length(newTags) === 0 {
          (
            newModel,
            VoiceTagCmd.deleteSidecar(filePath, result => VoiceTag(SidecarDeleted(result))),
          )
        } else {
          // Serialise and save — simplified JSON output for now.
          let json = `{"version":"1.0","sourceFile":"${filePath}","tags":[],"lastModified":${Float.toString(
              Date.now(),
            )}}`
          (newModel, VoiceTagCmd.saveTags(filePath, json, result => VoiceTag(TagsSaved(result))))
        }
      | None => (newModel, Tea_Cmd.none)
      }
    }
  | ResolveTagById(id) => {
      let newTags = VoiceTagEngine.resolveTag(vt.tags, id, "human")
      let newSummary = VoiceTagEngine.computeSummary(newTags)
      ({...model, voiceTag: {...vt, tags: newTags, summary: newSummary}}, Tea_Cmd.none)
    }
  | SetFilterType(filterType) => ({...model, voiceTag: {...vt, filterType}}, Tea_Cmd.none)
  | ToggleShowResolved => (
      {...model, voiceTag: {...vt, showResolved: !vt.showResolved}},
      Tea_Cmd.none,
    )
  | StartVoice => ({...model, voiceTag: {...vt, voice: VoiceListening, error: None}}, Tea_Cmd.none)
  | StopVoice => ({...model, voiceTag: {...vt, voice: VoiceOff}}, Tea_Cmd.none)
  | VoiceTranscript(transcript) => {
      // Parse the voice command and apply it.
      let cmd = VoiceTagEngine.parseVoiceCommand(transcript)
      switch cmd {
      | VoiceTagEngine.TagRange(startLine, endLine, tagType, message) => {
          let newTag = VoiceTagEngine.createTagWithAttribution(
            vt.tags,
            startLine,
            endLine,
            tagType,
            message,
            "human",
            Voice,
          )
          let newTags = VoiceTagEngine.addTag(vt.tags, newTag)
          let newSummary = VoiceTagEngine.computeSummary(newTags)
          (
            {...model, voiceTag: {...vt, tags: newTags, summary: newSummary, voice: VoiceOff}},
            Tea_Cmd.none,
          )
        }
      | VoiceTagEngine.TagSelection(tagType, message) => {
          // Tag at line 1 (no selection context available — future: use editor selection).
          let newTag = VoiceTagEngine.createTagWithAttribution(
            vt.tags,
            1,
            1,
            tagType,
            message,
            "human",
            Voice,
          )
          let newTags = VoiceTagEngine.addTag(vt.tags, newTag)
          let newSummary = VoiceTagEngine.computeSummary(newTags)
          (
            {...model, voiceTag: {...vt, tags: newTags, summary: newSummary, voice: VoiceOff}},
            Tea_Cmd.none,
          )
        }
      | VoiceTagEngine.DeleteTag(id) => {
          let newTags = VoiceTagEngine.removeTag(vt.tags, id)
          let newSummary = VoiceTagEngine.computeSummary(newTags)
          (
            {...model, voiceTag: {...vt, tags: newTags, summary: newSummary, voice: VoiceOff}},
            Tea_Cmd.none,
          )
        }
      | VoiceTagEngine.ResolveTag(id) => {
          let newTags = VoiceTagEngine.resolveTag(vt.tags, id, "human")
          let newSummary = VoiceTagEngine.computeSummary(newTags)
          (
            {...model, voiceTag: {...vt, tags: newTags, summary: newSummary, voice: VoiceOff}},
            Tea_Cmd.none,
          )
        }
      | VoiceTagEngine.ShowTag(id) => (
          {...model, voiceTag: {...vt, selectedTagId: Some(id), voice: VoiceOff}},
          Tea_Cmd.none,
        )
      | VoiceTagEngine.ShowAll(maybeType) => (
          {...model, voiceTag: {...vt, filterType: maybeType, voice: VoiceOff}},
          Tea_Cmd.none,
        )
      | VoiceTagEngine.EditTag(_)
      | VoiceTagEngine.WhoWroteLine(_)
      | VoiceTagEngine.AttributeHuman
      | VoiceTagEngine.AttributeAi(_) => // These commands need editor integration — stub for now.
        ({...model, voiceTag: {...vt, voice: VoiceOff}}, Tea_Cmd.none)
      | VoiceTagEngine.VoiceUnrecognised(raw) => (
          {...model, voiceTag: {...vt, voice: Model.VoiceError(`Unrecognised: "${raw}"`)}},
          Tea_Cmd.none,
        )
      }
    }
  | VoiceError(err) => ({...model, voiceTag: {...vt, voice: Model.VoiceError(err)}}, Tea_Cmd.none)
  | SetCurrentFile(filePath) => (
      {
        ...model,
        voiceTag: {
          ...vt,
          currentFile: Some(filePath),
          tags: [],
          summary: VoiceTagEngine.emptySummary,
          error: None,
        },
      },
      VoiceTagCmd.loadTags(filePath, result => VoiceTag(TagsLoaded(result))),
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "voicetag", json)
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
