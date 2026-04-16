// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/**
 * Test Utilities for PanLL Integration Tests
 * 
 * Provides setup/teardown for test environments with VeriSimDB and Burble
 */

// Mock invoke import - will be replaced by test mock
// import { invoke } from "../src/ipc/ipc.js";

/**
 * Setup test environment with specified services
 * @param {Object} options - Test environment options
 * @param {string[]} options.services - Services to start (verisimdb, burble)
 * @param {boolean} options.cleanup - Whether to cleanup after tests
 * @returns {Promise<Object>} Environment configuration
 */
export async function setupTestEnvironment({ services = [], cleanup = true } = {}) {
  const env = {
    services: {
      verisimdb: false,
      burble: false
    },
    cleanup
  };

  // Start requested services
  for (const service of services) {
    if (service === "verisimdb") {
      await startVeriSimDB();
      env.services.verisimdb = true;
    } else if (service === "burble") {
      await startBurble();
      env.services.burble = true;
    }
  }

  return env;
}

/**
 * Teardown test environment
 * @param {Object} env - Environment to cleanup
 */
export async function teardownTestEnvironment(env) {
  if (env.cleanup) {
    // Cleanup identity snapshots
  try {
    if (globalThis.verisimdbMock) {
      const statesToDelete = [];
      for (const [key, value] of globalThis.verisimdbMock.states) {
        if (value.name && value.name.includes("Test")) {
          statesToDelete.push(key);
        }
      }
      for (const key of statesToDelete) {
        globalThis.verisimdbMock.states.delete(key);
      }
    }
  } catch (error) {
    console.warn("Cleanup warning:", error.message);
  }

    // Cleanup test files
    try {
      const fs = await import("https://deno.land/std@0.200.0/node/fs.ts");
      const path = await import("https://deno.land/std@0.200.0/path.ts");
      
      const homeDir = Deno.env.get("HOME") || "/home/user";
      const identitiesDir = path.join(homeDir, ".panll", "identities");
      
      // Remove test snapshot files
      const files = await fs.readdir(identitiesDir);
      for (const file of files) {
        if (file.includes("Test") || file.includes("test")) {
          await fs.rm(path.join(identitiesDir, file));
        }
      }
    } catch (error) {
      console.warn("Cleanup warning:", error.message);
    }
  }
}

/**
 * Start VeriSimDB service for testing
 */
async function startVeriSimDB() {
  // Check if VeriSimDB is already running
  try {
    const response = await fetch("http://localhost:8080/api/v1/health", {
      method: "GET",
      signal: AbortSignal.timeout(1000)
    });
    
    if (response.ok) {
      console.log("VeriSimDB already running");
      return;
    }
  } catch {
    // VeriSimDB not running, start it
  }

  // Start VeriSimDB (mock for testing)
  console.log("Starting VeriSimDB for tests...");
  
  // In real implementation, this would start the actual service
  // For testing, we'll use a mock that simulates the API
  globalThis.verisimdbMock = {
    states: new Map(),
    health: () => ({ status: "healthy", version: "1.0.0" }),
    saveState: (key, state) => {
      globalThis.verisimdbMock.states.set(key, state);
      return { success: true, key };
    },
    loadState: (key) => {
      const state = globalThis.verisimdbMock.states.get(key);
      if (!state) throw new Error("Not found");
      return state;
    }
  };
  
  // Set environment variable
  Deno.env.set("VERISIMDB_URL", "http://localhost:8080/api/v1");
}

/**
 * Start Burble service for testing
 */
async function startBurble() {
  // Check if Burble is already running
  try {
    const response = await fetch("http://localhost:6473/api/v1/status", {
      method: "GET",
      signal: AbortSignal.timeout(1000)
    });
    
    if (response.ok) {
      console.log("Burble already running");
      return;
    }
  } catch {
    // Burble not running, start it
  }

  // Start Burble (mock for testing)
  console.log("Starting Burble for tests...");
  
  // Mock Burble service
  globalThis.burbleMock = {
    broadcasts: [],
    status: () => ({ status: "running", connections: 0 }),
    broadcast: (payload) => {
      globalThis.burbleMock.broadcasts.push(payload);
      return { success: true, id: `broadcast-${Date.now()}` };
    },
    getBroadcasts: () => globalThis.burbleMock.broadcasts
  };
  
  // Set environment variable
  Deno.env.set("BURBLE_URL", "http://localhost:6473");
}

/**
 * Mock fetch for VeriSimDB calls
 */
export function setupVeriSimDBMock() {
  const originalFetch = globalThis.fetch;
  
  globalThis.fetch = async (input, init = {}) => {
    const url = input.toString();
    
    // Intercept VeriSimDB calls
    if (url.startsWith("http://localhost:8080/api/v1/")) {
      if (url.endsWith("/health")) {
        return new Response(JSON.stringify(globalThis.verisimdbMock.health()), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        });
      }
      
      if (url.includes("/state/")) {
        const key = url.split("/state/")[1];
        
        if (init.method === "POST") {
          const body = await init.body?.getReader().read();
          const state = JSON.parse(new TextDecoder().decode(body.value));
          const result = globalThis.verisimdbMock.saveState(key, state.state);
          return new Response(JSON.stringify(result), {
            status: 200,
            headers: { "Content-Type": "application/json" }
          });
        }
        
        if (init.method === "GET") {
          try {
            const state = globalThis.verisimdbMock.loadState(key);
            return new Response(JSON.stringify(state), {
              status: 200,
              headers: { "Content-Type": "application/json" }
            });
          } catch (error) {
            return new Response(JSON.stringify({ error: error.message }), {
              status: 404,
              headers: { "Content-Type": "application/json" }
            });
          }
        }
      }
    }
    
    // Intercept Burble calls
    if (url.startsWith("http://localhost:6473/api/v1/")) {
      if (url.endsWith("/status")) {
        return new Response(JSON.stringify(globalThis.burbleMock.status()), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        });
      }
      
      if (url.endsWith("/broadcast") && init.method === "POST") {
        const body = await init.body?.getReader().read();
        const payload = JSON.parse(new TextDecoder().decode(body.value));
        const result = globalThis.burbleMock.broadcast(payload);
        return new Response(JSON.stringify(result), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        });
      }
      
      if (url.endsWith("/broadcasts") && init.method === "GET") {
        const broadcasts = globalThis.burbleMock.getBroadcasts();
        return new Response(JSON.stringify(broadcasts), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        });
      }
    }
    
    // Fallback to original fetch
    return originalFetch(input, init);
  };
}

/**
 * Reset mocks between tests
 */
export function resetMocks() {
  delete globalThis.verisimdbMock;
  delete globalThis.burbleMock;
  
  if (globalThis.fetch === setupVeriSimDBMock) {
    // Restore original fetch
    delete globalThis.fetch;
  }
}