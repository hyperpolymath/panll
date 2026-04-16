# PanLL Identity Management Troubleshooting Guide

## Common Issues and Solutions

### VeriSimDB Connection Issues

#### Symptom: "VeriSimDB unavailable" errors

**Possible Causes**:
- VeriSimDB service not running
- Incorrect URL configuration
- Network connectivity problems
- Authentication issues

**Solutions**:

1. **Check VeriSimDB service status**:
   ```bash
   # Check if service is running
   systemctl status verisimdb
   
   # Or check container status
   docker ps | grep verisimdb
   ```

2. **Verify configuration**:
   ```bash
   # Check environment variable
   echo $VERISIMDB_URL
   
   # Should return: http://localhost:8080/api/v1 (or your custom URL)
   ```

3. **Test connectivity**:
   ```bash
   curl -v http://localhost:8080/api/v1/health
   ```

4. **Check PanLL logs**:
   ```bash
   # Look for connection errors
   journalctl -u panll --no-pager | grep -i verisim
   ```

#### Symptom: Fallback to filesystem storage

**Expected Behavior**: This is normal when VeriSimDB is unavailable. PanLL will:
- Continue working normally
- Store snapshots locally in `~/.panll/identities/`
- Automatically sync when VeriSimDB connection is restored

**Verification**:
```bash
# Check local snapshots
ls -la ~/.panll/identities/
```

### Identity Snapshot Issues

#### Symptom: "Snapshot not found" errors

**Possible Causes**:
- Invalid snapshot ID
- Snapshot stored only in VeriSimDB (not synced locally)
- Snapshot corrupted
- Permissions issue

**Solutions**:

1. **List available snapshots**:
   ```javascript
   const snapshots = await invoke("identity_list");
   console.log("Available snapshots:", snapshots);
   ```

2. **Check both storage locations**:
   ```bash
   # Check VeriSimDB (if available)
   curl http://localhost:8080/api/v1/state/
   
   # Check local storage
   ls ~/.panll/identities/
   ```

3. **Verify snapshot ID format**:
   - Should be UUID format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - No spaces or special characters

#### Symptom: Corrupted snapshot files

**Possible Causes**:
- Incomplete write operation
- Filesystem errors
- Manual file editing

**Solutions**:

1. **Validate snapshot JSON**:
   ```bash
   # Check JSON validity
   jq . ~/.panll/identities/snapshot-id.json
   ```

2. **Restore from VeriSimDB** (if available):
   ```javascript
   // Force load from VeriSimDB
   const snapshot = await invoke("verisim_load_state", {
     key: "your-snapshot-id"
   });
   
   // Re-save to fix local copy
   await invoke("identity_save", {
     name: snapshot.name,
     panll_state: snapshot.panll_state,
     settings: snapshot.settings,
     service_urls: snapshot.service_urls
   });
   ```

3. **Manual repair** (advanced):
   - Make backup of corrupted file
   - Edit JSON to fix syntax errors
   - Validate with `jq` before using

### Team Broadcast Issues

#### Symptom: Team broadcasts not received

**Possible Causes**:
- Burble service not running
- Network connectivity issues
- Incorrect Burble URL configuration
- Firewall blocking broadcasts

**Solutions**:

1. **Check Burble service status**:
   ```bash
   systemctl status burble
   # or
   docker ps | grep burble
   ```

2. **Verify Burble configuration**:
   ```bash
   echo $BURBLE_URL
   # Should return: http://localhost:6473 (or your custom URL)
   ```

3. **Test Burble connectivity**:
   ```bash
   curl -v http://localhost:6473/api/v1/status
   ```

4. **Check system tray notifications**:
   - Right-click PanLL system tray icon
   - Check "Burble Status" menu item
   - Should show "Connected" when working

#### Symptom: Broadcast received but won't apply

**Possible Causes**:
- Incompatible snapshot version
- Missing required services
- Permission restrictions
- Conflicting local changes

**Solutions**:

1. **Check snapshot compatibility**:
   ```javascript
   // Inspect snapshot before applying
   const snapshot = await invoke("identity_load", { id: broadcastId });
   console.log("Snapshot details:", snapshot);
   ```

2. **Manual application**:
   ```javascript
   // Apply parts of snapshot selectively
   const snapshot = await invoke("identity_load", { id: broadcastId });
   
   // Apply only settings (example)
   const settings = JSON.parse(snapshot.settings);
   await invoke("settings_set", {
     key: "some_setting",
     value: settings.some_setting
   });
   ```

3. **Check service availability**:
   ```javascript
   // Verify required services are running
   const services = await invoke("service_status_all");
   console.log("Service status:", services);
   ```

### System Tray Issues

#### Symptom: System tray icon missing

**Possible Causes**:
- PanLL not running
- System tray service crashed
- Display/WM issues

**Solutions**:

1. **Restart PanLL**:
   ```bash
   systemctl restart panll
   # or
   pkill panll; panll &
   ```

2. **Check system tray service**:
   ```bash
   # Reinitialize system tray
   await invoke("system_tray_init");
   ```

3. **Verify display environment**:
   ```bash
   echo $XDG_CURRENT_DESKTOP
   echo $DESKTOP_SESSION
   ```

#### Symptom: Service toggle not working

**Possible Causes**:
- Service not installed
- Permission issues
- Service crashed
- Configuration error

**Solutions**:

1. **Check service status**:
   ```javascript
   // Get current status
   const burbleStatus = await invoke("system_tray_get_burble_status");
   const gossamerStatus = await invoke("system_tray_get_gossamer_status");
   ```

2. **Manual service control**:
   ```bash
   # For Burble
   systemctl restart burble
   
   # For Gossamer
   systemctl restart gossamer
   ```

3. **Check logs**:
   ```bash
   journalctl -u burble -u gossamer --no-pager | tail -50
   ```

### Performance Issues

#### Symptom: Slow snapshot operations

**Possible Causes**:
- VeriSimDB under heavy load
- Large snapshot sizes
- Network latency
- Filesystem performance issues

**Solutions**:

1. **Check VeriSimDB performance**:
   ```bash
   curl http://localhost:8080/api/v1/stats
   ```

2. **Optimize snapshot size**:
   - Remove unnecessary data before saving
   - Compress large configuration objects

3. **Monitor operation times**:
   ```javascript
   const start = performance.now();
   await invoke("identity_save", { /* ... */ });
   const duration = performance.now() - start;
   console.log(`Save took ${duration}ms`);
   ```

4. **Fallback to local storage** (temporary):
   ```bash
   # Temporarily disable VeriSimDB
   export VERISIMDB_URL=""
   # Operations will use local storage only
   ```

### Configuration Issues

#### Symptom: Settings not persisting

**Possible Causes**:
- Permission issues
- Corrupted settings file
- Race conditions

**Solutions**:

1. **Check settings file**:
   ```bash
   ls -la ~/.panll/settings.json
   jq . ~/.panll/settings.json
   ```

2. **Reset settings**:
   ```javascript
   await invoke("settings_reset");
   ```

3. **Manual backup/restore**:
   ```bash
   # Backup
   cp ~/.panll/settings.json ~/.panll/settings.json.bak
   
   # Restore
   cp ~/.panll/settings.json.bak ~/.panll/settings.json
   ```

## Advanced Troubleshooting

### Debug Logging

Enable debug logging for detailed troubleshooting:

```bash
# Set debug environment variable
export PANLL_DEBUG=1

# Run PanLL
panll

# Check debug logs
tail -f ~/.panll/debug.log
```

### Network Diagnostics

```bash
# Check VeriSimDB connectivity
curl -v http://localhost:8080/api/v1/health

# Check Burble connectivity  
curl -v http://localhost:6473/api/v1/status

# Test with different timeouts
curl --connect-timeout 5 --max-time 10 http://localhost:8080/api/v1/health
```

### Manual VeriSimDB Operations

```bash
# Save snapshot manually to VeriSimDB
SNAPSHOT_ID="your-snapshot-id"
SNAPSHOT_DATA='{"name":"Test","created_at":"2024-01-01T00:00:00Z"}'

curl -X POST \
  http://localhost:8080/api/v1/state/$SNAPSHOT_ID \
  -H "Content-Type: application/json" \
  -d "{\"state\": $SNAPSHOT_DATA}"

# Load snapshot manually from VeriSimDB
curl http://localhost:8080/api/v1/state/$SNAPSHOT_ID
```

### Filesystem Verification

```bash
# Check filesystem integrity
fsck ~/.panll/identities/

# Verify file permissions
chmod -R 600 ~/.panll/identities/
chown -R $USER:$USER ~/.panll/
```

## Common Error Messages

### "JSON serialise error"

**Cause**: Invalid JSON data in snapshot

**Solution**: Validate all input data before saving

```javascript
// Validate before saving
try {
  JSON.parse(panll_state);
  JSON.parse(settings);
  JSON.parse(service_urls);
  await invoke("identity_save", { /* ... */ });
} catch (e) {
  console.error("Invalid JSON:", e.message);
}
```

### "HTTP client error"

**Cause**: Network or VeriSimDB connection issue

**Solution**: Check network connectivity and VeriSimDB status

### "Snapshot not found"

**Cause**: Snapshot doesn't exist in either storage location

**Solution**: Verify snapshot ID and check both VeriSimDB and local storage

### "Broadcast failed"

**Cause**: Burble service issue or network problem

**Solution**: Check Burble service status and network connectivity

## Recovery Procedures

### Restore from Backup

```bash
# Restore entire identities directory
cp -r ~/.panll/backups/identities/ ~/.panll/

# Restore specific snapshot
cp ~/.panll/backups/identities/snapshot-id.json ~/.panll/identities/
```

### Manual Snapshot Migration

```javascript
// Migrate from old format to new format
const oldSnapshot = { /* old format data */ };

const newSnapshot = {
  id: oldSnapshot.id || uuid.v4(),
  name: oldSnapshot.name || "Migrated Snapshot",
  created_at: oldSnapshot.created_at || new Date().toISOString(),
  panll_state: JSON.stringify(oldSnapshot.state || {}),
  settings: JSON.stringify(oldSnapshot.settings || {}),
  service_urls: JSON.stringify(oldSnapshot.services || {})
};

await invoke("identity_save", newSnapshot);
```

### Emergency Mode

If all else fails, you can run PanLL in emergency mode:

```bash
# Disable all external services
export VERISIMDB_URL=""
export BURBLE_URL=""
export DISABLE_SYSTEM_TRAY=1

# Run with minimal functionality
panll --safe-mode
```

## Getting Help

### Diagnostic Information to Provide

When reporting issues, include:

1. PanLL version (`panll --version`)
2. Operating system and version
3. VeriSimDB version (if applicable)
4. Steps to reproduce the issue
5. Relevant log entries
6. Screenshot (if UI-related)

### Support Channels

- **GitHub Issues**: https://github.com/hyperpolymath/panll/issues
- **Discussions**: https://github.com/hyperpolymath/panll/discussions
- **Documentation**: https://panll.hyperpolymath.dev/docs

## Preventive Measures

### Regular Maintenance

```bash
# Weekly maintenance script
#!/bin/bash

# Backup identities
tar -czf ~/.panll/backups/identities-$(date +%Y%m%d).tar.gz ~/.panll/identities/

# Clean up old backups
find ~/.panll/backups/ -name "*.tar.gz" -mtime +30 -delete

# Verify snapshot integrity
find ~/.panll/identities/ -name "*.json" -exec jq . {} \; 2>/dev/null
```

### Monitoring

Set up monitoring for critical services:

```bash
# Simple health check script
#!/bin/bash

# Check VeriSimDB
if ! curl -s http://localhost:8080/api/v1/health >/dev/null; then
  echo "VeriSimDB down!" | systemd-cat -p emerg
fi

# Check Burble
if ! curl -s http://localhost:6473/api/v1/status >/dev/null; then
  echo "Burble down!" | systemd-cat -p emerg
fi
```

### Configuration Best Practices

1. **Use environment variables** for service URLs
2. **Regular backups** of identity snapshots
3. **Monitor service health** proactively
4. **Test fallback mechanisms** periodically
5. **Document team workflows** for consistency

## Related Documentation

- [User Guide](identity-user-guide.md)
- [API Reference](api-reference.md)
- [PanLL README](../README.adoc)