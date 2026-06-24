// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL LLM Coding command wrappers — invoke bridge for spawning
/// and managing LLM coding sessions.
///
/// All commands invoke backend commands registered in
/// src-gossamer/src/llm_coding/commands.rs.

let invoke = RuntimeBridge.invoke

// ============================================================================
// Session Management
// ============================================================================

/// Fetch all sessions with updated resource stats.
let listSessions = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("llm_coding_list_sessions", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list sessions")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Spawn a new Claude coding session.
let spawnSession = (
  name: string,
  workDir: string,
  taskList: string,
  allowedRepos: array<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "llm_coding_spawn",
      {
        "name": name,
        "work_dir": workDir,
        "task_list": taskList,
        "allowed_repos": allowedRepos,
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to spawn session")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Freeze (SIGSTOP) a session.
let freezeSession = (sessionId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("llm_coding_freeze", {"session_id": sessionId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to freeze session")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Thaw (SIGCONT) a session.
let thawSession = (sessionId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("llm_coding_thaw", {"session_id": sessionId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to thaw session")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Kill (terminate) a session.
let killSession = (sessionId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("llm_coding_kill", {"session_id": sessionId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to kill session")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Resource & Lock Queries
// ============================================================================

/// Fetch system resource snapshot.
let systemResources = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("llm_coding_system_resources", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch system resources")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch workspace locks.
let listLocks = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("llm_coding_list_locks", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list locks")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch cross-session messages.
let listMessages = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("llm_coding_list_messages", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list messages")))
      Promise.resolve()
    })
    ->ignore
  })
}
