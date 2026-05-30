# PanLL Developer Guide

## Overview

This guide provides comprehensive information for developers who want to extend, customize, or integrate with PanLL's identity management system. Learn how to build plugins, extend the API, and contribute to the core system.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Identity Management API](#identity-management-api)
4. [Extending Identity Management](#extending-identity-management)
5. [Plugin System](#plugin-system)
6. [Custom Storage Backends](#custom-storage-backends)
7. [Testing & Quality Assurance](#testing--quality-assurance)
8. [Performance Optimization](#performance-optimization)
9. [Contributing to Core](#contributing-to-core)
10. [API Reference](#api-reference)

## Architecture Overview

### System Architecture

```mermaid
graph TD
    A[Frontend: ReScript/React] -->|IPC| B[Backend: Rust/Gossamer]
    B -->|FFI| C[Gossamer Shell: Zig]
    B -->|HTTP| D[VeriSimDB: Rust]
    B -->|HTTP| E[Burble: Rust]
    B -->|FS| F[Local Storage]
    D -->|SQLite| G[Database]
    E -->|WebSocket| H[Team Members]
```

### Identity Management Components

```
┌───────────────────────────────────────────────────┐
│                 Identity Management               │
├─────────────────┬─────────────────┬───────────────┤
│   Core API      │  Storage Layer  │  Cache Layer  │
├─────────────────┼─────────────────┼───────────────┤
│ - identity.rs   │ - VeriSimDB     │ - LRU Cache   │
│ - commands      │ - Filesystem    │ - Disk Cache  │
│ - validation    │ - Plugins       │ - TTL         │
└─────────────────┴─────────────────┴───────────────┘
                      │
                      ▼
┌───────────────────────────────────────────────────┐
│                 External Services                │
├─────────────────┬─────────────────┬───────────────┤
│   VeriSimDB     │    Burble       │  Custom       │
│   API           │   Broadcast     │  Services     │
└─────────────────┴─────────────────┴───────────────┘
```

### Key Modules

| Module | Language | Purpose |
|--------|----------|---------|
| `identity.rs` | Rust | Core identity operations |
| `identity_cache.rs` | Rust | Caching layer |
| `IdentityService.res` | ReScript | Frontend service |
| `IdentityStore.res` | ReScript | Frontend state management |
| `verisimdb_bridge.rs` | Rust | VeriSimDB integration |

## Development Environment Setup

### Prerequisites

```bash
# Install system dependencies
sudo apt update
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    libgtk-3-dev \
    libwebkit2gtk-4.0-dev \
    nodejs \
    npm

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install Deno
curl -fsSL https://deno.land/x/install/install.sh | sh
export DENO_INSTALL="/home/$USER/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
```

ReScript is pinned in `deno.json` (`npm:rescript@^12.0.0`) and resolved on first `deno task res:build` — no global install required.

### Clone and Build

```bash
# Clone repository
git clone https://github.com/hyperpolymath/panll.git
cd panll

# Build backend
cargo build --release

# Build frontend
cd src
deno task build

# Run in development mode
panll --dev
```

### IDE Setup

#### VS Code Recommended Extensions

- **Rust Analyzer** - Rust language support
- **ReScript** - ReScript language support
- **Deno** - Deno support
- **TOML** - TOML syntax highlighting
- **Even Better TOML** - Enhanced TOML support

#### VS Code Settings

```json
{
  "rust-analyzer.checkOnSave": true,
  "rust-analyzer.cargo.runBuildScripts": true,
  "rescript.enable": true,
  "deno.enable": true,
  "editor.formatOnSave": true,
  "[rust]": {
    "editor.defaultFormatter": "rust-lang.rust-analyzer"
  },
  "[rescript]": {
    "editor.defaultFormatter": "chrisdavies.rescript-vscode"
  }
}
```

## Identity Management API

### Core API Endpoints

```rust
// src-gossamer/src/main.rs

// Save identity snapshot
app.command("identity_save", |payload| {
    let name = get_str(&payload, "name")?;
    let panll_state = get_str(&payload, "panll_state")?;
    let settings = get_str(&payload, "settings")?;
    let service_urls = get_str(&payload, "service_urls")?;
    result_to_json(identity::identity_save(&name, &panll_state, &settings, &service_urls))
});

// Load identity snapshot
app.command("identity_load", |payload| {
    let id = get_str(&payload, "id")?;
    result_to_json(identity::identity_load(&id))
});

// List all snapshots
app.command("identity_list", |_payload| {
    result_to_json(identity::identity_list())
});

// Delete snapshot
app.command("identity_delete", |payload| {
    let id = get_str(&payload, "id")?;
    result_to_json(identity::identity_delete(&id))
});

// Broadcast to team
app.command("team_broadcast_state", |payload| {
    let snapshot_json = get_str(&payload, "snapshot_json")?;
    result_to_json(identity::team_broadcast_state(&snapshot_json))
});
```

### Frontend API (ReScript)

```rescript
// src/core/IdentityService.res

module IdentityService = {
  let save = (~name, ~panllState, ~settings, ~serviceUrls) => {
    ErrorBoundary.invokeWithBoundary("identity_save", {
      "name": name,
      "panll_state": panllState,
      "settings": settings,
      "service_urls": serviceUrls
    })
  };

  let load = (~id) => {
    ErrorBoundary.invokeWithBoundary("identity_load", {"id": id})
  };

  let list = () => {
    ErrorBoundary.invokeWithBoundary("identity_list", ())
  };

  let delete = (~id) => {
    ErrorBoundary.invokeWithBoundary("identity_delete", {"id": id})
  };

  let broadcast = (~snapshotJson) => {
    ErrorBoundary.invokeWithBoundary("team_broadcast_state", {"snapshot_json": snapshotJson})
  };
};
```

### Type Definitions

```typescript
// IdentitySnapshot interface
interface IdentitySnapshot {
  id: string;              // UUID v4
  name: string;           // Human-readable name
  created_at: string;      // ISO 8601 timestamp
  panll_state: string;     // JSON string of panel state
  settings: string;         // JSON string of settings
  service_urls: string;     // JSON string of service registry
}

// API Response format
interface ApiResponse<T> {
  ok: boolean;
  result?: T;
  error?: string;
}
```

## Extending Identity Management

### Adding Custom Fields

```rust
// src-gossamer/src/identity.rs

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdentitySnapshot {
    /// Unique snapshot identifier (UUID v4).
    pub id: String,
    /// Human-readable snapshot name.
    pub name: String,
    /// ISO 8601 creation timestamp.
    pub created_at: String,
    /// Panel state JSON (from Storage.serialize()).
    pub panll_state: String,
    /// Settings JSON (from settings_get()).
    pub settings: String,
    /// Service registry JSON (from service_registry_get()).
    pub service_urls: String,
    /// NEW: Custom metadata field
    pub metadata: Option<serde_json::Value>,
    /// NEW: Tags for categorization
    pub tags: Option<Vec<String>>,
}
```

### Adding New Commands

```rust
// 1. Add to main.rs
app.command("identity_add_tag", |payload| {
    let id = get_str(&payload, "id")?;
    let tag = get_str(&payload, "tag")?;
    result_to_json(identity::add_tag(&id, &tag))
});

// 2. Implement in identity.rs
pub fn add_tag(id: &str, tag: &str) -> Result<String, String> {
    // Load existing snapshot
    let mut snapshot: IdentitySnapshot = match identity_load(id) {
        Ok(json) => serde_json::from_str(&json)?,
        Err(e) => return Err(e),
    };
    
    // Add tag
    let tags = snapshot.tags.unwrap_or_default();
    if !tags.contains(&tag.to_string()) {
        snapshot.tags = Some([tags, vec![tag.to_string()]].concat());
        
        // Save updated snapshot
        let json = serde_json::to_string(&snapshot)?;
        identity_save(
            &snapshot.name,
            &snapshot.panll_state,
            &snapshot.settings,
            &snapshot.service_urls
        )?;
    }
    
    Ok(json!({"success": true, "id": id, "tag": tag}).to_string())
}

// 3. Add to frontend
let addTag = (~id, ~tag) => {
    ErrorBoundary.invokeWithBoundary("identity_add_tag", {"id": id, "tag": tag})
};
```

### Custom Validation

```rust
// Add validation function
pub fn validate_snapshot(snapshot: &IdentitySnapshot) -> Result<(), String> {
    // Check name length
    if snapshot.name.len() > 100 {
        return Err("Snapshot name too long (max 100 chars)".to_string());
    }
    
    // Validate JSON fields
    if let Err(e) = serde_json::from_str::<serde_json::Value>(&snapshot.panll_state) {
        return Err(format!("Invalid panll_state JSON: {}", e));
    }
    
    if let Err(e) = serde_json::from_str::<serde_json::Value>(&snapshot.settings) {
        return Err(format!("Invalid settings JSON: {}", e));
    }
    
    if let Err(e) = serde_json::from_str::<serde_json::Value>(&snapshot.service_urls) {
        return Err(format!("Invalid service_urls JSON: {}", e));
    }
    
    // Check created_at format
    if let Err(e) = DateTime::parse_from_rfc3339(&snapshot.created_at) {
        return Err(format!("Invalid created_at format: {}", e));
    }
    
    Ok(())
}

// Use in save function
pub fn identity_save(...) -> Result<String, String> {
    let snapshot = IdentitySnapshot { ... };
    validate_snapshot(&snapshot)?;
    // ... rest of implementation
}
```

## Plugin System

### Plugin Architecture

```
┌───────────────────────────────────────────────────┐
│                 Plugin System                     │
├─────────────────┬─────────────────┬───────────────┤
│   Plugin API     │  Plugin Manager  │  Plugin       │
│                   │                  │  Registry     │
└─────────────────┴─────────────────┴───────────────┘
                      │
                      ▼
┌───────────────────────────────────────────────────┐
│                 Plugin Types                     │
├─────────────────┬─────────────────┬───────────────┤
│   Storage        │  Processing     │  UI           │
│   Plugins        │  Plugins        │  Extensions   │
└─────────────────┴─────────────────┴───────────────┘
```

### Plugin Interface

```rust
// src-gossamer/src/plugins/mod.rs

pub trait IdentityPlugin: Send + Sync {
    /// Plugin name
    fn name(&self) -> &str;
    
    /// Plugin version
    fn version(&self) -> &str;
    
    /// Initialize plugin
    fn initialize(&mut self, config: &PluginConfig) -> Result<(), String>;
    
    /// Plugin-specific functionality
    fn execute(&self, command: &str, payload: &serde_json::Value) -> Result<serde_json::Value, String>;
    
    /// Cleanup
    fn shutdown(&mut self) -> Result<(), String>;
}

pub struct PluginConfig {
    pub data_dir: PathBuf,
    pub cache_dir: PathBuf,
    pub config: serde_json::Value,
}
```

### Creating a Storage Plugin

```rust
// Example: S3 Storage Plugin
use async_trait::async_trait;
use aws_sdk_s3::Client;

pub struct S3StoragePlugin {
    client: Client,
    bucket: String,
    prefix: String,
}

#[async_trait]
impl IdentityPlugin for S3StoragePlugin {
    fn name(&self) -> &str { "s3-storage" }
    
    fn version(&self) -> &str { "0.1.0" }
    
    fn initialize(&mut self, config: &PluginConfig) -> Result<(), String> {
        let s3_config = config.config.get("s3")
            .ok_or("Missing S3 configuration")?;
        
        let bucket = s3_config.get("bucket")
            .and_then(|v| v.as_str())
            .ok_or("Missing S3 bucket")?;
        
        let region = s3_config.get("region")
            .and_then(|v| v.as_str())
            .unwrap_or("us-east-1");
        
        let prefix = s3_config.get("prefix")
            .and_then(|v| v.as_str())
            .unwrap_or("panll/identities");
        
        let config = aws_config::from_env()
            .region(Region::new(region.to_string()))
            .load()
            .await;
        
        self.client = Client::new(&config);
        self.bucket = bucket.to_string();
        self.prefix = prefix.to_string();
        
        Ok(())
    }
    
    async fn execute(&self, command: &str, payload: &serde_json::Value) -> Result<serde_json::Value, String> {
        match command {
            "save" => self.save_snapshot(payload).await,
            "load" => self.load_snapshot(payload).await,
            "delete" => self.delete_snapshot(payload).await,
            "list" => self.list_snapshots(payload).await,
            _ => Err(format!("Unknown command: {}", command)),
        }
    }
    
    fn shutdown(&mut self) -> Result<(), String> {
        // Cleanup resources
        Ok(())
    }
}

impl S3StoragePlugin {
    async fn save_snapshot(&self, payload: &serde_json::Value) -> Result<serde_json::Value, String> {
        let id = payload.get("id")
            .and_then(|v| v.as_str())
            .ok_or("Missing snapshot ID")?;
        
        let data = payload.get("data")
            .and_then(|v| v.as_str())
            .ok_or("Missing snapshot data")?;
        
        let key = format!("{}/{}.json", self.prefix, id);
        
        self.client
            .put_object()
            .bucket(&self.bucket)
            .key(&key)
            .body(data.as_bytes().to_vec())
            .send()
            .await
            .map_err(|e| format!("S3 upload failed: {}", e))?;
        
        Ok(json!({"success": true, "id": id}))
    }
    
    // Implement load_snapshot, delete_snapshot, list_snapshots...
}
```

### Plugin Registration

```rust
// src-gossamer/src/main.rs

mod plugins;
use plugins::{PluginManager, IdentityPlugin};

fn main() {
    // Initialize plugin manager
    let mut plugin_manager = PluginManager::new();
    
    // Load plugins from configuration
    let plugin_configs = get_plugin_configs();
    for config in plugin_configs {
        if let Err(e) = plugin_manager.load_plugin(&config) {
            eprintln!("Failed to load plugin {}: {}", config.name, e);
        }
    }
    
    // Register plugin commands
    for plugin in plugin_manager.plugins() {
        let plugin_name = plugin.name().to_string();
        
        app.command(&format!("plugin_{}_execute", plugin_name), |payload| {
            let command = get_str(&payload, "command")?;
            let plugin_payload = get_value(&payload, "payload")?;
            
            match plugin_manager.execute(&plugin_name, &command, &plugin_payload) {
                Ok(result) => result_to_json(Ok(result)),
                Err(error) => result_to_json(Err(error)),
            }
        });
    }
}
```

### Frontend Plugin Integration

```rescript
// src/core/PluginManager.res

module PluginManager = {
  let execute = (~plugin, ~command, ~payload) => {
    ErrorBoundary.invokeWithBoundary(
      "plugin_" ++ plugin ++ "_execute",
      {
        "command": command,
        "payload": payload
      }
    )
  };

  let s3Save = (~id, ~data) => {
    execute(
      ~plugin="s3_storage",
      ~command="save",
      ~payload={"id": id, "data": data}
    )
  };

  let s3Load = (~id) => {
    execute(
      ~plugin="s3_storage",
      ~command="load",
      ~payload={"id": id}
    )
  };
};
```

## Custom Storage Backends

### Storage Backend Interface

```rust
// src-gossamer/src/storage/mod.rs

pub trait IdentityStorage: Send + Sync {
    /// Save an identity snapshot
    fn save(&self, id: &str, snapshot: &IdentitySnapshot) -> Result<(), String>;
    
    /// Load an identity snapshot
    fn load(&self, id: &str) -> Result<IdentitySnapshot, String>;
    
    /// List all snapshots (metadata only)
    fn list(&self) -> Result<Vec<SnapshotMeta>, String>;
    
    /// Delete an identity snapshot
    fn delete(&self, id: &str) -> Result<(), String>;
    
    /// Check if snapshot exists
    fn exists(&self, id: &str) -> bool;
    
    /// Get storage statistics
    fn stats(&self) -> StorageStats;
}

pub struct StorageStats {
    pub snapshot_count: usize,
    pub total_size_bytes: u64,
    pub storage_type: String,
}
```

### Implementing a Custom Backend

```rust
// Example: PostgreSQL Storage Backend
use sqlx::postgres::PgPoolOptions;
use sqlx::{PgPool, Postgres, Transaction};

pub struct PostgresStorage {
    pool: PgPool,
}

impl PostgresStorage {
    pub async fn new(connection_string: &str) -> Result<Self, String> {
        let pool = PgPoolOptions::new()
            .max_connections(10)
            .connect(connection_string)
            .await
            .map_err(|e| format!("Database connection failed: {}", e))?;
        
        // Initialize database schema
        sqlx::migrate!().run(&pool).await
            .map_err(|e| format!("Migration failed: {}", e))?;
        
        Ok(Self { pool })
    }
}

#[async_trait::async_trait]
impl IdentityStorage for PostgresStorage {
    async fn save(&self, id: &str, snapshot: &IdentitySnapshot) -> Result<(), String> {
        let json = serde_json::to_value(snapshot)
            .map_err(|e| format!("Serialization failed: {}", e))?;
        
        sqlx::query(
            r#"
            INSERT INTO identity_snapshots (id, data, created_at)
            VALUES ($1, $2, NOW())
            ON CONFLICT (id) DO UPDATE SET data = $2, updated_at = NOW()
            "#
        )
        .bind(id)
        .bind(json)
        .execute(&self.pool)
        .await
        .map_err(|e| format!("Save failed: {}", e))?;
        
        Ok(())
    }
    
    async fn load(&self, id: &str) -> Result<IdentitySnapshot, String> {
        let row = sqlx::query("SELECT data FROM identity_snapshots WHERE id = $1")
            .bind(id)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| format!("Load failed: {}", e))?;
        
        let json: serde_json::Value = row.get("data");
        serde_json::from_value(json)
            .map_err(|e| format!("Deserialization failed: {}", e))
    }
    
    async fn list(&self) -> Result<Vec<SnapshotMeta>, String> {
        let rows = sqlx::query(
            r#"
            SELECT id, 
                   data->>'name' as name, 
                   created_at as created_at
            FROM identity_snapshots
            ORDER BY created_at DESC
            "#
        )
        .fetch_all(&self.pool)
        .await
        .map_err(|e| format!("List failed: {}", e))?;
        
        rows.into_iter()
            .map(|row| {
                Ok(SnapshotMeta {
                    id: row.get("id"),
                    name: row.get("name"),
                    created_at: row.get("created_at"),
                })
            })
            .collect()
    }
    
    async fn delete(&self, id: &str) -> Result<(), String> {
        sqlx::query("DELETE FROM identity_snapshots WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(|e| format!("Delete failed: {}", e))?;
        
        Ok(())
    }
    
    fn exists(&self, id: &str) -> bool {
        // Implementation
        true
    }
    
    async fn stats(&self) -> StorageStats {
        // Implementation
        StorageStats {
            snapshot_count: 0,
            total_size_bytes: 0,
            storage_type: "postgres".to_string(),
        }
    }
}
```

### Storage Backend Configuration

```toml
# storage.toml
[storage]
# Primary storage backend
primary = "verisimdb"

# Fallback chain
fallback = ["filesystem", "s3"]

# Backend configurations
[storage.verisimdb]
enabled = true
url = "http://localhost:8080/api/v1"

[storage.filesystem]
enabled = true
path = "/var/panll/identities"

[storage.s3]
enabled = false
bucket = "panll-snapshots"
region = "us-east-1"
prefix = "identities"

[storage.postgres]
enabled = false
connection_string = "postgres://user:pass@localhost/panll"
```

### Multi-Backend Strategy

```rust
// src-gossamer/src/storage/strategy.rs

pub struct MultiBackendStorage {
    primary: Box<dyn IdentityStorage>,
    fallbacks: Vec<Box<dyn IdentityStorage>>,
}

impl MultiBackendStorage {
    pub fn new(
        primary: Box<dyn IdentityStorage>,
        fallbacks: Vec<Box<dyn IdentityStorage>>,
    ) -> Self {
        Self { primary, fallbacks }
    }
    
    pub async fn save_with_fallback(&self, id: &str, snapshot: &IdentitySnapshot) -> Result<(), String> {
        // Try primary first
        if let Err(e) = self.primary.save(id, snapshot).await {
            log::warn!("Primary storage failed: {}, trying fallbacks", e);
            
            // Try fallbacks in order
            for fallback in &self.fallbacks {
                if let Ok(_) = fallback.save(id, snapshot).await {
                    log::info!("Fallback storage succeeded");
                    return Ok(());
                }
            }
            
            return Err(format!("All storage backends failed: {}", e));
        }
        
        Ok(())
    }
    
    pub async fn load_with_fallback(&self, id: &str) -> Result<IdentitySnapshot, String> {
        // Try primary first
        match self.primary.load(id).await {
            Ok(snapshot) => Ok(snapshot),
            Err(primary_error) => {
                log::warn!("Primary load failed: {}, trying fallbacks", primary_error);
                
                // Try fallbacks in order
                for fallback in &self.fallbacks {
                    match fallback.load(id).await {
                        Ok(snapshot) => {
                            log::info!("Fallback load succeeded");
                            return Ok(snapshot);
                        }
                        Err(fallback_error) => {
                            log::warn!("Fallback load failed: {}", fallback_error);
                        }
                    }
                }
                
                Err(format!("All storage backends failed: {}", primary_error))
            }
        }
    }
}
```

## Testing & Quality Assurance

### Unit Testing

```rust
// tests/identity_tests.rs

#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;
    use mockall::*;
    
    // Create a mock storage backend
    #[automock]
    pub trait MockIdentityStorage: IdentityStorage {}
    
    #[test]
    fn test_identity_save_validation() {
        let snapshot = IdentitySnapshot {
            id: "test-id".to_string(),
            name: "A".repeat(101), // Too long
            created_at: "invalid-date".to_string(),
            panll_state: "invalid-json".to_string(),
            settings: "{}".to_string(),
            service_urls: "{}".to_string(),
        };
        
        let result = validate_snapshot(&snapshot);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("too long"));
    }
    
    #[test]
    fn test_identity_save_success() {
        let mut mock_storage = MockIdentityStorage::new();
        
        // Setup expectations
        mock_storage.expect_save()
            .withf(|id, snapshot| id == "test-id" && snapshot.name == "Test")
            .times(1)
            .returning(|_, _| Ok(()));
        
        let result = identity_save(
            "Test",
            "{}",
            "{}",
            "{}"
        );
        
        assert!(result.is_ok());
        let snapshot: IdentitySnapshot = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(snapshot.name, "Test");
    }
    
    #[tokio::test]
    async fn test_multi_backend_fallback() {
        let mut primary = MockIdentityStorage::new();
        let mut fallback = MockIdentityStorage::new();
        
        // Primary fails, fallback succeeds
        primary.expect_save()
            .returning(|_, _| Err("Primary failed".to_string()));
        
        fallback.expect_save()
            .returning(|_, _| Ok(()));
        
        let storage = MultiBackendStorage::new(
            Box::new(primary),
            vec![Box::new(fallback)]
        );
        
        let snapshot = IdentitySnapshot {
            id: "test".to_string(),
            name: "Test".to_string(),
            created_at: "2024-01-01T00:00:00Z".to_string(),
            panll_state: "{}".to_string(),
            settings: "{}".to_string(),
            service_urls: "{}".to_string(),
        };
        
        let result = storage.save_with_fallback("test", &snapshot).await;
        assert!(result.is_ok());
    }
}
```

### Integration Testing

```javascript
// tests/identity_integration_test.js
import { assert, assertEquals } from "https://deno.land/std/testing/asserts.ts";
import { invoke } from "../src/ipc/ipc.js";

Deno.test("Custom storage backend integration", async (t) => {
    await t.step("Save with custom backend", async () => {
        const result = await invoke("identity_save", {
            name: "Custom Backend Test",
            panll_state: "{}",
            settings: "{}",
            service_urls: "{}",
            storage_backend: "postgres"
        });
        
        assert(result.ok);
        const snapshot = JSON.parse(result.result);
        assertEquals(snapshot.name, "Custom Backend Test");
    });
    
    await t.step("Verify backend selection", async () => {
        const stats = await invoke("storage_stats");
        assert(stats.ok);
        const statsData = JSON.parse(stats.result);
        assertEquals(statsData.primary, "postgres");
    });
});
```

### Performance Testing

```rust
// benchmarks/identity_benchmarks.rs

#[bench]
fn bench_identity_save(b: &mut Bencher) {
    let snapshot = IdentitySnapshot {
        id: "bench-test".to_string(),
        name: "Benchmark".to_string(),
        created_at: "2024-01-01T00:00:00Z".to_string(),
        panll_state: json!({
            "panels": ["PaneL", "PaneN", "PaneW"],
            "layout": "balanced"
        }).to_string(),
        settings: json!({"theme": "dark", "fontSize": 14}).to_string(),
        service_urls: json!({"verisimdb": "http://localhost:8080"}).to_string(),
    };
    
    b.iter(|| {
        // Reset mock storage
        let storage = MockIdentityStorage::new();
        identity_save_with_storage(&snapshot, &storage).unwrap();
    });
}

#[bench]
fn bench_identity_load(b: &mut Bencher) {
    let snapshot = create_test_snapshot();
    let storage = setup_test_storage_with_snapshot(&snapshot);
    
    b.iter(|| {
        identity_load_with_storage("test-id", &storage).unwrap();
    });
}

#[bench]
fn bench_batch_operations(b: &mut Bencher) {
    let snapshots = create_test_snapshots(100);
    let storage = MockIdentityStorage::new();
    
    b.iter(|| {
        batch_save_snapshots(&snapshots, &storage).unwrap();
    });
}
```

### Test Coverage

```bash
# Run all tests
cargo test --all-features

# Run specific test module
cargo test identity_tests

# Test with coverage
cargo tarpaulin --out Html

# Run frontend tests
deno test --allow-all

# Run integration tests
cargo test --test integration_tests

# Run benchmarks
cargo bench
```

## Performance Optimization

### Caching Strategies

```rust
// src-gossamer/src/identity_cache.rs

use lru::LruCache;
use std::num::NonZeroUsize;

pub struct IdentityCache {
    lru_cache: LruCache<String, String>, // ID -> JSON
    ttl_cache: HashMap<String, Instant>, // ID -> expiration
    cache_ttl: Duration,
}

impl IdentityCache {
    pub fn new(capacity: NonZeroUsize, ttl: Duration) -> Self {
        Self {
            lru_cache: LruCache::new(capacity),
            ttl_cache: HashMap::new(),
            cache_ttl: ttl,
        }
    }
    
    pub fn get(&mut self, id: &str) -> Option<String> {
        // Check TTL first
        if let Some(expiration) = self.ttl_cache.get(id) {
            if Instant::now() > *expiration {
                self.lru_cache.pop(id);
                self.ttl_cache.remove(id);
                return None;
            }
        }
        
        self.lru_cache.get(id).cloned()
    }
    
    pub fn set(&mut self, id: String, data: String) {
        self.lru_cache.put(id.clone(), data.clone());
        self.ttl_cache.insert(id, Instant::now() + self.cache_ttl);
    }
    
    pub fn invalidate(&mut self, id: &str) {
        self.lru_cache.pop(id);
        self.ttl_cache.remove(id);
    }
    
    pub fn stats(&self) -> CacheStats {
        CacheStats {
            size: self.lru_cache.len(),
            capacity: self.lru_cache.cap(),
            hit_rate: 0.0, // Would be tracked separately
        }
    }
}
```

### Batch Processing

```rust
// src-gossamer/src/batch.rs

pub async fn batch_save_snapshots(
    snapshots: Vec<IdentitySnapshot>,
    storage: &dyn IdentityStorage,
    batch_size: usize,
) -> Result<BatchResult, String> {
    let mut results = Vec::with_capacity(snapshots.len());
    let mut success = 0;
    let mut failures = 0;
    
    let start_time = Instant::now();
    
    // Process in batches
    for chunk in snapshots.chunks(batch_size) {
        let mut tasks = Vec::new();
        
        for snapshot in chunk {
            let storage = storage.clone();
            let snapshot = snapshot.clone();
            
            tasks.push(tokio::spawn(async move {
                storage.save(&snapshot.id, &snapshot).await
                    .map(|_| snapshot.id)
            }));
        }
        
        // Await batch
        for task in tasks {
            match task.await {
                Ok(Ok(id)) => {
                    results.push(BatchItemResult::Success(id));
                    success += 1;
                }
                Ok(Err(e)) => {
                    results.push(BatchItemResult::Failure(e));
                    failures += 1;
                }
                Err(e) => {
                    results.push(BatchItemResult::Failure(format!("Task failed: {}", e)));
                    failures += 1;
                }
            }
        }
    }
    
    let duration = start_time.elapsed();
    
    Ok(BatchResult {
        results,
        summary: BatchSummary {
            total: snapshots.len(),
            success,
            failures,
            duration_ms: duration.as_millis() as u64,
        }
    })
}
```

### Performance Monitoring

```rust
// src-gossamer/src/metrics.rs

pub struct IdentityMetrics {
    save_operations: AtomicU64,
    load_operations: AtomicU64,
    save_time: AtomicU64, // milliseconds
    load_time: AtomicU64, // milliseconds
    cache_hits: AtomicU64,
    cache_misses: AtomicU64,
}

impl IdentityMetrics {
    pub fn new() -> Self {
        Self {
            save_operations: AtomicU64::new(0),
            load_operations: AtomicU64::new(0),
            save_time: AtomicU64::new(0),
            load_time: AtomicU64::new(0),
            cache_hits: AtomicU64::new(0),
            cache_misses: AtomicU64::new(0),
        }
    }
    
    pub fn record_save(&self, duration: Duration) {
        self.save_operations.fetch_add(1, Ordering::Relaxed);
        self.save_time.fetch_add(duration.as_millis() as u64, Ordering::Relaxed);
    }
    
    pub fn record_load(&self, duration: Duration, cache_hit: bool) {
        self.load_operations.fetch_add(1, Ordering::Relaxed);
        self.load_time.fetch_add(duration.as_millis() as u64, Ordering::Relaxed);
        
        if cache_hit {
            self.cache_hits.fetch_add(1, Ordering::Relaxed);
        } else {
            self.cache_misses.fetch_add(1, Ordering::Relaxed);
        }
    }
    
    pub fn get_stats(&self) -> MetricsStats {
        let save_ops = self.save_operations.load(Ordering::Relaxed);
        let load_ops = self.load_operations.load(Ordering::Relaxed);
        
        MetricsStats {
            save_operations: save_ops,
            load_operations: load_ops,
            avg_save_time: if save_ops > 0 {
                self.save_time.load(Ordering::Relaxed) / save_ops
            } else {
                0
            },
            avg_load_time: if load_ops > 0 {
                self.load_time.load(Ordering::Relaxed) / load_ops
            } else {
                0
            },
            cache_hit_rate: if load_ops > 0 {
                (self.cache_hits.load(Ordering::Relaxed) as f64 / load_ops as f64) * 100.0
            } else {
                0.0
            },
        }
    }
    
    pub fn reset(&self) {
        self.save_operations.store(0, Ordering::Relaxed);
        self.load_operations.store(0, Ordering::Relaxed);
        self.save_time.store(0, Ordering::Relaxed);
        self.load_time.store(0, Ordering::Relaxed);
        self.cache_hits.store(0, Ordering::Relaxed);
        self.cache_misses.store(0, Ordering::Relaxed);
    }
}
```

### Performance Tips

1. **Caching**: Implement LRU cache with 256MB capacity
2. **Batching**: Use batch operations for bulk actions
3. **Compression**: Enable for snapshots >10KB
4. **Connection Pooling**: Reuse database connections
5. **Parallel Processing**: Use tokio for async I/O
6. **Lazy Loading**: Load only necessary data
7. **Pagination**: Implement for large result sets
8. **Debouncing**: For rapid UI updates

## Contributing to Core

### Contribution Guidelines

```markdown
# Contributing to PanLL

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Submit a pull request

## Code Standards

- Follow Rust API guidelines
- Use ReScript best practices
- Write comprehensive tests
- Document public APIs
- Keep changes focused

## Pull Request Process

1. Ensure tests pass
2. Update documentation
3. Add changelog entry
4. Request review
5. Address feedback
6. Merge when approved

## Branch Naming

- `feature/*` - New features
- `fix/*` - Bug fixes
- `docs/*` - Documentation
- `refactor/*` - Code refactoring
- `perf/*` - Performance improvements

## Commit Messages

- Use imperative mood
- Keep first line under 72 chars
- Reference issues when applicable
- Explain why, not just what

## Testing Requirements

- Unit tests for new functionality
- Integration tests for API changes
- Performance tests for optimizations
- Update existing tests if behavior changes

## Documentation

- Update README for new features
- Add API documentation
- Include usage examples
- Update architecture diagrams if needed

## Code Review Checklist

- [ ] Follows coding standards
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] Performance considered
- [ ] Security reviewed
- [ ] Error handling adequate

## Reporting Issues

- Use GitHub Issues
- Include reproduction steps
- Specify environment
- Attach logs if possible
- Suggest possible solutions

## License

By contributing, you agree to license your contributions under the PMPL-1.0-or-later.
```

### Development Workflow

```bash
# Setup
git clone https://github.com/your-fork/panll.git
cd panll
git remote add upstream https://github.com/hyperpolymath/panll.git

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes
# ... edit files ...

# Run tests
cargo test --all-features
deno test --allow-all

# Commit changes
git add .
git commit -m "Add your feature description"

# Push to your fork
git push origin feature/your-feature-name

# Create pull request
gh pr create --base main --head your-fork:feature/your-feature-name
```

### Code Review Process

1. **Automated Checks**: CI runs tests and lints
2. **Peer Review**: At least one approval required
3. **Maintainer Review**: Architecture and design review
4. **Merge**: After all checks pass

### Continuous Integration

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Install Rust
      uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
        override: true
    
    - name: Cache cargo
      uses: actions/cache@v3
      with:
        path: |
          ~/.cargo/bin/
          ~/.cargo/registry/index/
          ~/.cargo/registry/cache/
          ~/.cargo/git/db/
          target/
        key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
    
    - name: Build
      run: cargo build --all-features
    
    - name: Test
      run: cargo test --all-features
    
    - name: Lint
      run: cargo clippy --all-features -- -D warnings
    
    - name: Format check
      run: cargo fmt --all -- --check
    
    - name: Install Deno
      uses: denoland/setup-deno@v1
    
    - name: Frontend tests
      run: deno test --allow-all
    
    - name: Build frontend
      run: deno task build
```

## API Reference

### Core Identity API

```typescript
// Save identity snapshot
interface SaveIdentityParams {
  name: string;
  panll_state: string; // JSON
  settings: string;   // JSON
  service_urls: string; // JSON
  tags?: string[];     // Optional
  metadata?: any;      // Optional
}

interface SaveIdentityResult {
  id: string;
  name: string;
  created_at: string;
  // ... all snapshot fields
}

async function identitySave(params: SaveIdentityParams): Promise<ApiResponse<SaveIdentityResult>>;
```

### Storage Plugin API

```typescript
interface StoragePlugin {
  name: string;
  version: string;
  
  initialize(config: any): Promise<void>;
  
  execute(command: string, payload: any): Promise<any>;
  
  shutdown(): Promise<void>;
}

// Register plugin
async function registerStoragePlugin(plugin: StoragePlugin): Promise<void>;

// Unregister plugin
async function unregisterStoragePlugin(name: string): Promise<void>;
```

### Batch Operations API

```typescript
interface BatchOperationResult<T> {
  success: T[];
  failures: { id: string; error: string }[];
  summary: {
    total: number;
    success: number;
    failed: number;
    duration_ms: number;
  };
}

async function batchSaveSnapshots(
  snapshots: Omit<IdentitySnapshot, 'id' | 'created_at'>[]
): Promise<BatchOperationResult<IdentitySnapshot>>;

async function batchLoadSnapshots(
  ids: string[]
): Promise<BatchOperationResult<IdentitySnapshot>>;

async function batchDeleteSnapshots(
  ids: string[]
): Promise<BatchOperationResult<{id: string}>>;
```

### Cache Management API

```typescript
interface CacheStats {
  size: number;
  capacity: number;
  hit_rate: number; // 0-100
}

async function getCacheStats(): Promise<ApiResponse<CacheStats>>;

async function clearCache(): Promise<ApiResponse<{cleared: number}>>;

async function setCacheSize(sizeMb: number): Promise<ApiResponse<{new_size: number}>>;
```

## Conclusion

This developer guide provides comprehensive information for extending PanLL's identity management system. Whether you're building plugins, custom storage backends, or contributing to the core system, this guide covers the architecture, APIs, and best practices you'll need.

For more information:
- **API Reference**: Complete API documentation
- **Admin Guide**: Deployment and configuration
- **User Guide**: Using identity management features
- **GitHub**: Source code and issue tracker