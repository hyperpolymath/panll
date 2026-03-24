// SPDX-License-Identifier: PMPL-1.0-or-later

//! System information queries for PanLL status bar widgets.
//!
//! Provides CPU usage, memory consumption, disk space, and uptime data.
//! Uses `/proc` on Linux (no external crate needed — sysinfo crate is
//! 3+ MB; we read procfs directly for a lean build).
//!
//! These commands are polled by the status bar at configurable intervals
//! (default: 2000ms for CPU, 5000ms for memory/disk).

use std::fs;

use super::types::SystemInfo;

/// Read CPU usage from /proc/stat. Returns a percentage (0.0-100.0).
/// This is a point-in-time sample — for smooth readings, the frontend
/// should average over multiple samples.
fn read_cpu_usage() -> f64 {
    // Read /proc/stat and parse the first "cpu" line.
    let content = match fs::read_to_string("/proc/stat") {
        Ok(c) => c,
        Err(_) => return 0.0,
    };

    let first_line = match content.lines().next() {
        Some(l) => l,
        None => return 0.0,
    };

    // cpu  user nice system idle iowait irq softirq steal guest guest_nice
    let parts: Vec<&str> = first_line.split_whitespace().collect();
    if parts.len() < 5 {
        return 0.0;
    }

    let user: f64 = parts[1].parse().unwrap_or(0.0);
    let nice: f64 = parts[2].parse().unwrap_or(0.0);
    let system: f64 = parts[3].parse().unwrap_or(0.0);
    let idle: f64 = parts[4].parse().unwrap_or(0.0);
    let iowait: f64 = if parts.len() > 5 { parts[5].parse().unwrap_or(0.0) } else { 0.0 };

    let total = user + nice + system + idle + iowait;
    if total > 0.0 {
        ((total - idle - iowait) / total) * 100.0
    } else {
        0.0
    }
}

/// Read memory info from /proc/meminfo. Returns (total_bytes, used_bytes).
fn read_memory_info() -> (u64, u64) {
    let content = match fs::read_to_string("/proc/meminfo") {
        Ok(c) => c,
        Err(_) => return (0, 0),
    };

    let mut total_kb: u64 = 0;
    let mut available_kb: u64 = 0;

    for line in content.lines() {
        if line.starts_with("MemTotal:") {
            total_kb = line.split_whitespace()
                .nth(1)
                .and_then(|v| v.parse().ok())
                .unwrap_or(0);
        } else if line.starts_with("MemAvailable:") {
            available_kb = line.split_whitespace()
                .nth(1)
                .and_then(|v| v.parse().ok())
                .unwrap_or(0);
        }

        if total_kb > 0 && available_kb > 0 {
            break;
        }
    }

    let total_bytes = total_kb * 1024;
    let used_bytes = total_bytes.saturating_sub(available_kb * 1024);
    (total_bytes, used_bytes)
}

/// Read disk usage for the Eclipse drive (or root if not mounted).
/// Returns (total_bytes, used_bytes).
fn read_disk_usage() -> (u64, u64) {
    // Try /proc/mounts to find the Eclipse drive, fall back to statvfs on root.
    let content = match fs::read_to_string("/proc/mounts") {
        Ok(c) => c,
        Err(_) => return (0, 0),
    };

    // Prefer the mount point named in PANLL_DATA_MOUNT (default: "eclipse"),
    // then fall back to root.
    let mount_hint = std::env::var("PANLL_DATA_MOUNT")
        .unwrap_or_else(|_| "eclipse".to_string());
    let mount_point = content.lines()
        .find(|l| l.contains(&mount_hint))
        .or_else(|| content.lines().find(|l| l.starts_with("/ ")))
        .and_then(|l| l.split_whitespace().nth(1))
        .unwrap_or("/");

    // Use libc statvfs to get filesystem stats.
    // SAFETY: statvfs is a POSIX syscall that writes into a zeroed struct we own.
    // The CString is valid for the duration of the call. No UB if path is invalid
    // (statvfs returns -1 and we fall through to (0, 0)).
    unsafe {
        let mut stat: libc::statvfs = std::mem::zeroed();
        let c_path = std::ffi::CString::new(mount_point).unwrap_or_default();
        if libc::statvfs(c_path.as_ptr(), &mut stat) == 0 {
            let total = stat.f_blocks as u64 * stat.f_frsize as u64;
            let available = stat.f_bavail as u64 * stat.f_frsize as u64;
            let used = total.saturating_sub(available);
            (total, used)
        } else {
            (0, 0)
        }
    }
}

/// Read system uptime from /proc/uptime. Returns seconds.
fn read_uptime() -> u64 {
    let content = match fs::read_to_string("/proc/uptime") {
        Ok(c) => c,
        Err(_) => return 0,
    };

    content.split_whitespace()
        .next()
        .and_then(|v| v.parse::<f64>().ok())
        .map(|v| v as u64)
        .unwrap_or(0)
}

/// Tauri command: get current system information for status bar widgets.
/// Returns a JSON-serialised SystemInfo struct.

pub async fn get_system_info() -> Result<String, String> {
    let cpu_usage = read_cpu_usage();
    let (memory_total, memory_used) = read_memory_info();
    let (disk_total, disk_used) = read_disk_usage();
    let uptime_seconds = read_uptime();

    let info = SystemInfo {
        cpu_usage,
        memory_total,
        memory_used,
        disk_total,
        disk_used,
        uptime_seconds,
    };

    serde_json::to_string(&info)
        .map_err(|e| format!("Serialisation error: {e}"))
}
