// PanLL Panel-Clades FFI Implementation
//
// This module implements the C-compatible FFI declared in src/abi/Foreign.idr
// for the panel-clades subsystem.  All types and layouts must match the
// Idris2 ABI definitions in PanelClades.ABI.Types.
//
// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

const std = @import("std");

// Version information (keep in sync with project)
const VERSION = "0.1.0";
const BUILD_INFO = "panel_clades built with Zig " ++ @import("builtin").zig_version_string;

/// Total number of clade kinds — must match PanelClades.ABI.Types.cladeKindCount
const CLADE_KIND_COUNT: u32 = 13;

/// Thread-local error storage
threadlocal var last_error: ?[]const u8 = null;

/// Set the last error message
fn setError(msg: []const u8) void {
    last_error = msg;
}

/// Clear the last error
fn clearError() void {
    last_error = null;
}

//==============================================================================
// Core Types (must match src/abi/Types.idr)
//==============================================================================

/// Result codes (must match Idris2 Result type)
pub const Result = enum(c_int) {
    ok = 0,
    @"error" = 1,
    invalid_param = 2,
    out_of_memory = 3,
    null_pointer = 4,
};

/// Clade kind tags (must match Idris2 CladeKind type, 0..12)
pub const CladeKind = enum(u32) {
    directive = 0,
    scanner = 1,
    builder = 2,
    database = 3,
    network = 4,
    viewer = 5,
    ai = 6,
    loader = 7,
    meta = 8,
    service = 9,
    inspector = 10,
    bridge = 11,
    terminal = 12,
};

/// Library handle. A real struct internally; exposed across the C ABI as
/// an opaque pointer (the header forward-declares it). `opaque{}` cannot
/// have fields or be `create`d, so this must be a `struct`.
pub const Handle = struct {
    // Internal state hidden from C
    allocator: std.mem.Allocator,
    initialized: bool,
};

//==============================================================================
// Library Lifecycle
//==============================================================================

/// Initialize the library
/// Returns a handle, or null on failure
export fn panel_clades_init() ?*Handle {
    const allocator = std.heap.c_allocator;

    const handle = allocator.create(Handle) catch {
        setError("Failed to allocate handle");
        return null;
    };

    // Initialize handle
    handle.* = .{
        .allocator = allocator,
        .initialized = true,
    };

    clearError();
    return handle;
}

/// Free the library handle
export fn panel_clades_free(handle: ?*Handle) void {
    const h = handle orelse return;
    const allocator = h.allocator;

    // Clean up resources
    h.initialized = false;

    allocator.destroy(h);
    clearError();
}

//==============================================================================
// Core Operations
//==============================================================================

/// Process data (example operation)
export fn panel_clades_process(handle: ?*Handle, input: u32) Result {
    const h = handle orelse {
        setError("Null handle");
        return .null_pointer;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return .@"error";
    }

    // Example processing logic
    _ = input;

    clearError();
    return .ok;
}

//==============================================================================
// Clade-Specific Operations
//==============================================================================

/// Load a clade definition by its string identifier.
/// Returns a Result code indicating success or failure.
export fn panel_clades_load_clade(handle: ?*Handle, clade_id: ?[*:0]const u8) Result {
    const h = handle orelse {
        setError("Null handle");
        return .null_pointer;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return .@"error";
    }

    const id = clade_id orelse {
        setError("Null clade identifier");
        return .invalid_param;
    };

    const id_str = std.mem.span(id);
    if (id_str.len == 0) {
        setError("Empty clade identifier");
        return .invalid_param;
    }

    // TODO: store clade definition internally (id_str validated above)

    clearError();
    return .ok;
}

/// Query the traits/capabilities of a clade kind.
/// Returns a heap-allocated, null-terminated string describing the traits,
/// or null on failure.  The caller must free via panel_clades_free_string.
export fn panel_clades_query_traits(handle: ?*Handle, kind_tag: u32) ?[*:0]const u8 {
    const h = handle orelse {
        setError("Null handle");
        return null;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return null;
    }

    const kind: CladeKind = std.meta.intToEnum(CladeKind, kind_tag) catch {
        setError("Invalid clade kind tag");
        return null;
    };

    // Return a trait descriptor for each kind
    const description: []const u8 = switch (kind) {
        .directive => "orchestration,command-dispatch",
        .scanner => "code-analysis,linting",
        .builder => "compilation,build-pipeline",
        .database => "persistent-storage,query",
        .network => "http,sockets,protocol",
        .viewer => "read-only,preview,display",
        .ai => "llm,ml-inference",
        .loader => "asset-loading,resource-management",
        .meta => "workspace-metadata,configuration",
        .service => "background-service,daemon",
        .inspector => "runtime-introspection,debugging",
        .bridge => "cross-system,translation",
        .terminal => "interactive-shell,repl",
    };

    const result = h.allocator.dupeZ(u8, description) catch {
        setError("Failed to allocate trait string");
        return null;
    };

    clearError();
    return result.ptr;
}

/// Return the number of clade kinds known to this library.
/// Must equal CLADE_KIND_COUNT (13).  Used by the Idris2 layer to
/// verify ABI consistency at runtime.
export fn panel_clades_clade_kind_count() u32 {
    return CLADE_KIND_COUNT;
}

//==============================================================================
// String Operations
//==============================================================================

/// Get a string result (example)
/// Caller must free the returned string
export fn panel_clades_get_string(handle: ?*Handle) ?[*:0]const u8 {
    const h = handle orelse {
        setError("Null handle");
        return null;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return null;
    }

    // Example: allocate and return a string
    const result = h.allocator.dupeZ(u8, "Example result") catch {
        setError("Failed to allocate string");
        return null;
    };

    clearError();
    return result.ptr;
}

/// Free a string allocated by the library
export fn panel_clades_free_string(str: ?[*:0]const u8) void {
    const s = str orelse return;
    const allocator = std.heap.c_allocator;

    const slice = std.mem.span(s);
    allocator.free(slice);
}

//==============================================================================
// Array/Buffer Operations
//==============================================================================

/// Process an array of data
export fn panel_clades_process_array(
    handle: ?*Handle,
    buffer: ?[*]const u8,
    len: u32,
) Result {
    const h = handle orelse {
        setError("Null handle");
        return .null_pointer;
    };

    const buf = buffer orelse {
        setError("Null buffer");
        return .null_pointer;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return .@"error";
    }

    // Access the buffer
    const data = buf[0..len];
    _ = data;

    // Process data here

    clearError();
    return .ok;
}

//==============================================================================
// Error Handling
//==============================================================================

/// Get the last error message
/// Returns null if no error
export fn panel_clades_last_error() ?[*:0]const u8 {
    const err = last_error orelse return null;

    // Return C string (static storage, no need to free)
    const allocator = std.heap.c_allocator;
    const c_str = allocator.dupeZ(u8, err) catch return null;
    return c_str.ptr;
}

//==============================================================================
// Version Information
//==============================================================================

/// Get the library version
export fn panel_clades_version() [*:0]const u8 {
    return VERSION.ptr;
}

/// Get build information
export fn panel_clades_build_info() [*:0]const u8 {
    return BUILD_INFO.ptr;
}

//==============================================================================
// Callback Support
//==============================================================================

/// Callback function type (C ABI)
pub const Callback = *const fn (u64, u32) callconv(.c) u32;

/// Register a callback
export fn panel_clades_register_callback(
    handle: ?*Handle,
    callback: ?Callback,
) Result {
    const h = handle orelse {
        setError("Null handle");
        return .null_pointer;
    };

    const cb = callback orelse {
        setError("Null callback");
        return .null_pointer;
    };

    if (!h.initialized) {
        setError("Handle not initialized");
        return .@"error";
    }

    // Store callback for later use
    _ = cb;

    clearError();
    return .ok;
}

//==============================================================================
// Utility Functions
//==============================================================================

/// Check if handle is initialized
export fn panel_clades_is_initialized(handle: ?*Handle) u32 {
    const h = handle orelse return 0;
    return if (h.initialized) 1 else 0;
}

//==============================================================================
// Tests
//==============================================================================

test "lifecycle" {
    const handle = panel_clades_init() orelse return error.InitFailed;
    defer panel_clades_free(handle);

    try std.testing.expect(panel_clades_is_initialized(handle) == 1);
}

test "error handling" {
    const result = panel_clades_process(null, 0);
    try std.testing.expectEqual(Result.null_pointer, result);

    const err = panel_clades_last_error();
    try std.testing.expect(err != null);
}

test "version" {
    const ver = panel_clades_version();
    const ver_str = std.mem.span(ver);
    try std.testing.expectEqualStrings(VERSION, ver_str);
}

test "clade kind count" {
    try std.testing.expectEqual(@as(u32, 13), panel_clades_clade_kind_count());
}

test "query traits" {
    const handle = panel_clades_init() orelse return error.InitFailed;
    defer panel_clades_free(handle);

    // Query traits for each clade kind (0..12)
    var i: u32 = 0;
    while (i < CLADE_KIND_COUNT) : (i += 1) {
        const traits = panel_clades_query_traits(handle, i);
        try std.testing.expect(traits != null);
        // Free the returned string
        panel_clades_free_string(traits);
    }

    // Out-of-range kind should return null
    const bad = panel_clades_query_traits(handle, 99);
    try std.testing.expect(bad == null);
}

test "load clade" {
    const handle = panel_clades_init() orelse return error.InitFailed;
    defer panel_clades_free(handle);

    // Valid clade id
    const result = panel_clades_load_clade(handle, "test-clade");
    try std.testing.expectEqual(Result.ok, result);

    // Null clade id
    const null_result = panel_clades_load_clade(handle, null);
    try std.testing.expectEqual(Result.invalid_param, null_result);
}
