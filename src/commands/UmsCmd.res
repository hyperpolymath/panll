// SPDX-License-Identifier: MPL-2.0

/// PanLL Universal Modding Studio Commands — backend invoke wrappers for
/// mod project management, ABI validation, template instantiation,
/// asset pipeline, distribution, and API reference loading.

let invoke = RuntimeBridge.invoke

/// Load all mod projects from the UMS projects directory.
let loadProjects = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_load_projects", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load projects")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Create a new mod project with the given name and description.
let createProject = (
  name: string,
  description: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_create_project", {"name": name, "description": description})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to create project")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Open an existing mod project by its ID.
let openProject = (projectId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_open_project", {"projectId": projectId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to open project")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Delete a mod project by its ID.
let deleteProject = (projectId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_delete_project", {"projectId": projectId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to delete project")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run ABI validation on a level within the current project.
let validateLevel = (levelId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_validate_level", {"levelId": levelId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ABI validation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load available mod templates.
let loadTemplates = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_load_templates", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load templates")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Instantiate a mod template to create a new project.
let instantiateTemplate = (
  templateId: string,
  projectName: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_instantiate_template", {"templateId": templateId, "projectName": projectName})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to instantiate template")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load assets for the currently selected project.
let loadAssets = (projectId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_load_assets", {"projectId": projectId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load assets")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Import an asset file into the current project.
let importAsset = (
  projectId: string,
  filePath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_import_asset", {"projectId": projectId, "filePath": filePath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to import asset")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Publish the current mod to a distribution target.
let publishMod = (
  projectId: string,
  platform: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_publish_mod", {"projectId": projectId, "platform": platform})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to publish mod")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load the modding API reference documentation.
let loadApiReference = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ums_load_api_reference", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load API reference")))
      Promise.resolve()
    })
    ->ignore
  })
}
