# The Elm Architecture (TEA) Guide for PanLL

**Version:** 1.0.0
**Status:** Production Ready
**License:** PMPL-1.0-or-later
**Author:** Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

## Table of Contents

- [Introduction](#introduction)
- [Core Concepts](#core-concepts)
- [Module Reference](#module-reference)
- [Architecture Guide](#architecture-guide)
- [Testing](#testing)
- [Best Practices](#best-practices)
- [Examples](#examples)

---

## Introduction

The Elm Architecture (TEA) is a pattern for building web applications that provides:

- **Predictable state management**: All state changes flow through a single update function
- **Side-effect isolation**: Commands and subscriptions handle async operations
- **Type safety**: ReScript's type system ensures correctness
- **Testability**: Pure functions make testing straightforward

### Why TEA for PanLL?

PanLL (eNSAID - Environment for NeSy-Agentic Integrated Development) requires:
- Complex state management for multi-panel neurosymbolic reasoning
- Real-time updates from agents
- Predictable behavior for debugging reasoning chains
- Type-safe guarantees for critical operations

TEA provides all of these guarantees.

---

## Core Concepts

### The TEA Cycle

```
User Input → Message → Update (Model + Command) → View → DOM
                ↑
                └──────── Subscriptions ────────────────────┘
```

### Four Core Components

1. **Model**: Application state (immutable data structure)
2. **Update**: State transition function `(Model, Msg) → (Model, Cmd)`
3. **View**: Rendering function `Model → VirtualDOM`
4. **Subscriptions**: External event sources `Model → Sub`

---

## Module Reference

### Tea_Cmd - Commands

Commands represent side effects to be executed after an update.

#### API

```rescript
// SPDX-License-Identifier: PMPL-1.0-or-later

type t<'msg>  // Opaque command type

// Constructors
let none: t<'msg>
let msg: 'msg => t<'msg>
let batch: list<t<'msg>> => t<'msg>
let call: (callbacks<'msg> => unit) => t<'msg>

// Execution
let execute: (t<'msg>, 'msg => unit) => unit

// Mapping
let map: (t<'msg>, 'msg => 'mappedMsg) => t<'mappedMsg>
```

#### Usage Examples

**No-op command:**
```rescript
let (newModel, cmd) = (model, Tea_Cmd.none)
```

**Immediate message:**
```rescript
let (model, Tea_Cmd.msg(LoadComplete))
```

**Async operation:**
```rescript
let fetchUserCmd = Tea_Cmd.call(callbacks => {
  Fetch.get("/api/user")
    ->Promise.then(response => {
      callbacks.enqueue(UserLoaded(response))
      Promise.resolve()
    })
    ->ignore
})
```

**Batch multiple commands:**
```rescript
let (model, Tea_Cmd.batch(list{
  Tea_Cmd.msg(LogEvent("Startup")),
  Tea_Cmd.call(loadUserData),
  Tea_Cmd.call(connectWebSocket)
}))
```

#### Testing

Commands are easily testable:

```javascript
// SPDX-License-Identifier: PMPL-1.0-or-later
import { msg, execute } from '../src/tea/Tea_Cmd.res.js';

it('executes Msg command', () => {
  const dispatch = vi.fn();
  const message = { type: 'TestMsg', value: 42 };

  execute(msg(message), dispatch);

  expect(dispatch).toHaveBeenCalledWith(message);
});
```

---

### Tea_Sub - Subscriptions

Subscriptions represent ongoing event sources (WebSocket, timers, keyboard).

#### API

```rescript
// SPDX-License-Identifier: PMPL-1.0-or-later

type t<'msg>  // Opaque subscription type

// Constructors
let none: t<'msg>
let registration: (string, ('msg => unit) => (unit => unit)) => t<'msg>
let batch: list<t<'msg>> => t<'msg>

// Lifecycle
let enable: (t<'msg>, 'msg => unit) => (unit => unit)
let getKeys: t<'msg> => array<string>

// Mapping
let map: (t<'msg>, 'msg => 'mappedMsg) => t<'mappedMsg>
```

#### Usage Examples

**No subscriptions:**
```rescript
let subscriptions = _model => Tea_Sub.none
```

**Timer subscription:**
```rescript
let subscriptions = model => {
  Tea_Sub.registration("timer", dispatch => {
    let intervalId = setInterval(() => {
      dispatch(Tick)
    }, 1000)

    // Cleanup function
    () => clearInterval(intervalId)
  })
}
```

**WebSocket subscription:**
```rescript
let subscriptions = model => {
  if model.connected {
    Tea_Sub.registration("websocket", dispatch => {
      let ws = WebSocket.create("wss://api.example.com")

      ws->WebSocket.onMessage(event => {
        dispatch(MessageReceived(event.data))
      })

      // Cleanup
      () => ws->WebSocket.close()
    })
  } else {
    Tea_Sub.none
  }
}
```

**Batch subscriptions:**
```rescript
let subscriptions = model => {
  Tea_Sub.batch(list{
    keyboardSub(model),
    timerSub(model),
    websocketSub(model)
  })
}
```

#### Memory Safety

Subscriptions **must** return cleanup functions to prevent memory leaks:

```rescript
// ✓ CORRECT - cleanup function returned
Tea_Sub.registration("timer", dispatch => {
  let id = setInterval(() => dispatch(Tick), 1000)
  () => clearInterval(id)  // Cleanup
})

// ✗ WRONG - no cleanup, memory leak!
Tea_Sub.registration("timer", dispatch => {
  setInterval(() => dispatch(Tick), 1000)
  () => ()  // No cleanup!
})
```

#### Testing

```javascript
// SPDX-License-Identifier: PMPL-1.0-or-later
it('prevents memory leaks with timers', () => {
  return new Promise((resolve) => {
    const dispatch = vi.fn();
    let timerFired = false;

    const timerSub = registration('timer', (dispatchFn) => {
      const timerId = setTimeout(() => {
        timerFired = true;
        dispatchFn({ type: 'TimerFired' });
      }, 50);
      return () => clearTimeout(timerId);  // Cleanup
    });

    const cleanup = enable(timerSub, dispatch);
    cleanup();  // Clean up before timer fires

    setTimeout(() => {
      expect(timerFired).toBe(false);  // Timer was cancelled
      expect(dispatch).not.toHaveBeenCalled();
      resolve();
    }, 100);
  });
});
```

---

### Tea_Vdom - Virtual DOM

Virtual DOM types and constructors for building UIs.

#### API

```rescript
// SPDX-License-Identifier: PMPL-1.0-or-later

type node<'msg>
type property<'msg>

// Node constructors
let text: string => node<'msg>
let node: (string, list<property<'msg>>, list<node<'msg>>) => node<'msg>

// Properties
let class_: string => property<'msg>
let id: string => property<'msg>
let style: (string, string) => property<'msg>
let href: string => property<'msg>
let src: string => property<'msg>
let placeholder: string => property<'msg>
let value: string => property<'msg>

// Events
let onClick: ('msg) => property<'msg>
let onInput: (string => 'msg) => property<'msg>
let onSubmit: ('msg) => property<'msg>
let onMouseEnter: ('msg) => property<'msg>
let onMouseLeave: ('msg) => property<'msg>

// Mapping
let map: (node<'msg>, 'msg => 'mappedMsg) => node<'mappedMsg>
```

#### Usage Examples

**Simple text:**
```rescript
Tea_Vdom.text("Hello, World!")
```

**Element with attributes:**
```rescript
Tea_Vdom.node("div", list{
  Tea_Vdom.class_("container"),
  Tea_Vdom.id("app")
}, list{
  Tea_Vdom.text("Content")
})
```

**Interactive button:**
```rescript
Tea_Vdom.node("button", list{
  Tea_Vdom.onClick(Increment),
  Tea_Vdom.class_("btn btn-primary")
}, list{
  Tea_Vdom.text("Click me")
})
```

**Form with input:**
```rescript
Tea_Vdom.node("input", list{
  Tea_Vdom.placeholder("Enter your name"),
  Tea_Vdom.value(model.name),
  Tea_Vdom.onInput(name => UpdateName(name))
}, list{})
```

---

### Tea_App - Application Runtime

Main entry point for running TEA applications.

#### API

```rescript
// SPDX-License-Identifier: PMPL-1.0-or-later

type program<'flags, 'model, 'msg>

// Program constructors
let simpleProgram: {
  init: 'flags => ('model, Tea_Cmd.t<'msg>),
  update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
  view: 'model => Tea_Vdom.node<'msg>,
  subscriptions: 'model => Tea_Sub.t<'msg>
} => program<'flags, 'model, 'msg>

let standardProgram: {
  init: 'flags => ('model, Tea_Cmd.t<'msg>),
  update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
  view: 'model => Tea_Vdom.node<'msg>,
  subscriptions: 'model => Tea_Sub.t<'msg>,
  shutdown: 'model => Tea_Cmd.t<'msg>
} => program<'flags, 'model, 'msg>
```

---

## Architecture Guide

### Complete Application Structure

```rescript
// SPDX-License-Identifier: PMPL-1.0-or-later

// Model.res
type model = {
  count: int,
  status: [#Idle | #Loading | #Error(string)]
}

let init = (): (model, Tea_Cmd.t<msg>) => (
  {count: 0, status: #Idle},
  Tea_Cmd.none
)

// Update.res
type msg =
  | Increment
  | Decrement
  | Reset
  | LoadData
  | DataLoaded(result<string, string>)

let update = (model: model, msg: msg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | Increment => ({...model, count: model.count + 1}, Tea_Cmd.none)
  | Decrement => ({...model, count: model.count - 1}, Tea_Cmd.none)
  | Reset => ({...model, count: 0}, Tea_Cmd.none)
  | LoadData => (
      {...model, status: #Loading},
      Tea_Cmd.call(callbacks => {
        fetchData()->Promise.then(result => {
          callbacks.enqueue(DataLoaded(result))
          Promise.resolve()
        })->ignore
      })
    )
  | DataLoaded(Ok(data)) => ({...model, status: #Idle}, Tea_Cmd.none)
  | DataLoaded(Error(err)) => ({...model, status: #Error(err)}, Tea_Cmd.none)
  }
}

// View.res
let view = (model: model): Tea_Vdom.node<msg> => {
  Tea_Vdom.node("div", list{Tea_Vdom.class_("app")}, list{
    Tea_Vdom.node("h1", list{}, list{
      Tea_Vdom.text(`Count: ${Int.toString(model.count)}`)
    }),
    Tea_Vdom.node("button", list{Tea_Vdom.onClick(Increment)}, list{
      Tea_Vdom.text("+")
    }),
    Tea_Vdom.node("button", list{Tea_Vdom.onClick(Decrement)}, list{
      Tea_Vdom.text("-")
    }),
    Tea_Vdom.node("button", list{Tea_Vdom.onClick(Reset)}, list{
      Tea_Vdom.text("Reset")
    })
  })
}

// Subscriptions.res
let subscriptions = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.none
}

// App.res
let app = Tea_App.simpleProgram({
  init: init,
  update: update,
  view: view,
  subscriptions: subscriptions
})
```

---

## Testing

### Test Coverage

Current test coverage (as of v1.0.0):
- **Tea_Cmd**: 87% lines, 85.71% branches, 83.33% functions
- **Tea_Sub**: 91% lines, 92.85% branches, 100% functions
- **Overall**: 33 passing tests

### Running Tests

```bash
# Run all tests
npm test

# Watch mode
npm run test:watch

# With UI
npm run test:ui

# With coverage
npm run test:coverage
```

### Test Structure

Tests use vitest + happy-dom:

```javascript
// SPDX-License-Identifier: PMPL-1.0-or-later
import { describe, it, expect } from 'vitest';
import { update } from '../src/Update.res.js';

describe('Update function', () => {
  it('increments counter', () => {
    const model = { count: 0, status: 'Idle' };
    const [newModel, cmd] = update(model, { type: 'Increment' });

    expect(newModel.count).toBe(1);
    expect(cmd).toBe("None");  // No command
  });
});
```

---

## Best Practices

### 1. Keep Model Simple

```rescript
// ✓ GOOD - Flat, simple structure
type model = {
  users: array<user>,
  selectedUserId: option<string>,
  loading: bool
}

// ✗ BAD - Nested, complex structure
type model = {
  data: {
    users: {
      list: array<user>,
      selected: option<{id: string, data: user}>
    }
  }
}
```

### 2. Use Variants for Messages

```rescript
// ✓ GOOD - Explicit variants
type msg =
  | UserClicked(string)
  | DataLoaded(result<data, error>)
  | FormUpdated(formField, string)

// ✗ BAD - Stringly-typed
type msg = {
  type_: string,
  payload: option<Js.Json.t>
}
```

### 3. Extract Complex Commands

```rescript
// ✓ GOOD - Named, reusable command
let loadUserCmd = (userId: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    fetchUser(userId)
      ->Promise.then(user => {
        callbacks.enqueue(UserLoaded(Ok(user)))
        Promise.resolve()
      })
      ->Promise.catch(err => {
        callbacks.enqueue(UserLoaded(Error(err)))
        Promise.resolve()
      })
      ->ignore
  })
}

// In update:
| LoadUser(id) => (model, loadUserCmd(id))
```

### 4. Always Clean Up Subscriptions

```rescript
// ✓ GOOD - Proper cleanup
Tea_Sub.registration("websocket", dispatch => {
  let ws = connect()
  ws.onMessage(msg => dispatch(Received(msg)))

  () => {  // Cleanup function
    ws.close()
    ws.onMessage(_ => ())  // Clear handler
  }
})
```

### 5. Test Update Function Thoroughly

Update is pure - easy to test:

```javascript
it('handles error state', () => {
  const model = { status: 'Loading' };
  const msg = { type: 'Error', error: 'Network failed' };

  const [newModel, cmd] = update(model, msg);

  expect(newModel.status).toBe('Error');
  expect(newModel.error).toBe('Network failed');
});
```

---

## Examples

### Example 1: Counter

See [Architecture Guide](#architecture-guide) above.

### Example 2: Form with Validation

```rescript
// SPDX-License-Identifier: PMPL-1.0-or-later

type model = {
  email: string,
  password: string,
  errors: list<string>
}

type msg =
  | UpdateEmail(string)
  | UpdatePassword(string)
  | Submit
  | SubmitResult(result<unit, string>)

let validateEmail = (email: string): option<string> => {
  if String.includes(email, "@") {
    None
  } else {
    Some("Invalid email")
  }
}

let update = (model, msg) => {
  switch msg {
  | UpdateEmail(email) => ({...model, email: email}, Tea_Cmd.none)
  | UpdatePassword(pwd) => ({...model, password: pwd}, Tea_Cmd.none)
  | Submit => {
      let errors = list{}
      switch validateEmail(model.email) {
      | Some(err) => errors = list{err, ...errors}
      | None => ()
      }

      if List.length(errors) > 0 {
        ({...model, errors: errors}, Tea_Cmd.none)
      } else {
        (model, submitFormCmd(model.email, model.password))
      }
    }
  | SubmitResult(Ok()) => (model, Tea_Cmd.msg(NavigateToHome))
  | SubmitResult(Error(err)) => ({...model, errors: list{err}}, Tea_Cmd.none)
  }
}
```

### Example 3: Real-Time Updates

```rescript
// SPDX-License-Identifier: PMPL-1.0-or-later

type model = {
  messages: array<string>,
  connected: bool
}

type msg =
  | Connect
  | Disconnect
  | MessageReceived(string)
  | SendMessage(string)

let subscriptions = (model) => {
  if model.connected {
    Tea_Sub.registration("websocket", dispatch => {
      let ws = WebSocket.create("wss://chat.example.com")

      ws->onOpen(() => Console.log("Connected"))
      ws->onMessage(event => dispatch(MessageReceived(event.data)))
      ws->onClose(() => dispatch(Disconnect))

      // Cleanup
      () => ws->close()
    })
  } else {
    Tea_Sub.none
  }
}
```

---

## References

- **Original Elm Architecture**: https://guide.elm-lang.org/architecture/
- **ReScript Documentation**: https://rescript-lang.org/
- **PanLL Project**: https://github.com/hyperpolymath/panll

---

## License

This documentation is licensed under PMPL-1.0-or-later.

Copyright (c) 2025 Jonathan D.A. Jewell
