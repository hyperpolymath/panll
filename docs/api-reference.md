# VeriSimDB Integration API Reference

## Overview

PanLL integrates with VeriSimDB for persistent storage of identity snapshots and other state data. This document describes the available API endpoints and their usage.

## Base Configuration

- **Default VeriSimDB URL**: `http://localhost:8080/api/v1`
- **Environment Variable**: `VERISIMDB_URL` (override default)
- **Timeout**: 10 seconds for all operations

## Identity Management Endpoints

### Save Identity Snapshot

**Command**: `verisim_save_state`

**Parameters**:
```json
{
  "key": "string",      // Snapshot ID (UUID)
  "state": "string"     // JSON string of IdentitySnapshot
}
```

**Returns**:
```json
{
  "ok": true,
  "result": "string"    // Success message or VeriSimDB response
}
```

**Example**:
```javascript
const result = await invoke("verisim_save_state", {
  key: "abc123-def456",
  state: JSON.stringify(snapshotData)
});
```

### Load Identity Snapshot

**Command**: `verisim_load_state`

**Parameters**:
```json
{
  "key": "string"       // Snapshot ID to load
}
```

**Returns**:
```json
{
  "ok": true,
  "result": {            // Parsed JSON object
    "id": "string",
    "name": "string",
    "created_at": "string",
    "panll_state": "string",
    "settings": "string",
    "service_urls": "string"
  }
}
```

**Example**:
```javascript
const snapshot = await invoke("verisim_load_state", {
  key: "abc123-def456"
});
```

## VeriSimDB Direct Access

### Health Check

**Command**: `verisim_health`

**Parameters**: None

**Returns**:
```json
{
  "ok": true,
  "result": "string"    // Health status JSON
}
```

### Execute VCL Query

**Command**: `verisim_vcl_execute`

**Parameters**:
```json
{
  "vcl": "string"       // VCL query string
}
```

**Returns**:
```json
{
  "ok": true,
  "result": "string"    // Query results JSON
}
```

### List Octads

**Command**: `verisim_octads_list`

**Parameters**:
```json
{
  "limit": number,      // Max results (default: 100)
  "offset": number       // Pagination offset (default: 0)
}
```

**Returns**:
```json
{
  "ok": true,
  "result": "string"    // Octads list JSON
}
```

### Get Drift Entity

**Command**: `verisim_drift_entity`

**Parameters**:
```json
{
  "entity_id": "string" // Entity ID to query
}
```

**Returns**:
```json
{
  "ok": true,
  "result": "string"    // Entity data JSON
}
```

### Trigger Normalizer

**Command**: `verisim_normalizer_trigger`

**Parameters**:
```json
{
  "entity_id": "string" // Entity ID to normalize
}
```

**Returns**:
```json
{
  "ok": true,
  "result": "string"    // Normalization result
}
```

### Get Octads for Entity

**Command**: `verisim_octads_get`

**Parameters**:
```json
{
  "entity_id": "string" // Entity ID
}
```

**Returns**:
```json
{
  "ok": true,
  "result": "string"    // Octads data JSON
}
```

## Orchestrator Endpoints

### Orchestrator Status

**Command**: `verisim_orch_status`

**Parameters**: None

**Returns**:
```json
{
  "ok": true,
  "result": "string"    // Orchestrator status JSON
}
```

## Error Handling

All commands return a consistent error format:

```json
{
  "ok": false,
  "error": "string"       // Error message
}
```

### Common Error Scenarios

**VeriSimDB Unavailable**:
- Automatic fallback to local filesystem storage
- Operations continue normally
- Data syncs when connection restored

**Invalid Snapshot ID**:
```json
{
  "ok": false,
  "error": "Snapshot not found: abc123"
}
```

**Network Timeout**:
```json
{
  "ok": false,
  "error": "GET failed: operation timed out"
}
```

## Storage Fallback Mechanism

### Primary → Fallback Flow

1. Attempt VeriSimDB operation
2. On success: Return VeriSimDB response
3. On failure: Fall back to local filesystem
4. On filesystem success: Return local data
5. On complete failure: Return error

### Fallback → Primary Sync

When VeriSimDB connection is restored:
1. System automatically detects connection
2. Local snapshots are synced to VeriSimDB
3. No manual intervention required
4. System tray shows sync completion notification

## Performance Characteristics

- **Save Operation**: ~50-150ms (VeriSimDB) / ~10-30ms (filesystem)
- **Load Operation**: ~60-200ms (VeriSimDB) / ~15-40ms (filesystem)
- **List Operation**: ~80-250ms (VeriSimDB) / ~20-50ms (filesystem)

## Rate Limiting

- No explicit rate limiting from PanLL
- VeriSimDB may impose limits (configurable server-side)
- Recommended: ≤ 10 operations/second for bulk operations

## Authentication

- VeriSimDB authentication handled at server level
- PanLL passes through configured credentials
- Set `VERISIMDB_AUTH_TOKEN` environment variable if required

## Best Practices

### Connection Management

```javascript
// Check VeriSimDB health before operations
const health = await invoke("verisim_health");
if (!health.ok) {
  console.warn("VeriSimDB unavailable, using fallback storage");
}
```

### Error Handling

```javascript
try {
  const result = await invoke("verisim_load_state", { key: snapshotId });
  if (!result.ok) {
    throw new Error(result.error);
  }
  // Process result
} catch (error) {
  console.error("Failed to load snapshot:", error.message);
  // Fallback to local storage or alternative
}
```

### Batch Operations

```javascript
// Process multiple snapshots efficiently
const snapshotIds = ["id1", "id2", "id3"];
const results = await Promise.all(
  snapshotIds.map(id => invoke("verisim_load_state", { key: id }))
);
```

## Troubleshooting

For common issues and solutions, see the [Troubleshooting Guide](troubleshooting.md).