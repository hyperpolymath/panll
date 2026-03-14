// SPDX-License-Identifier: PMPL-1.0-or-later
// Generated from src/abi/cartridge-schema.json — DO NOT EDIT MANUALLY.
// Regenerate with: deno task gen:cartridge-abi
// Seam-validated against BoJ server ABI at compile time via ppx_typell.

/// Cartridge identifier — every BoJ cartridge has exactly one variant here.
/// Using this type instead of raw strings gives compile-time guarantees that
/// only valid cartridge names reach BojCmd.invokeCartridge.
type cartridgeId =
  | AgentMcp
  | BspMcp
  | CloudMcp
  | CommsMcp
  | ContainerMcp
  | DapMcp
  | DatabaseMcp
  | FeedbackMcp
  | FleetMcp
  | GitMcp
  | IacMcp
  | K8sMcp
  | LspMcp
  | MlMcp
  | NesyMcp
  | ObserveMcp
  | ProofMcp
  | QueuesMcp
  | ResearchMcp
  | SecretsMcp
  | SsgMcp
  | UmsMcp

/// Convert a cartridge variant to its wire-format string name.
/// This is the ONLY place where cartridge name strings should exist.
let cartridgeToString = (c: cartridgeId): string =>
  switch c {
  | AgentMcp => "agent-mcp"
  | BspMcp => "bsp-mcp"
  | CloudMcp => "cloud-mcp"
  | CommsMcp => "comms-mcp"
  | ContainerMcp => "container-mcp"
  | DapMcp => "dap-mcp"
  | DatabaseMcp => "database-mcp"
  | FeedbackMcp => "feedback-mcp"
  | FleetMcp => "fleet-mcp"
  | GitMcp => "git-mcp"
  | IacMcp => "iac-mcp"
  | K8sMcp => "k8s-mcp"
  | LspMcp => "lsp-mcp"
  | MlMcp => "ml-mcp"
  | NesyMcp => "nesy-mcp"
  | ObserveMcp => "observe-mcp"
  | ProofMcp => "proof-mcp"
  | QueuesMcp => "queues-mcp"
  | ResearchMcp => "research-mcp"
  | SecretsMcp => "secrets-mcp"
  | SsgMcp => "ssg-mcp"
  | UmsMcp => "ums-mcp"
  }

/// Parse a wire-format string back to a cartridge variant.
/// Returns None for unknown cartridge names.
let cartridgeFromString = (s: string): option<cartridgeId> =>
  switch s {
  | "agent-mcp" => Some(AgentMcp)
  | "bsp-mcp" => Some(BspMcp)
  | "cloud-mcp" => Some(CloudMcp)
  | "comms-mcp" => Some(CommsMcp)
  | "container-mcp" => Some(ContainerMcp)
  | "dap-mcp" => Some(DapMcp)
  | "database-mcp" => Some(DatabaseMcp)
  | "feedback-mcp" => Some(FeedbackMcp)
  | "fleet-mcp" => Some(FleetMcp)
  | "git-mcp" => Some(GitMcp)
  | "iac-mcp" => Some(IacMcp)
  | "k8s-mcp" => Some(K8sMcp)
  | "lsp-mcp" => Some(LspMcp)
  | "ml-mcp" => Some(MlMcp)
  | "nesy-mcp" => Some(NesyMcp)
  | "observe-mcp" => Some(ObserveMcp)
  | "proof-mcp" => Some(ProofMcp)
  | "queues-mcp" => Some(QueuesMcp)
  | "research-mcp" => Some(ResearchMcp)
  | "secrets-mcp" => Some(SecretsMcp)
  | "ssg-mcp" => Some(SsgMcp)
  | "ums-mcp" => Some(UmsMcp)
  | _ => None
  }

/// Security tier. Shield cartridges require elevated trust.
type tier = Teranga | Shield | Ayo

/// Get the tier for a cartridge.
let cartridgeTier = (c: cartridgeId): tier =>
  switch c {
  | ProofMcp | SecretsMcp | UmsMcp => Shield
  | _ => Teranga
  }

/// Tool identifiers per cartridge. Each module below contains only the tools
/// that the specific cartridge exposes — calling a tool on the wrong cartridge
/// is a compile-time error because the types don't unify.

/// Agent OODA loop tools.
type agentTool =
  | NewSession | EndSession | GetSession | Transition | Advance
  | Halt | Validate | Reset | ToolCallInfo | SafetyCheckInfo | CoordinationInfo

let agentToolToString = (t: agentTool): string =>
  switch t {
  | NewSession => "new_session"
  | EndSession => "end_session"
  | GetSession => "get_session"
  | Transition => "transition"
  | Advance => "advance"
  | Halt => "halt"
  | Validate => "validate"
  | Reset => "reset"
  | ToolCallInfo => "tool_call_info"
  | SafetyCheckInfo => "safety_check_info"
  | CoordinationInfo => "coordination_info"
  }

/// BSP build server tools.
type bspTool =
  | CreateSession | Initialize | Ready | Build | BuildDone
  | Shutdown | Exit | GetState | AddTarget | RegisterCapability

let bspToolToString = (t: bspTool): string =>
  switch t {
  | CreateSession => "create_session"
  | Initialize => "initialize"
  | Ready => "ready"
  | Build => "build"
  | BuildDone => "build_done"
  | Shutdown => "shutdown"
  | Exit => "exit"
  | GetState => "get_state"
  | AddTarget => "add_target"
  | RegisterCapability => "register_capability"
  }

/// Cloud provider tools.
type cloudTool =
  | Authenticate | Logout | GetState | BeginOperation | EndOperation | Reset

let cloudToolToString = (t: cloudTool): string =>
  switch t {
  | Authenticate => "authenticate"
  | Logout => "logout"
  | GetState => "get_state"
  | BeginOperation => "begin_operation"
  | EndOperation => "end_operation"
  | Reset => "reset"
  }

/// Communications tools (Gmail, Calendar).
type commsTool =
  | Authenticate | Logout | GetState | BeginOperation | EndOperation | Reset

let commsToolToString = (t: commsTool): string =>
  switch t {
  | Authenticate => "authenticate"
  | Logout => "logout"
  | GetState => "get_state"
  | BeginOperation => "begin_operation"
  | EndOperation => "end_operation"
  | Reset => "reset"
  }

/// Container management tools.
type containerTool =
  | BuildImage | Create | Start | Stop | Remove | GetState | Reset

let containerToolToString = (t: containerTool): string =>
  switch t {
  | BuildImage => "build_image"
  | Create => "create"
  | Start => "start"
  | Stop => "stop"
  | Remove => "remove"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// DAP debug adapter tools.
type dapTool =
  | CreateSession | Launch | Configure | Continue | Stopped
  | Terminate | Disconnect | GetState | AddBreakpoint

let dapToolToString = (t: dapTool): string =>
  switch t {
  | CreateSession => "create_session"
  | Launch => "launch"
  | Configure => "configure"
  | Continue => "continue"
  | Stopped => "stopped"
  | Terminate => "terminate"
  | Disconnect => "disconnect"
  | GetState => "get_state"
  | AddBreakpoint => "add_breakpoint"
  }

/// Database tools (SQLite, VeriSimDB, PostgreSQL).
type databaseTool =
  | Connect | ConnectSqlite | ConnectVerisimdb | Disconnect
  | ExecuteSql | ExecuteVql | GetState | Reset

let databaseToolToString = (t: databaseTool): string =>
  switch t {
  | Connect => "connect"
  | ConnectSqlite => "connect_sqlite"
  | ConnectVerisimdb => "connect_verisimdb"
  | Disconnect => "disconnect"
  | ExecuteSql => "execute_sql"
  | ExecuteVql => "execute_vql"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// Feedback collection tools.
type feedbackTool =
  | RegisterChannel | SubmitFeedback | GetSentiment | Deregister | Reset

let feedbackToolToString = (t: feedbackTool): string =>
  switch t {
  | RegisterChannel => "register_channel"
  | SubmitFeedback => "submit_feedback"
  | GetSentiment => "get_sentiment"
  | Deregister => "deregister"
  | Reset => "reset"
  }

/// Fleet (gitbot-fleet) tools.
type fleetTool = GetStatus | RecordGate | Reset

let fleetToolToString = (t: fleetTool): string =>
  switch t {
  | GetStatus => "get_status"
  | RecordGate => "record_gate"
  | Reset => "reset"
  }

/// Git/VCS tools.
type gitTool =
  | Authenticate | SelectRepo | BeginOperation | EndOperation
  | Logout | GetState | Reset

let gitToolToString = (t: gitTool): string =>
  switch t {
  | Authenticate => "authenticate"
  | SelectRepo => "select_repo"
  | BeginOperation => "begin_operation"
  | EndOperation => "end_operation"
  | Logout => "logout"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// Infrastructure as Code tools.
type iacTool =
  | InitWorkspace | Plan | Apply | Destroy | GetState | Reset

let iacToolToString = (t: iacTool): string =>
  switch t {
  | InitWorkspace => "init_workspace"
  | Plan => "plan"
  | Apply => "apply"
  | Destroy => "destroy"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// Kubernetes tools.
type k8sTool =
  | Connect | SelectNamespace | BeginOperation | EndOperation
  | Disconnect | GetState | Reset

let k8sToolToString = (t: k8sTool): string =>
  switch t {
  | Connect => "connect"
  | SelectNamespace => "select_namespace"
  | BeginOperation => "begin_operation"
  | EndOperation => "end_operation"
  | Disconnect => "disconnect"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// LSP language server tools.
type lspTool =
  | CreateSession | Initialize | Initialized | Shutdown
  | Exit | GetState | RegisterCapability

let lspToolToString = (t: lspTool): string =>
  switch t {
  | CreateSession => "create_session"
  | Initialize => "initialize"
  | Initialized => "initialized"
  | Shutdown => "shutdown"
  | Exit => "exit"
  | GetState => "get_state"
  | RegisterCapability => "register_capability"
  }

/// ML/AI tools (HuggingFace).
type mlTool =
  | Authenticate | Logout | GetState | BeginOperation | EndOperation | Reset

let mlToolToString = (t: mlTool): string =>
  switch t {
  | Authenticate => "authenticate"
  | Logout => "logout"
  | GetState => "get_state"
  | BeginOperation => "begin_operation"
  | EndOperation => "end_operation"
  | Reset => "reset"
  }

/// NeSy neurosymbolic reasoning tools.
type nesyTool = Harmonize | AnalyzeDrift | ReasoningModeInfo

let nesyToolToString = (t: nesyTool): string =>
  switch t {
  | Harmonize => "harmonize"
  | AnalyzeDrift => "analyze_drift"
  | ReasoningModeInfo => "reasoning_mode_info"
  }

/// Observability tools (Prometheus, Grafana, Loki, Jaeger).
type observeTool =
  | RegisterSource | BeginQuery | EndQuery | Unregister | GetState | Reset

let observeToolToString = (t: observeTool): string =>
  switch t {
  | RegisterSource => "register_source"
  | BeginQuery => "begin_query"
  | EndQuery => "end_query"
  | Unregister => "unregister"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// Proof assistant tools (Z3, CVC5, Lean, Coq, Agda, Isabelle, Idris2).
type proofTool =
  | InitSession | LoadObligation | Verify | GetResult
  | GetState | ResetSession | ResetAll

let proofToolToString = (t: proofTool): string =>
  switch t {
  | InitSession => "init_session"
  | LoadObligation => "load_obligation"
  | Verify => "verify"
  | GetResult => "get_result"
  | GetState => "get_state"
  | ResetSession => "reset_session"
  | ResetAll => "reset_all"
  }

/// Message queue tools (NATS, RabbitMQ, RedisStream).
type queuesTool =
  | Connect | Subscribe | BeginConsume | Ack | Publish
  | Unsubscribe | Disconnect | GetState | Reset

let queuesToolToString = (t: queuesTool): string =>
  switch t {
  | Connect => "connect"
  | Subscribe => "subscribe"
  | BeginConsume => "begin_consume"
  | Ack => "ack"
  | Publish => "publish"
  | Unsubscribe => "unsubscribe"
  | Disconnect => "disconnect"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// Academic research tools (Semantic Scholar, OpenAlex).
type researchTool =
  | Authenticate | Logout | GetState | BeginOperation | EndOperation | Reset

let researchToolToString = (t: researchTool): string =>
  switch t {
  | Authenticate => "authenticate"
  | Logout => "logout"
  | GetState => "get_state"
  | BeginOperation => "begin_operation"
  | EndOperation => "end_operation"
  | Reset => "reset"
  }

/// Secret management tools (Vault, SOPS, EnvVault).
type secretsTool =
  | Unseal | Authenticate | BeginAccess | EndAccess | Seal | GetState | Reset

let secretsToolToString = (t: secretsTool): string =>
  switch t {
  | Unseal => "unseal"
  | Authenticate => "authenticate"
  | BeginAccess => "begin_access"
  | EndAccess => "end_access"
  | Seal => "seal"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// Static site generation tools (Hugo, Zola, Astro, Casket).
type ssgTool =
  | LoadContent | BuildSite | Preview | ReadyDeploy | Deploy | Clean | GetState | Reset

let ssgToolToString = (t: ssgTool): string =>
  switch t {
  | LoadContent => "load_content"
  | BuildSite => "build_site"
  | Preview => "preview"
  | ReadyDeploy => "ready_deploy"
  | Deploy => "deploy"
  | Clean => "clean"
  | GetState => "get_state"
  | Reset => "reset"
  }

/// UMS level management tools.
type umsTool =
  | LoadLevel
  | SaveLevel
  | ValidateLevelAbi
  | ListLevels
  | ExportLevelConfig
  | CreateProject
  | OpenProject
  | DeleteProject
  | LoadTemplates
  | InstantiateTemplate

let umsToolToString = (t: umsTool): string =>
  switch t {
  | LoadLevel => "load_level"
  | SaveLevel => "save_level"
  | ValidateLevelAbi => "validate_level_abi"
  | ListLevels => "list_levels"
  | ExportLevelConfig => "export_level_config"
  | CreateProject => "create_project"
  | OpenProject => "open_project"
  | DeleteProject => "delete_project"
  | LoadTemplates => "load_templates"
  | InstantiateTemplate => "instantiate_template"
  }

/// Unified cartridge invocation — a single sum type over all (cartridge, tool) pairs.
/// This is what Update.res should use instead of raw string pairs.
type invocation =
  | Agent(agentTool)
  | Bsp(bspTool)
  | Cloud(cloudTool)
  | Comms(commsTool)
  | Container(containerTool)
  | Dap(dapTool)
  | Database(databaseTool)
  | Feedback(feedbackTool)
  | Fleet(fleetTool)
  | Git(gitTool)
  | Iac(iacTool)
  | K8s(k8sTool)
  | Lsp(lspTool)
  | Ml(mlTool)
  | Nesy(nesyTool)
  | Observe(observeTool)
  | Proof(proofTool)
  | Queues(queuesTool)
  | Research(researchTool)
  | Secrets(secretsTool)
  | Ssg(ssgTool)
  | Ums(umsTool)

/// Decompose a typed invocation into its wire-format (cartridge_name, tool_name) pair.
/// This is the bridge between the type-safe world and the string-based BojCmd layer.
let toWire = (inv: invocation): (string, string) =>
  switch inv {
  | Agent(t) => ("agent-mcp", agentToolToString(t))
  | Bsp(t) => ("bsp-mcp", bspToolToString(t))
  | Cloud(t) => ("cloud-mcp", cloudToolToString(t))
  | Comms(t) => ("comms-mcp", commsToolToString(t))
  | Container(t) => ("container-mcp", containerToolToString(t))
  | Dap(t) => ("dap-mcp", dapToolToString(t))
  | Database(t) => ("database-mcp", databaseToolToString(t))
  | Feedback(t) => ("feedback-mcp", feedbackToolToString(t))
  | Fleet(t) => ("fleet-mcp", fleetToolToString(t))
  | Git(t) => ("git-mcp", gitToolToString(t))
  | Iac(t) => ("iac-mcp", iacToolToString(t))
  | K8s(t) => ("k8s-mcp", k8sToolToString(t))
  | Lsp(t) => ("lsp-mcp", lspToolToString(t))
  | Ml(t) => ("ml-mcp", mlToolToString(t))
  | Nesy(t) => ("nesy-mcp", nesyToolToString(t))
  | Observe(t) => ("observe-mcp", observeToolToString(t))
  | Proof(t) => ("proof-mcp", proofToolToString(t))
  | Queues(t) => ("queues-mcp", queuesToolToString(t))
  | Research(t) => ("research-mcp", researchToolToString(t))
  | Secrets(t) => ("secrets-mcp", secretsToolToString(t))
  | Ssg(t) => ("ssg-mcp", ssgToolToString(t))
  | Ums(t) => ("ums-mcp", umsToolToString(t))
  }

/// Total cartridge count. Must match BoJ server's catalogue count.
/// Seam test validates this at build time.
let cartridgeCount = 22

/// Total tool count across all cartridges.
let toolCount = 162
