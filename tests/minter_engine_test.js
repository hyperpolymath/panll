// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * MinterEngine Tests — name validation, case conversion, backend/accessibility
 * labels and descriptions, wizard step helpers, template generation, file
 * summary, and default state validation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  reservedNames,
  validateName,
  toCamelCase,
  toSnakeCase,
  backendKindLabel,
  allBackendKinds,
  accessibilityLabel,
  accessibilityDescription,
  backendKindDescription,
  totalSteps,
  stepLabel,
  canProceedFromStep,
  generateModel,
  generateEngine,
  generateCmd,
  fileSummary,
  defaultForm,
  defaultState,
} from "../src/core/MinterEngine.res.js";

// -- reservedNames --

Deno.test("reservedNames contains expected entries", () => {
  assert(reservedNames.includes("CloudGuard"));
  assert(reservedNames.includes("Minter"));
  assert(reservedNames.includes("Model"));
  assert(reservedNames.includes("View"));
  assertEquals(reservedNames.length, 17);
});

// -- validateName --

Deno.test("validateName rejects empty string", () => {
  const result = validateName("");
  assertEquals(result.TAG, "NameInvalid");
  assert(result._0.includes("empty"));
});

Deno.test("validateName rejects single character", () => {
  const result = validateName("A");
  assertEquals(result.TAG, "NameInvalid");
  assert(result._0.includes("at least 2"));
});

Deno.test("validateName rejects lowercase start", () => {
  const result = validateName("myPanel");
  assertEquals(result.TAG, "NameInvalid");
  assert(result._0.includes("uppercase"));
});

Deno.test("validateName rejects reserved names", () => {
  const result = validateName("CloudGuard");
  assertEquals(result.TAG, "NameConflict");
  assert(result._0.includes("CloudGuard"));
});

Deno.test("validateName accepts valid PascalCase name", () => {
  assertEquals(validateName("NewPanel"), "NameValid");
});

Deno.test("validateName accepts two-character PascalCase name", () => {
  assertEquals(validateName("Ab"), "NameValid");
});

// -- toCamelCase --

Deno.test("toCamelCase converts PascalCase to camelCase", () => {
  assertEquals(toCamelCase("CloudGuard"), "cloudGuard");
  assertEquals(toCamelCase("Aerie"), "aerie");
  assertEquals(toCamelCase("MyPanel"), "myPanel");
});

Deno.test("toCamelCase returns empty string for empty input", () => {
  assertEquals(toCamelCase(""), "");
});

Deno.test("toCamelCase handles single character", () => {
  assertEquals(toCamelCase("A"), "a");
});

// -- toSnakeCase --

Deno.test("toSnakeCase converts PascalCase to snake_case", () => {
  assertEquals(toSnakeCase("CloudGuard"), "cloud_guard");
  assertEquals(toSnakeCase("MyPanel"), "my_panel");
  assertEquals(toSnakeCase("Aerie"), "aerie");
});

Deno.test("toSnakeCase handles multiple uppercase transitions", () => {
  assertEquals(toSnakeCase("ABCDef"), "a_b_c_def");
});

Deno.test("toSnakeCase returns empty string for empty input", () => {
  assertEquals(toSnakeCase(""), "");
});

// -- backendKindLabel --

Deno.test("backendKindLabel returns correct strings", () => {
  assertEquals(backendKindLabel("NoBackend"), "No Backend");
  assertEquals(backendKindLabel("FilesystemBackend"), "Filesystem");
  assertEquals(backendKindLabel("HttpBackend"), "HTTP API");
  assertEquals(backendKindLabel("DatabaseBackend"), "Database");
});

// -- allBackendKinds --

Deno.test("allBackendKinds has 4 entries", () => {
  assertEquals(allBackendKinds.length, 4);
});

Deno.test("allBackendKinds contains all backend kinds in order", () => {
  assertEquals(allBackendKinds, [
    "NoBackend",
    "FilesystemBackend",
    "HttpBackend",
    "DatabaseBackend",
  ]);
});

// -- accessibilityLabel --

Deno.test("accessibilityLabel returns correct strings", () => {
  assertEquals(accessibilityLabel("StandardAccessibility"), "Standard");
  assertEquals(accessibilityLabel("EnhancedAccessibility"), "Enhanced");
});

// -- accessibilityDescription --

Deno.test("accessibilityDescription returns correct descriptions", () => {
  const standard = accessibilityDescription("StandardAccessibility");
  assert(standard.includes("Keyboard nav"));
  const enhanced = accessibilityDescription("EnhancedAccessibility");
  assert(enhanced.includes("aria-live"));
});

// -- backendKindDescription --

Deno.test("backendKindDescription returns correct descriptions", () => {
  assert(backendKindDescription("NoBackend").includes("Pure frontend"));
  assert(backendKindDescription("FilesystemBackend").includes("Tauri"));
  assert(backendKindDescription("HttpBackend").includes("HTTP API"));
  assert(backendKindDescription("DatabaseBackend").includes("database"));
});

// -- totalSteps --

Deno.test("totalSteps is 4", () => {
  assertEquals(totalSteps, 4);
});

// -- stepLabel --

Deno.test("stepLabel returns correct labels for all steps", () => {
  assertEquals(stepLabel(0), "Name & Identity");
  assertEquals(stepLabel(1), "Backend & Config");
  assertEquals(stepLabel(2), "Capabilities");
  assertEquals(stepLabel(3), "Review & Mint");
});

Deno.test("stepLabel returns Unknown for out-of-range step", () => {
  assertEquals(stepLabel(4), "Unknown");
  assertEquals(stepLabel(-1), "Unknown");
});

// -- canProceedFromStep --

Deno.test("canProceedFromStep rejects step 0 with invalid form", () => {
  const form = { ...defaultForm };
  assertEquals(canProceedFromStep(form, 0), false);
});

Deno.test("canProceedFromStep accepts step 0 with valid form", () => {
  const form = {
    ...defaultForm,
    panelName: "TestPanel",
    shortName: "TP",
    description: "A test panel for testing",
    nameValidation: "NameValid",
  };
  assertEquals(canProceedFromStep(form, 0), true);
});

Deno.test("canProceedFromStep accepts steps 1-3 unconditionally", () => {
  assertEquals(canProceedFromStep(defaultForm, 1), true);
  assertEquals(canProceedFromStep(defaultForm, 2), true);
  assertEquals(canProceedFromStep(defaultForm, 3), true);
});

Deno.test("canProceedFromStep rejects out-of-range step", () => {
  assertEquals(canProceedFromStep(defaultForm, 4), false);
});

// -- generateModel --

Deno.test("generateModel produces ReScript source with panel name", () => {
  const form = { ...defaultForm, panelName: "Weather", description: "Weather panel" };
  const src = generateModel(form);
  assert(src.includes("Weather"));
  assert(src.includes("weatherCategory"));
  assert(src.includes("SPDX-License-Identifier"));
});

// -- generateEngine --

Deno.test("generateEngine produces ReScript source with categoryLabel", () => {
  const form = { ...defaultForm, panelName: "Weather", description: "Weather panel" };
  const src = generateEngine(form);
  assert(src.includes("categoryLabel"));
  assert(src.includes("WeatherDashboard"));
  assert(src.includes("WeatherSettings"));
});

// -- generateCmd --

Deno.test("generateCmd returns undefined for NoBackend", () => {
  const form = { ...defaultForm, panelName: "Weather", backendKind: "NoBackend" };
  assertEquals(generateCmd(form), undefined);
});

Deno.test("generateCmd returns source string for HttpBackend", () => {
  const form = { ...defaultForm, panelName: "Weather", backendKind: "HttpBackend" };
  const src = generateCmd(form);
  assert(typeof src === "string");
  assert(src.includes("weather_load_data"));
});

// -- fileSummary --

Deno.test("fileSummary returns correct files for NoBackend", () => {
  const form = { ...defaultForm, panelName: "Weather", backendKind: "NoBackend" };
  const files = fileSummary(form);
  // 4 source files + 6 patches = 10
  assertEquals(files.length, 10);
  assert(files.some(f => f[0].includes("WeatherModel.res")));
  assert(files.some(f => f[0].includes("WeatherEngine.res")));
});

Deno.test("fileSummary includes Rust files for HttpBackend", () => {
  const form = { ...defaultForm, panelName: "Weather", backendKind: "HttpBackend" };
  const files = fileSummary(form);
  // 4 source + 1 cmd + 3 rust + 6 patches = 14
  assertEquals(files.length, 14);
  assert(files.some(f => f[0].includes("weather/mod.rs")));
});

// -- defaultForm --

Deno.test("defaultForm has empty panelName", () => {
  assertEquals(defaultForm.panelName, "");
});

Deno.test("defaultForm has NoBackend", () => {
  assertEquals(defaultForm.backendKind, "NoBackend");
});

Deno.test("defaultForm has EnhancedAccessibility", () => {
  assertEquals(defaultForm.accessibility, "EnhancedAccessibility");
});

Deno.test("defaultForm has empty capabilities", () => {
  assertEquals(defaultForm.capabilities.length, 0);
});

Deno.test("defaultForm icon is panel", () => {
  assertEquals(defaultForm.icon, "panel");
});

Deno.test("defaultForm nameValidation is NameInvalid", () => {
  assertEquals(defaultForm.nameValidation.TAG, "NameInvalid");
});

// -- defaultState --

Deno.test("defaultState minting is false", () => {
  assertEquals(defaultState.minting, false);
});

Deno.test("defaultState wizardStep is 0", () => {
  assertEquals(defaultState.wizardStep, 0);
});

Deno.test("defaultState lastResult is undefined (None)", () => {
  assertEquals(defaultState.lastResult, undefined);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});

Deno.test("defaultState form matches defaultForm", () => {
  assertEquals(defaultState.form.panelName, defaultForm.panelName);
  assertEquals(defaultState.form.backendKind, defaultForm.backendKind);
});
