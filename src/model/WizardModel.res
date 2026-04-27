// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Wizard Model — State for the plugin/panel creation wizard.
/// Depends on ProvisionerModel for pluginDependency, securityConfig, etc.
open ProvisionerModel

/// Wizard step
type wizardStep =
  /// Select what to create (panel or plugin)
  | SelectType
  /// Choose capabilities
  | ChooseCapabilities
  /// Configure dependencies
  | ConfigureDependencies
  /// Set up security
  | SetupSecurity
  /// Review and generate
  | ReviewAndGenerate

/// What are we creating?
type creationType =
  | CreatingPanel
  | CreatingPlugin

/// Security configuration
type securityConfig = {
  /// Trust tier
  trustTier: pluginTrustTier,
  /// Sandbox policy
  sandboxPolicy: sandboxPolicy,
  /// Network access
  networkAccess: bool,
  /// Filesystem access
  filesystemAccess: bool,
}

/// Generation result
type generationResult =
  | GenerationSuccess({
      filesCreated: array<string>,
      filesPatched: array<string>,
      warnings: array<string>,
    })
  | GenerationFailed(string)

/// Template for quick-start configurations
type wizardTemplate = {
  /// Template name
  name: string,
  /// Template description
  description: string,
  /// Category/organization
  category: string,
  /// Capabilities to auto-select
  capabilities: array<string>,
  /// Dependencies to auto-add
  dependencies: array<{
    pluginId: string,
    version: string,
  }>,
  /// Recommended security settings
  securityConfig: securityConfig,
}

/// Wizard state
type wizardState = {
  /// Current step
  currentStep: wizardStep,
  /// What are we creating?
  creationType: option<creationType>,
  /// Selected capabilities
  selectedCapabilities: array<string>,
  /// Configured dependencies
  dependencies: array<pluginDependency>,
  /// Security configuration
  securityConfig: securityConfig,
  /// Generation in progress
  generating: bool,
  /// Validation errors
  validationErrors: option<string>,
  /// Generation result
  generationResult: option<generationResult>,
  /// Currently selected template (if any)
  selectedTemplate: option<wizardTemplate>,
  /// Test results (for debugging/validation)
  testResults: option<{
    report: string,
    timestamp: float,
  }>,
}

/// Default wizard state
let defaultWizardState: wizardState = {
  currentStep: SelectType,
  creationType: None,
  selectedCapabilities: [],
  dependencies: [],
  securityConfig: {
    trustTier: Ayo,
    sandboxPolicy: {
      networkAccess: false,
      filesystemAccess: false,
      allowedCapabilities: [],
    },
    networkAccess: false,
    filesystemAccess: false,
  },
  generating: false,
  validationErrors: None,
  generationResult: None,
  selectedTemplate: None,
  testResults: None,
}

/// Capability registry
type capability = {
  id: string,
  name: string,
  description: string,
  category: string,
  requiredDependencies: array<string>,
}

/// Available capabilities by category
let capabilityRegistry: array<capability> = [
  {
    id: "ui-rendering",
    name: "UI Rendering",
    description: "Render user interfaces",
    category: "UI",
    requiredDependencies: [],
  },
  {
    id: "data-fetching",
    name: "Data Fetching",
    description: "Fetch data from APIs",
    category: "Data",
    requiredDependencies: ["http-client"],
  },
  {
    id: "http-client",
    name: "HTTP Client",
    description: "Make HTTP requests",
    category: "Network",
    requiredDependencies: [],
  },
  {
    id: "state-management",
    name: "State Management",
    description: "Manage application state",
    category: "State",
    requiredDependencies: [],
  },
  {
    id: "form-handling",
    name: "Form Handling",
    description: "Handle form input and validation",
    category: "UI",
    requiredDependencies: ["state-management"],
  },
  {
    id: "routing",
    name: "Routing",
    description: "Handle navigation and routing",
    category: "Navigation",
    requiredDependencies: [],
  },
  {
    id: "authentication",
    name: "Authentication",
    description: "Handle user authentication",
    category: "Security",
    requiredDependencies: ["http-client"],
  },
  {
    id: "authorization",
    name: "Authorization",
    description: "Handle user permissions",
    category: "Security",
    requiredDependencies: ["authentication"],
  },
]

/// Get capabilities by category
let getCapabilitiesByCategory = (category: string): array<capability> => {
  capabilityRegistry->Array.filter(cap => cap.category === category)
}

/// Get all capability categories
let getCapabilityCategories = (): array<string> => {
  capabilityRegistry
  ->Array.map(cap => cap.category)
  ->Array.reduce([], (acc, cat) =>
    if acc->Array.includes(cat) { acc } else { acc->Array.concat([cat]) }
  )
}

/// Check if capability is selected
let isCapabilitySelected = (capId: string, state: wizardState): bool => {
  state.selectedCapabilities->Array.includes(capId)
}

/// Toggle capability selection
let toggleCapability = (capId: string, state: wizardState): wizardState => {
  let selected = state.selectedCapabilities
  if (selected->Array.includes(capId)) {
    // Remove
    {
      ...state,
      selectedCapabilities: selected->Array.filter(id => id !== capId),
    }
  } else {
    // Add
    {
      ...state,
      selectedCapabilities: selected->Array.concat([capId]),
    }
  }
}

/// Get required dependencies for selected capabilities
let getRequiredDependencies = (state: wizardState): array<string> => {
  state.selectedCapabilities
  ->Array.flatMap(capId => {
    capabilityRegistry
    ->Array.find(cap => cap.id === capId)
    ->Option.map(cap => cap.requiredDependencies)
    ->Option.getOr([])
  })
  ->Array.reduce([], (acc, item) =>
    if acc->Array.includes(item) { acc } else { Array.concat(acc, [item]) }
  )
}

/// Check if all required dependencies are satisfied
let areDependenciesSatisfied = (state: wizardState): bool => {
  let required = getRequiredDependencies(state)
  let satisfied = state.dependencies->Array.map(dep => dep.pluginId)
  required->Array.every(req => satisfied->Array.includes(req))
}

/// Check if current step is the last step
let isLastStep = (step: wizardStep): bool => {
  step === ReviewAndGenerate
}

/// Add dependency to satisfy requirement
let addDependency = (pluginId: string, version: string, state: wizardState): wizardState => {
  let existing = state.dependencies->Array.find(dep => dep.pluginId === pluginId)
  
  if (existing->Option.isSome) {
    // Update existing
    {
      ...state,
      dependencies: state.dependencies->Array.map(dep =>
        dep.pluginId === pluginId ? {...dep, version} : dep
      ),
    }
  } else {
    // Add new
    {
      ...state,
      dependencies: state.dependencies->Array.concat([{
        pluginId,
        version,
        tier: Ayo,  // Default tier
      }]),
    }
  }
}

/// Validate wizard configuration
let validateWizardConfig = (state: wizardState): array<string> => {
  let errors = ref([]: array<string>)

  if state.creationType->Option.isNone {
    errors := errors.contents->Array.concat(["Please select what to create"])
  }

  if state.selectedCapabilities->Array.length === 0 {
    errors := errors.contents->Array.concat(["Please select at least one capability"])
  }

  if !areDependenciesSatisfied(state) {
    errors := errors.contents->Array.concat(["Some required dependencies are not satisfied"])
  }

  errors.contents
}

/// Can proceed to next step?
let canProceed = (state: wizardState): bool => {
  switch state.currentStep {
  | SelectType => state.creationType->Option.isSome
  | ChooseCapabilities => state.selectedCapabilities->Array.length > 0
  | ConfigureDependencies => areDependenciesSatisfied(state)
  | SetupSecurity => true  // Always can proceed from security
  | ReviewAndGenerate => validateWizardConfig(state)->Array.length === 0
  }
}

/// Get next step
let getNextStep = (current: wizardStep): wizardStep => {
  switch current {
  | SelectType => ChooseCapabilities
  | ChooseCapabilities => ConfigureDependencies
  | ConfigureDependencies => SetupSecurity
  | SetupSecurity => ReviewAndGenerate
  | ReviewAndGenerate => ReviewAndGenerate  // Stay on review
  }
}

/// Get previous step
let getPreviousStep = (current: wizardStep): wizardStep => {
  switch current {
  | SelectType => SelectType  // Stay on first step
  | ChooseCapabilities => SelectType
  | ConfigureDependencies => ChooseCapabilities
  | SetupSecurity => ConfigureDependencies
  | ReviewAndGenerate => SetupSecurity
  }
}

/// Step labels
let stepLabel = (step: wizardStep): string => {
  switch step {
  | SelectType => "1. Select Type"
  | ChooseCapabilities => "2. Choose Capabilities"
  | ConfigureDependencies => "3. Configure Dependencies"
  | SetupSecurity => "4. Setup Security"
  | ReviewAndGenerate => "5. Review & Generate"
  }
}

/// Step descriptions
let stepDescription = (step: wizardStep): string => {
  switch step {
  | SelectType => "Choose whether to create a panel or plugin"
  | ChooseCapabilities => "Select the capabilities your component needs"
  | ConfigureDependencies => "Set up required dependencies"
  | SetupSecurity => "Configure security and sandboxing"
  | ReviewAndGenerate => "Review your configuration and generate"
  }
}

/// Get step index (for progress tracking)
let stepIndex = (step: wizardStep): int => {
  switch step {
  | SelectType => 0
  | ChooseCapabilities => 1
  | ConfigureDependencies => 2
  | SetupSecurity => 3
  | ReviewAndGenerate => 4
  }
}

/// Check if step is the last step
let isLastStep = (step: wizardStep): bool => {
  step === ReviewAndGenerate
}

/// Predefined templates for common use cases
let templateRegistry: array<wizardTemplate> = [
  {
    name: "Basic Panel",
    description: "Simple panel with essential capabilities",
    category: "Panels",
    capabilities: ["ui-rendering", "state-management"],
    dependencies: [],
    securityConfig: {
      trustTier: Ayo,
      sandboxPolicy: {
        networkAccess: false,
        filesystemAccess: false,
        allowedCapabilities: ["ui-rendering", "state-management"],
      },
      networkAccess: false,
      filesystemAccess: false,
    },
  },
  {
    name: "Groove Integration Panel",
    description: "Panel with full Groove protocol support",
    category: "Panels",
    capabilities: ["groove-hard", "contractile", "http-client"],
    dependencies: [
      {
        pluginId: "groove-core",
        version: "1.0.0",
      },
    ],
    securityConfig: {
      trustTier: Ayo,
      sandboxPolicy: {
        networkAccess: true,
        filesystemAccess: false,
        allowedCapabilities: ["groove-hard", "contractile", "http-client"],
      },
      networkAccess: true,
      filesystemAccess: false,
    },
  },
  {
    name: "Data Visualization Plugin",
    description: "Plugin for data visualization components",
    category: "Plugins",
    capabilities: ["ui-rendering", "charting", "state-management"],
    dependencies: [
      {
        pluginId: "charting-lib",
        version: "2.1.0",
      },
    ],
    securityConfig: {
      trustTier: Ayo,
      sandboxPolicy: {
        networkAccess: false,
        filesystemAccess: false,
        allowedCapabilities: ["ui-rendering", "charting", "state-management"],
      },
      networkAccess: false,
      filesystemAccess: false,
    },
  },
  {
    name: "Governance Plugin",
    description: "Plugin with contractile governance support",
    category: "Plugins",
    capabilities: ["contractile", "provisioner", "state-management"],
    dependencies: [
      {
        pluginId: "contractile-core",
        version: "1.2.0",
      },
    ],
    securityConfig: {
      trustTier: Shield,
      sandboxPolicy: {
        networkAccess: false,
        filesystemAccess: true,
        allowedCapabilities: ["contractile", "provisioner", "state-management"],
      },
      networkAccess: false,
      filesystemAccess: true,
    },
  },
]

/// Get template by name
let getTemplateByName = (name: string): option<wizardTemplate> => {
  templateRegistry->Array.find(template => template.name === name)
}

/// Get templates by category
let getTemplatesByCategory = (category: string): array<wizardTemplate> => {
  templateRegistry->Array.filter(template => template.category === category)
}

/// Apply template to wizard state
let applyTemplate = (template: wizardTemplate, wizard: wizardState): wizardState => {
  {
    ...wizard,
    selectedCapabilities: template.capabilities,
    dependencies: template.dependencies->Array.map((dep): pluginDependency => ({
      pluginId: dep.pluginId,
      version: dep.version,
      tier: Ayo,
    })),
    securityConfig: template.securityConfig,
    selectedTemplate: Some(template),
    validationErrors: None, // Clear any validation errors when applying template
  }
}
