// SPDX-License-Identifier: MPL-2.0

/// Mock ECHIDNA REST Server for PanLL development.
///
/// A standalone Deno HTTP server on port 9000 that implements the ECHIDNA REST
/// API subset consumed by PanLL's Tauri commands. Stateful — maintains proof
/// sessions in memory so the interactive proof panel works end-to-end.
///
/// Run: deno task mock:echidna
/// Or:  deno run --allow-net=127.0.0.1:9000 scripts/mock-echidna.ts

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ProofSession {
  id: string;
  prover: string;
  goal: string;
  status: string;
  goals: string[];
  proof_script: string[];
  complete: boolean;
  tactics_applied: string[];
  time_elapsed: number;
  error_message: string | null;
  created_at: number;
}

interface TacticScenario {
  initial_goals: string[];
  tactics: Record<string, { removes_goal: number; description: string }>;
  suggestions: Array<{
    name: string;
    args: string[];
    confidence: number;
    aspect_tags: string[];
    description: string;
  }>;
}

// ---------------------------------------------------------------------------
// Demo data — prover catalog
// ---------------------------------------------------------------------------

const PROVERS = [
  { name: "coq", tier: "ITP", complexity: "high" },
  { name: "lean4", tier: "ITP", complexity: "high" },
  { name: "z3", tier: "SMT", complexity: "medium" },
  { name: "isabelle", tier: "ITP", complexity: "high" },
  { name: "agda", tier: "ITP", complexity: "high" },
];

// ---------------------------------------------------------------------------
// Demo data — built-in proof scenarios keyed by goal substring match
// ---------------------------------------------------------------------------

const SCENARIOS: Array<{ match: string; scenario: TacticScenario }> = [
  {
    match: "n + 0 = n",
    scenario: {
      initial_goals: ["Base case: 0 + 0 = 0", "Inductive step: S n + 0 = S n"],
      tactics: {
        "induction n": { removes_goal: -1, description: "Split into base and inductive cases" },
        "reflexivity": { removes_goal: 0, description: "Solve by definitional equality" },
        "simpl; reflexivity": { removes_goal: 0, description: "Simplify then solve by reflexivity" },
        "simpl": { removes_goal: -1, description: "Simplify the current goal" },
      },
      suggestions: [
        { name: "induction", args: ["n"], confidence: 0.94, aspect_tags: ["structural", "induction"], description: "Structural induction on the natural number n" },
        { name: "reflexivity", args: [], confidence: 0.82, aspect_tags: ["equality", "terminal"], description: "Solve goal by definitional equality" },
        { name: "simpl", args: [], confidence: 0.75, aspect_tags: ["simplification"], description: "Simplify the current goal expression" },
        { name: "auto", args: [], confidence: 0.60, aspect_tags: ["automation"], description: "Attempt automatic proof search" },
      ],
    },
  },
  {
    match: "reverse.reverse",
    scenario: {
      initial_goals: ["nil case: [].reverse.reverse = []", "cons case: (a :: l).reverse.reverse = a :: l"],
      tactics: {
        "simp": { removes_goal: 0, description: "Simplification by simp lemmas" },
        "induction l": { removes_goal: -1, description: "Structural induction on list l" },
        "rfl": { removes_goal: 0, description: "Reflexivity" },
      },
      suggestions: [
        { name: "simp", args: ["[List.reverse_reverse]"], confidence: 0.91, aspect_tags: ["simplification", "lemma"], description: "Apply reverse_reverse simp lemma" },
        { name: "induction", args: ["l"], confidence: 0.85, aspect_tags: ["structural", "induction"], description: "Induction on the list" },
        { name: "rfl", args: [], confidence: 0.70, aspect_tags: ["equality", "terminal"], description: "Reflexivity" },
      ],
    },
  },
  {
    match: "assert",
    scenario: {
      initial_goals: ["SMT obligation: satisfiability check"],
      tactics: {
        "check-sat": { removes_goal: 0, description: "Run SMT satisfiability check" },
        "solve": { removes_goal: 0, description: "Invoke Z3 solver" },
      },
      suggestions: [
        { name: "check-sat", args: [], confidence: 0.98, aspect_tags: ["smt", "terminal"], description: "Run the SMT satisfiability decision procedure" },
        { name: "simplify", args: [], confidence: 0.65, aspect_tags: ["smt", "preprocessing"], description: "Simplify constraints before solving" },
      ],
    },
  },
];

/// Fallback scenario for goals that don't match any built-in pattern.
const DEFAULT_SCENARIO: TacticScenario = {
  initial_goals: ["Goal 1: primary obligation", "Goal 2: secondary obligation"],
  tactics: {
    "auto": { removes_goal: 0, description: "Automatic proof search" },
    "intro": { removes_goal: -1, description: "Introduce hypotheses" },
    "apply": { removes_goal: 0, description: "Apply a matching lemma" },
    "trivial": { removes_goal: 0, description: "Solve trivial goals" },
  },
  suggestions: [
    { name: "auto", args: [], confidence: 0.70, aspect_tags: ["automation"], description: "Attempt automatic proof search" },
    { name: "intro", args: [], confidence: 0.65, aspect_tags: ["intro"], description: "Introduce hypotheses into the context" },
    { name: "apply", args: ["hypothesis"], confidence: 0.55, aspect_tags: ["application"], description: "Apply a matching hypothesis or lemma" },
  ],
};

// ---------------------------------------------------------------------------
// Demo data — theorem search corpus
// ---------------------------------------------------------------------------

const THEOREM_CORPUS = [
  { name: "Nat.add_zero_r", statement: "forall n : nat, n + 0 = n", prover: "coq", tags: ["arithmetic", "identity"] },
  { name: "Nat.add_comm", statement: "forall n m : nat, n + m = m + n", prover: "coq", tags: ["arithmetic", "commutativity"] },
  { name: "Nat.add_assoc", statement: "forall n m p : nat, n + (m + p) = (n + m) + p", prover: "coq", tags: ["arithmetic", "associativity"] },
  { name: "List.reverse_involutive", statement: "forall (A : Type) (l : list A), rev (rev l) = l", prover: "coq", tags: ["list", "involution"] },
  { name: "List.app_nil_r", statement: "forall (A : Type) (l : list A), l ++ [] = l", prover: "coq", tags: ["list", "identity"] },
  { name: "Bool.negb_involutive", statement: "forall b : bool, negb (negb b) = b", prover: "coq", tags: ["boolean", "involution"] },
  { name: "Nat.le_refl", statement: "forall n : nat, n <= n", prover: "coq", tags: ["order", "reflexivity"] },
  { name: "Nat.mul_comm", statement: "forall n m : nat, n * m = m * n", prover: "coq", tags: ["arithmetic", "commutativity"] },
];

// ---------------------------------------------------------------------------
// Session store
// ---------------------------------------------------------------------------

const sessions = new Map<string, ProofSession>();

/// Generate a UUID-like session identifier.
function generateSessionId(): string {
  const hex = () => Math.random().toString(16).slice(2, 6);
  return `sess-${hex()}-${hex()}-${hex()}`;
}

/// Find the matching proof scenario for a goal string.
function findScenario(goal: string): TacticScenario {
  for (const entry of SCENARIOS) {
    if (goal.includes(entry.match)) {
      return entry.scenario;
    }
  }
  return DEFAULT_SCENARIO;
}

/// Simulate network latency (200-500ms).
function randomDelay(): Promise<void> {
  const ms = 200 + Math.floor(Math.random() * 300);
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// Route handlers
// ---------------------------------------------------------------------------

/// GET /api/v1/health — server health check.
/// Returns a plain string (the parser expects raw text, not structured JSON).
function handleHealth(): Response {
  return new Response("ECHIDNA 1.5.0-mock (PanLL development server)", {
    headers: { "Content-Type": "text/plain" },
  });
}

/// GET /api/v1/provers — list available prover backends.
function handleListProvers(): Response {
  return Response.json(PROVERS);
}

/// POST /api/v1/prove — dispatch a proof obligation to the solver portfolio.
async function handleProve(req: Request): Promise<Response> {
  await randomDelay();
  const body = await req.json();
  const goal = body.content ?? body.goal ?? "";
  const prover = body.prover ?? "z3";

  const hasAxiomRisk = goal.includes("believe_me") || goal.includes("Admitted") || goal.includes("sorry");
  const trustLevel = hasAxiomRisk ? 1 : 4;
  const dangerLevel = hasAxiomRisk ? "reject" : "safe";

  return Response.json({
    verified: !hasAxiomRisk,
    trust_level: trustLevel,
    provers_used: [prover, "z3"],
    proof_time_ms: 150 + Math.random() * 500,
    goals_remaining: 0,
    axiom_report: hasAxiomRisk
      ? [{ axiom_name: "believe_me", danger_level: "reject", description: "Admitted proof — unsafe assumption" }]
      : [{ axiom_name: "standard_library", danger_level: "safe", description: "Standard library axioms only" }],
    certificate_hash: hasAxiomRisk ? null : `sha256:${Math.random().toString(16).slice(2, 18)}`,
    message: hasAxiomRisk ? "Proof rejected — dangerous axiom detected" : "Proof verified successfully",
    cross_checked: hasAxiomRisk ? "single_solver" : "cross_checked",
  });
}

/// POST /api/v1/verify — verify an existing proof (same shape as prove).
async function handleVerify(req: Request): Promise<Response> {
  return handleProve(req);
}

/// GET /api/v1/search?q=... — search the theorem corpus.
function handleSearch(url: URL): Response {
  const query = (url.searchParams.get("q") ?? "").toLowerCase();
  if (!query) {
    return Response.json([]);
  }
  const matches = THEOREM_CORPUS.filter(
    (t) =>
      t.name.toLowerCase().includes(query) ||
      t.statement.toLowerCase().includes(query) ||
      t.tags.some((tag) => tag.includes(query)),
  ).slice(0, 5);
  return Response.json(matches);
}

/// POST /api/v1/proofs — create a new interactive proof session.
async function handleCreateSession(req: Request): Promise<Response> {
  await randomDelay();
  const body = await req.json();
  const goal = body.goal ?? "";
  const prover = body.prover ?? "coq";
  const scenario = findScenario(goal);
  const sessionId = generateSessionId();

  const session: ProofSession = {
    id: sessionId,
    prover,
    goal,
    status: "pending",
    goals: [...scenario.initial_goals],
    proof_script: [],
    complete: false,
    tactics_applied: [],
    time_elapsed: 0,
    error_message: null,
    created_at: Date.now(),
  };

  sessions.set(sessionId, session);
  return Response.json(session);
}

/// GET /api/v1/proofs/:id — get current session state.
function handleGetSession(sessionId: string): Response {
  const session = sessions.get(sessionId);
  if (!session) {
    return Response.json(
      { error: `Session ${sessionId} not found` },
      { status: 404 },
    );
  }
  return Response.json(session);
}

/// POST /api/v1/proofs/:id/tactics — apply a tactic to the session.
async function handleApplyTactic(
  sessionId: string,
  req: Request,
): Promise<Response> {
  await randomDelay();
  const session = sessions.get(sessionId);
  if (!session) {
    return Response.json(
      { success: false, proof_state: { id: "", prover: "", goal: "", status: "error", goals: [], proof_script: [], complete: false, tactics_applied: [], time_elapsed: 0, error_message: `Session ${sessionId} not found` } },
      { status: 404 },
    );
  }

  const body = await req.json();
  const tacticName = body.name ?? body.tactic ?? "auto";
  const tacticArgs: string[] = body.args ?? [];
  const fullTactic = tacticArgs.length > 0 ? `${tacticName} ${tacticArgs.join(" ")}` : tacticName;

  // Look up the scenario for this session's goal
  const scenario = findScenario(session.goal);
  const tacticEntry = scenario.tactics[fullTactic] ?? scenario.tactics[tacticName];

  session.tactics_applied.push(fullTactic);
  session.proof_script.push(fullTactic + ".");
  session.status = "in_progress";
  session.time_elapsed = (Date.now() - session.created_at) / 1000;

  if (tacticEntry && tacticEntry.removes_goal >= 0 && session.goals.length > 0) {
    // Remove the specified goal (clamped to valid index)
    const idx = Math.min(tacticEntry.removes_goal, session.goals.length - 1);
    session.goals.splice(idx, 1);
  }

  // Check completion
  if (session.goals.length === 0) {
    session.status = "success";
    session.complete = true;
  }

  return Response.json({
    success: true,
    proof_state: { ...session },
  });
}

/// GET /api/v1/proofs/:id/tactics/suggest?limit=N — tactic suggestions.
function handleSuggestTactics(sessionId: string, url: URL): Response {
  const session = sessions.get(sessionId);
  if (!session) {
    return Response.json([], { status: 404 });
  }

  const limit = parseInt(url.searchParams.get("limit") ?? "5", 10);
  const scenario = findScenario(session.goal);

  // Filter out tactics already applied, then take up to limit
  const available = scenario.suggestions.filter(
    (s) => !session.tactics_applied.includes(s.name) &&
           !session.tactics_applied.includes(`${s.name} ${s.args.join(" ")}`.trim()),
  );

  return Response.json(available.slice(0, limit));
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

/// Route an incoming request to the appropriate handler.
/// All paths are under /api/v1/.
async function handleRequest(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const path = url.pathname;
  const method = req.method;

  // CORS headers for Tauri webview requests
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };

  // Handle CORS preflight
  if (method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  let response: Response;

  try {
    // Health
    if (path === "/api/v1/health" && method === "GET") {
      response = handleHealth();

    // Provers
    } else if (path === "/api/v1/provers" && method === "GET") {
      response = handleListProvers();

    // Prove
    } else if (path === "/api/v1/prove" && method === "POST") {
      response = await handleProve(req);

    // Verify
    } else if (path === "/api/v1/verify" && method === "POST") {
      response = await handleVerify(req);

    // Search
    } else if (path === "/api/v1/search" && method === "GET") {
      response = handleSearch(url);

    // Create session
    } else if (path === "/api/v1/proofs" && method === "POST") {
      response = await handleCreateSession(req);

    // Session and tactic routes: /api/v1/proofs/:id/...
    } else if (path.startsWith("/api/v1/proofs/")) {
      const rest = path.slice("/api/v1/proofs/".length);
      const segments = rest.split("/").filter(Boolean);
      const sessionId = segments[0];

      if (!sessionId) {
        response = Response.json({ error: "Missing session ID" }, { status: 400 });

      // GET /api/v1/proofs/:id
      } else if (segments.length === 1 && method === "GET") {
        response = handleGetSession(sessionId);

      // POST /api/v1/proofs/:id/tactics
      } else if (segments.length === 2 && segments[1] === "tactics" && method === "POST") {
        response = await handleApplyTactic(sessionId, req);

      // GET /api/v1/proofs/:id/tactics/suggest?limit=N
      } else if (segments.length === 3 && segments[1] === "tactics" && segments[2] === "suggest" && method === "GET") {
        response = handleSuggestTactics(sessionId, url);

      } else {
        response = Response.json({ error: "Not found" }, { status: 404 });
      }

    } else {
      response = Response.json({ error: `Unknown route: ${method} ${path}` }, { status: 404 });
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[ECHIDNA-MOCK] Error handling ${method} ${path}: ${message}`);
    response = Response.json({ error: message }, { status: 500 });
  }

  // Attach CORS headers to every response
  for (const [key, value] of Object.entries(corsHeaders)) {
    response.headers.set(key, value);
  }

  // Log the request
  const status = response.status;
  const sessionCount = sessions.size;
  console.log(`[ECHIDNA-MOCK] ${method} ${path} -> ${status}  (${sessionCount} active sessions)`);

  return response;
}

// ---------------------------------------------------------------------------
// Server entry point
// ---------------------------------------------------------------------------

const PORT = 9000;

console.log(`
  ╔══════════════════════════════════════════════════════╗
  ║  ECHIDNA Mock Server v1.5.0-mock                    ║
  ║  Listening on http://127.0.0.1:${PORT}/api/v1          ║
  ║                                                      ║
  ║  Endpoints:                                          ║
  ║    GET  /api/v1/health                               ║
  ║    GET  /api/v1/provers                              ║
  ║    POST /api/v1/prove                                ║
  ║    POST /api/v1/verify                               ║
  ║    GET  /api/v1/search?q=...                         ║
  ║    POST /api/v1/proofs                               ║
  ║    GET  /api/v1/proofs/:id                           ║
  ║    POST /api/v1/proofs/:id/tactics                   ║
  ║    GET  /api/v1/proofs/:id/tactics/suggest?limit=N   ║
  ║                                                      ║
  ║  Built-in scenarios:                                 ║
  ║    - Coq: "forall n : nat, n + 0 = n"               ║
  ║    - Lean: "...reverse.reverse = l"                  ║
  ║    - Z3:  "(assert ...)"                             ║
  ╚══════════════════════════════════════════════════════╝
`);

Deno.serve({ port: PORT, hostname: "127.0.0.1" }, handleRequest);
