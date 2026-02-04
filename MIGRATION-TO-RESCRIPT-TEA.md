# Migration from Custom TEA to Official rescript-tea

## Overview

This document tracks the migration from our custom TEA implementation (`src/tea/`) to the official `rescript-tea` package (v0.16.0).

## Status: IN PROGRESS

- [x] Install rescript-tea@0.16.0
- [x] Update package.json
- [ ] Update imports to use Tea module from rescript-tea
- [ ] Migrate keyboard subscriptions
- [ ] Migrate Tauri command effects
- [ ] Test basic TEA cycle
- [ ] Remove custom src/tea/ directory (after migration complete)

## Module Mapping

| Custom Module | Official Module | Status | Notes |
|---------------|----------------|--------|-------|
| `src/tea/Tea.res` | `Tea` (from rescript-tea) | 🔄 Migrate | Main entry point |
| `src/tea/Tea_App.res` | `Tea.App` or `Tea_App` | 🔄 Migrate | standardProgram available |
| `src/tea/Tea_Cmd.res` | `Tea_Cmd` | 🔄 Migrate | Commands for side effects |
| `src/tea/Tea_Sub.res` | `Tea_Sub` | 🔄 Migrate | Subscriptions for events |
| `src/tea/Tea_Html.res` | `Tea_Html` | 🔄 Migrate | HTML DSL |
| `src/tea/Tea_Vdom.res` | `Vdom` | 🔄 Migrate | Virtual DOM |
| `src/tea/Tea_Render.res` | (built-in) | 🔄 Migrate | Handled by rescript-tea |

## Official rescript-tea Modules Available

From `node_modules/rescript-tea/src/`:

- ✅ `tea_app.res` - Application runtime
- ✅ `tea_cmd.res` - Commands
- ✅ `tea_sub.res` - Subscriptions
- ✅ `tea_html.res` - HTML DSL
- ✅ `vdom.res` - Virtual DOM
- ✅ `tea_time.res` - Time subscriptions
- ✅ `tea_mouse.res` - Mouse events
- ✅ `tea_navigation.res` - Routing/navigation **⭐**
- ✅ `tea_http.res` - HTTP requests
- ✅ `tea_json.res` - JSON encoding/decoding
- ✅ `tea_task.res` - Task abstraction
- ✅ `tea_promise.res` - Promise integration
- ✅ `tea_animationframe.res` - Animation frames
- ✅ `tea_random.res` - Random number generation
- ✅ `tea_debug.res` - Debugging utilities

## Key Differences

### 1. Import Syntax

**Before (Custom)**:
```rescript
open Tea.App
open Tea.Html
open Tea.Cmd
```

**After (Official)**:
```rescript
open Tea_App
open Tea_Html
// Cmd is accessed via Tea_Cmd module
```

### 2. Commands

**Official rescript-tea** provides `Tea_Cmd` with:
- `Tea_Cmd.none` - No command
- `Tea_Cmd.batch(list)` - Multiple commands
- `Tea_Cmd.call(callback)` - Custom command

### 3. Subscriptions

**Official rescript-tea** provides `Tea_Sub` with:
- `Tea_Sub.none` - No subscription
- `Tea_Sub.batch(list)` - Multiple subscriptions

**Available subscriptions:**
- `Tea_Time.every(interval, msg)` - Timer
- `Tea_Mouse.clicks(msg)` - Mouse clicks
- `Tea_Mouse.moves(msg)` - Mouse moves
- `Tea_Animationframe.onAnimationFrame(msg)` - Animation frames
- `Tea_Navigation.onChange(url => msg)` - URL changes

### 4. Keyboard Events

**rescript-tea doesn't have built-in keyboard subscriptions!**

We need to create custom subscriptions for keyboard events:

```rescript
// src/subscriptions/Keyboard.res
module Keyboard = {
  type keyEvent = {
    key: string,
    ctrlKey: bool,
    shiftKey: bool,
    altKey: bool,
  }

  @val external addEventListener: (string, Js.t<'a> => unit) => unit = "window.addEventListener"
  @val external removeEventListener: (string, Js.t<'a> => unit) => unit = "window.removeEventListener"

  let onKeyDown = (tagger: keyEvent => 'msg): Tea_Sub.t<'msg> => {
    Tea_Sub.registration(
      "keyboard-keydown",
      enabler => {
        let handler = evt => {
          let key = evt["key"]
          let ctrlKey = evt["ctrlKey"]
          let shiftKey = evt["shiftKey"]
          let altKey = evt["altKey"]
          enabler(tagger({key, ctrlKey, shiftKey, altKey}))
        }
        addEventListener("keydown", handler)
        () => removeEventListener("keydown", handler)
      }
    )
  }
}
```

### 5. Tauri Commands

We need custom commands for Tauri:

```rescript
// src/commands/TauriCmd.res
module TauriCmd = {
  @module("@tauri-apps/api/core") external invoke: (string, 'a) => promise<'b> = "invoke"

  let validateInference = (token: string, constraints: array<string>, tagger: result<bool, string> => 'msg): Tea_Cmd.t<'msg> => {
    Tea_Cmd.call(callbacks => {
      invoke("validate_inference", {"token": token, "constraints": constraints})
      ->Promise.then(result => {
        callbacks.enqueue(tagger(Ok(result)))
        Promise.resolve()
      })
      ->Promise.catch(err => {
        callbacks.enqueue(tagger(Error("Validation failed")))
        Promise.resolve()
      })
      ->ignore
    })
  }

  let getVexationIndex = (tagger: float => 'msg): Tea_Cmd.t<'msg> => {
    Tea_Cmd.call(callbacks => {
      invoke("get_vexation_index", ())
      ->Promise.then(result => {
        callbacks.enqueue(tagger(result))
        Promise.resolve()
      })
      ->ignore
    })
  }
}
```

### 6. Navigation/Routing

For a Tauri desktop app, we might not need traditional URL-based routing. Instead:

**Option A: View-based routing** (simpler, recommended for PanLL)
```rescript
type route =
  | ThreePaneView
  | SettingsView
  | FeedbackView

type model = {
  currentRoute: route,
  // ... other fields
}
```

**Option B: Use Tea_Navigation** (if you want URL-like routes)
```rescript
// Use Tea_Navigation for hash-based routing
let subscriptions = (model: model): Tea_Sub.t<msg> => {
  Tea_Navigation.onChange(url => UrlChanged(url))
}
```

## Migration Steps

### Step 1: Update App.res

**Before**:
```rescript
open Tea.App

let main = standardProgram({
  init: () => (Model.init(), Tea.Cmd.none),
  update: Update.update,
  view: View.view,
  subscriptions: _ => Tea.Sub.none,
})
```

**After**:
```rescript
// Use official rescript-tea
let main = Tea_App.standardProgram(
  ~init=() => (Model.init(), Tea_Cmd.none),
  ~update=Update.update,
  ~view=View.view,
  ~subscriptions=Subscriptions.subscriptions,
  ()
)
```

### Step 2: Create Subscriptions.res

```rescript
// src/Subscriptions.res
open Model
open Msg

let subscriptions = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    // Keyboard shortcuts
    Keyboard.onKeyDown(evt => {
      if evt.ctrlKey && evt.shiftKey {
        switch evt.key {
        | "L" => View(TogglePaneL)
        | "N" => View(TogglePaneN)
        | "B" => View(TogglePaneW)
        | _ => NoOp
        }
      } else {
        NoOp
      }
    }),

    // Update vexation index every second
    Tea_Time.every(1000.0, _ => Vexometer(UpdateVexationIndex(0.0))),

    // Animation frame for smooth UI
    Tea_Animationframe.onAnimationFrame(_ => NoOp),
  })
}
```

### Step 3: Update Update.res to use Commands

```rescript
let update = (model: model, msg: msg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | AntiCrash(ValidateToken(token)) => {
      let newModel = model
      let cmd = TauriCmd.validateInference(
        token.content,
        model.paneL.constraints->Array.map(c => c.expression),
        result => {
          switch result {
          | Ok(valid) => AntiCrash(ValidationPassed(token))
          | Error(reason) => AntiCrash(ValidationFailed(token, reason))
          }
        }
      )
      (newModel, cmd)
    }

  | Vexometer(UpdateVexationIndex(_)) => {
      let cmd = TauriCmd.getVexationIndex(index =>
        Vexometer(UpdateVexationIndex(index))
      )
      (model, cmd)
    }

  | _ => {
      // ... other message handlers
      (model, Tea_Cmd.none)
    }
  }
}
```

### Step 4: Update View imports

```rescript
// src/View.res
open Tea_Html  // Changed from Tea.Html
open Model
open Msg

let view = (model: model): Vdom.t<msg> => {
  // ... view code
}
```

### Step 5: Test the migration

```bash
# Clean build
npm run res:clean

# Build
npm run res:build

# Run Tauri dev
deno task dev
```

### Step 6: Remove custom TEA (after successful migration)

```bash
# Once everything works with official rescript-tea:
rm -rf src/tea/
git add -A
git commit -m "refactor: migrate from custom TEA to rescript-tea@0.16.0"
```

## Testing Checklist

- [ ] App loads without errors
- [ ] Three panes render correctly
- [ ] Keyboard shortcuts work (Ctrl+Shift+L/N/B)
- [ ] Vexation index updates
- [ ] Tauri commands can be invoked
- [ ] State updates correctly
- [ ] No console errors

## Benefits of Official rescript-tea

1. **Battle-tested**: Used in production by Darklang and others
2. **More features**: Navigation, HTTP, Time, Mouse, AnimationFrame
3. **Community support**: Issues, PRs, updates
4. **Less maintenance**: We don't have to maintain TEA runtime
5. **Better performance**: Optimized virtual DOM
6. **Documentation**: Follows Elm's well-documented architecture

## Rollback Plan

If migration fails, we can rollback by:
```bash
git revert <migration-commit>
npm install  # Restore dependencies
npm run res:build
```

The custom TEA implementation remains in `src/tea/` until migration is confirmed successful.

## Next Steps After Migration

1. ✅ Basic TEA cycle working
2. ✅ Keyboard shortcuts functional
3. ✅ Tauri integration working
4. Add HTTP requests for future features
5. Add proper error handling
6. Add debugging with Tea_Debug
7. Consider adding Tea_Navigation for view routing

---

**Migration Started**: 2026-02-04
**Target Completion**: 2026-02-11 (1 week)
**Assigned**: Claude + User
