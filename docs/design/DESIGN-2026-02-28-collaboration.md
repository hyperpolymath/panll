# DESIGN: PanLL Embedded Collaboration — Working Tools, Not a Meeting Platform

**Date:** 2026-02-28
**Repo:** panll
**Author:** Jonathan D.A. Jewell
**Status:** Design exploration (pre-implementation)

## Context

PanLL's proof, database, and protocol workflows are inherently collaborative. A
proof is often co-authored. A database schema is negotiated between teams. A protocol
spec needs consensus. But the collaboration tools people reach for (Teams, Zoom,
Slack) are disconnected from the work — you share a screen and talk *about* the
proof, but you can't both *work on* it simultaneously.

This document designs embedded collaboration for PanLL: voice, chat, shared cursors,
and co-editing that live inside the tool where the work happens.

## Design Questions (from session dialogue)

> "We also do need to have a feature a bit like VS Code's Live Share thing for teams
> wanting to collaborate together, as these are often collaborative projects. Can our
> Elixir foundation support this too?"

> "I think with voice and/or chat, maybe video but that might be too performance
> demanding, and other basic features that MS Teams offers — but clearly this is not
> MS Teams, just working tools for doing this kind of business."

---

## Core Principle: Work-First, Communication-Second

This is **not** a videoconferencing platform that happens to show code. It is a
**proof/database/protocol workbench** that happens to let you talk to colleagues
while using it. The difference matters:

| MS Teams / Zoom | PanLL Collaboration |
|----------------|---------------------|
| Screen sharing (passive viewing) | Shared state (active co-editing) |
| "Can you scroll up?" | Both users see the same proof pipeline |
| Chat is a separate window | Chat is contextual — attached to goals, entities, states |
| Video is the main event | Voice is ambient background; video is optional |
| General-purpose meetings | Purpose-built for formal methods / data / protocol work |
| Disconnected from the artifact | Embedded in the artifact |

---

## Feature Set

### Tier 1: Shared State (Core — built on Phoenix Channels)

The foundation. Multiple PanLL instances connect to the same session and see
synchronised state in real time.

**What's shared:**
- Proof session state (goals, tactics applied, proof script)
- Pane layout and scroll position
- Entity selections in VeriSimDB
- Protocol state machine edits
- Cursor positions (coloured per participant)
- Tactic suggestions (everyone sees the same ECHIDNA output)

**What's NOT shared (private to each participant):**
- Personal layout preferences
- Information Humidity setting (one person may want Low while another wants High)
- Local SLM explanations
- Undo history (each user has their own undo stack)

**Architecture:**
```
┌──────────┐     WebSocket      ┌───────────────────┐
│ PanLL A  │◀──────────────────▶│                   │
└──────────┘                    │  Elixir/Phoenix   │
                                │  Collaboration    │
┌──────────┐     WebSocket      │  Server           │
│ PanLL B  │◀──────────────────▶│                   │
└──────────┘                    │  • Session state  │
                                │  • Presence       │
┌──────────┐     WebSocket      │  • Conflict res.  │
│ PanLL C  │◀──────────────────▶│  • Chat history   │
└──────────┘                    │  • Voice relay     │
                                └────────┬──────────┘
                                         │
                                    ┌────▼────┐
                                    │ ECHIDNA │
                                    └─────────┘
```

The collaboration server mediates between PanLL instances and ECHIDNA. When
participant A applies a tactic, the server forwards it to ECHIDNA, receives the
updated proof state, and broadcasts to all participants. No one talks directly
to ECHIDNA — the server is the single source of truth.

**Conflict resolution:** If two people apply a tactic at the same instant, the server
applies them sequentially (first-received wins) and broadcasts the result. The second
user sees their tactic applied to the updated state, which may have different effects
than they expected. The UI shows a brief "Alice applied 'induction n' just before
you" notification.

### Tier 2: Text Chat (Contextual)

Chat messages can be:

1. **General:** Appears in a sidebar chat panel (like Slack/Teams DMs)
2. **Contextual:** Attached to a specific proof goal, database entity, or protocol
   state. Appears as a speech bubble annotation on the relevant element.

```
┌──────────────────────────────────────────────────┐
│  Goal: ∀ n, n + 0 = n                           │
│  Status: 2 subgoals remaining                   │
│                                            💬 2  │◀── "2 comments on this goal"
│  ┌──────────────────────────────────────┐        │
│  │ Alice: Should we try omega here?     │        │
│  │ Bob:   No, induction is cleaner for  │        │
│  │        the inductive step            │        │
│  └──────────────────────────────────────┘        │
└──────────────────────────────────────────────────┘
```

**Contextual chat** is the differentiator. In Teams you say "look at line 47" and
hope everyone scrolls there. In PanLL, the comment *lives on* the goal — it's
always visible when that goal is visible, across sessions.

**Implementation:** Phoenix PubSub with per-topic channels. Each proof goal, entity,
or protocol state has a topic. Chat messages are persisted (ETS for session lifetime,
optional DETS/Mnesia for longer-term persistence).

### Tier 3: Voice (Ambient, Low-Bandwidth)

Voice should feel like sitting next to a colleague — always-on, low-latency, no
ceremony. Not a "call" you schedule; just a channel you're in while working.

**Requirements:**
- **Opus codec** — excellent quality at 16-32 kbps (negligible bandwidth)
- **Push-to-talk AND open-mic** — user choice, sensible default is open-mic with
  voice activity detection (VAD)
- **Spatial audio (optional):** Participants positioned left/right based on their
  cursor location in the proof — if Alice is working on subgoal A (left side of
  pipeline) and Bob on subgoal B (right side), their voices come from those
  directions. Subtle but powerful for awareness.
- **No video by default** — audio is cheap and sufficient for co-working. Video is
  available but opt-in (see Tier 4).

**Implementation options:**

| Approach | Pros | Cons |
|----------|------|------|
| WebRTC peer-to-peer | No server relay, low latency | NAT traversal complexity, doesn't scale past ~6 peers |
| WebRTC via SFU (mediasoup/Janus) | Scales to many participants | Requires media server infrastructure |
| Elixir-native (Membrane Framework) | Pure Elixir, integrates with Phoenix | Less mature than WebRTC ecosystem |
| LiveKit (open source) | Production-grade, WebRTC-based SFU | External dependency but well-maintained |

**Recommendation:** WebRTC peer-to-peer for small teams (2-4 people, which is the
common case for proof co-authoring). If PanLL collaboration grows to larger groups,
add LiveKit as an optional SFU backend. The Elixir server handles signalling (ICE
candidates, SDP exchange) via Phoenix Channels — it doesn't relay media itself.

### Tier 4: Video (Optional, Opt-In)

Video is available but never mandatory. Useful for:
- Teaching sessions (instructor shows their face while walking through a proof)
- Remote pair programming on protocol specs
- Presentations (someone screen-shares their PanLL while others watch)

**Performance considerations:**
- Video encoding/decoding is GPU-accelerated on modern hardware (VA-API on Linux,
  VideoToolbox on macOS)
- 720p at 30fps is ~1.5 Mbps — manageable on any broadband connection
- PanLL should detect available bandwidth and auto-adjust quality
- Video should NEVER compete with the proof engine for CPU — if ECHIDNA is running
  a heavy proof, video quality degrades gracefully

**Tauri integration:** Tauri 2.0 can host a WebRTC peer connection via the webview.
The Rust backend handles no media — it all goes through the web layer.

### Tier 5: Awareness Features (Borrowed from Teams, Adapted for Work)

| Feature | Teams Equivalent | PanLL Adaptation |
|---------|-----------------|------------------|
| Presence | Green/yellow/red dot | "Alice: working on subgoal 2", "Bob: reviewing axiom report" |
| Reactions | Emoji reactions | "Alice agreed with this tactic" (👍 on a proof step) |
| Raise hand | Raise hand button | "Bob wants to discuss this goal before proceeding" (blocks tactic application until resolved) |
| Status | Custom status | "Focusing — please don't apply tactics to my subgoal" |
| Notifications | Toast notifications | "Proof complete! All goals discharged." broadcast to all participants |

**What PanLL does NOT need from Teams:**
- Calendar integration
- File sharing (the proof IS the shared artifact)
- Channels/teams hierarchy (a PanLL session is the unit of collaboration)
- Bots and app integrations
- Email integration
- Backgrounds and filters

---

## Session Model

A **collaborative session** is:

```
Session {
  id: UUID,
  name: "Proving nat_add_zero_r with Alice and Bob",
  layout: LogicAndProofs,            // Discipline preset
  participants: [Alice, Bob, Carol],
  echidna_session: "sess-abc-123",   // Linked ECHIDNA proof session
  chat_history: [...],
  created_at: timestamp,
  expires_at: timestamp | never,
}
```

**Joining a session:**
1. Host creates a session (generates a share link or room code)
2. Participants open PanLL and enter the room code
3. Phoenix Presence registers them; cursors appear; state syncs
4. Voice channel auto-joins (muted by default, unmute when ready)

**No accounts required** for joining — the collaboration server identifies
participants by a nickname + session token. For persistent teams, optional
authentication via existing identity providers.

---

## Elixir/Phoenix Fitness Assessment

Why Elixir is exceptionally well-suited for this:

| Requirement | Elixir/OTP Feature |
|-------------|-------------------|
| Real-time state sync | Phoenix Channels (WebSocket multiplexing) |
| Participant tracking | Phoenix Presence (CRDT-based, conflict-free) |
| Chat persistence | ETS (in-memory, session-scoped) / Mnesia (cross-node) |
| Voice signalling | Phoenix Channel for WebRTC ICE/SDP exchange |
| Fault tolerance | OTP Supervisors (session crashes don't affect other sessions) |
| Scalability | BEAM handles millions of lightweight processes |
| Hot code upgrades | OTP releases — upgrade server without dropping connections |
| Low latency | Sub-millisecond message routing within the BEAM |

The collaboration server is a natural Elixir application. Each session is a GenServer
process. Each participant's connection is a Channel. Presence tracks who's in each
session. The supervision tree ensures that if one session crashes, all others continue
unaffected.

**Estimated implementation:** A basic shared-state + chat collaboration server in
Phoenix is roughly 500-800 lines of Elixir. Voice signalling adds ~200 lines. This
is a weekend project for the core, not a multi-month effort.

---

## Privacy and Security

- **End-to-end encryption** for voice/video (WebRTC's SRTP provides this by default)
- **Chat messages** encrypted in transit (WSS) and optionally at rest
- **No telemetry** on collaboration content — PanLL never phones home with proof data
- **Self-hostable** — the collaboration server can run on the user's own infrastructure
- **Session expiry** — sessions auto-delete after configurable timeout (default: 24h
  of inactivity)
- **No recording** unless explicitly enabled by all participants

---

## Implementation Phases

### Phase A: Shared proof state (Phoenix Channels)
- [ ] Elixir/Phoenix collaboration server scaffold
- [ ] Session creation and joining (room codes)
- [ ] Real-time proof state synchronisation
- [ ] Cursor presence (coloured indicators)
- [ ] Conflict resolution for concurrent tactic applications

### Phase B: Contextual chat
- [ ] General chat sidebar
- [ ] Contextual comments attached to proof goals / entities / states
- [ ] Chat persistence (session-scoped)

### Phase C: Voice
- [ ] WebRTC signalling via Phoenix Channel
- [ ] Peer-to-peer audio (Opus codec)
- [ ] Push-to-talk and open-mic with VAD
- [ ] Mute/unmute UI in PanLL status bar

### Phase D: Video (optional)
- [ ] WebRTC video stream (720p default)
- [ ] Bandwidth-adaptive quality
- [ ] Picture-in-picture mode (small video overlay, doesn't obscure panes)

### Phase E: Awareness features
- [ ] Rich presence ("working on subgoal 2")
- [ ] Tactic reactions (👍 on proof steps)
- [ ] "Hold" flag (block tactic application pending discussion)

---

## Open Questions

1. **Should the collaboration server be a separate Elixir application or integrated
   into a broader PanLL backend?** Separate is cleaner for deployment but means
   another service to run.

2. **Should collaborative sessions be persisted beyond their lifetime?** "Replay a
   proof session" could be valuable for teaching — watch how Alice and Bob arrived
   at the proof step by step.

3. **What about async collaboration?** Not everyone is online at the same time.
   Should PanLL support "leave a comment on this goal, Alice will see it when she
   opens the session tomorrow"?

4. **Does the collaboration server need its own ECHIDNA connection, or does each
   PanLL client still talk to ECHIDNA directly?** Centralising through the server
   gives better conflict resolution but adds latency.

5. **Should voice/video be integrated via Tauri's webview WebRTC, or via a native
   Rust WebRTC library (webrtc-rs)?** Webview is simpler; native gives more control
   over codec selection and performance.

---

## References

- Discipline layouts: `DESIGN-2026-02-28-discipline-layouts.md`
- Proof UX: `DESIGN-2026-02-28-echidna-proof-ux.md`
- Phoenix Channels: https://hexdocs.pm/phoenix/channels.html
- Phoenix Presence: https://hexdocs.pm/phoenix/Phoenix.Presence.html
- Membrane Framework (Elixir media): https://membrane.stream
- LiveKit: https://livekit.io
