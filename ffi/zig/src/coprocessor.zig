// SPDX-License-Identifier: PMPL-1.0-or-later
//
// PanLL Coprocessor FFI — Zig shared library for local compute dispatch.
//
// Exports a C-compatible ABI consumed by the Rust/Tauri host via libloading:
//   - copro_init()     — Initialise the coprocessor library.
//   - copro_deinit()   — Tear down and release resources.
//   - copro_dispatch() — Dispatch a computation to a backend.
//   - copro_free()     — Free a result string allocated by copro_dispatch.
//
// Backend IDs (u8) match the ReScript CoprocessorsModel variants:
//   0=Maths, 1=Vector, 2=Tensor, 3=Physics, 4=Crypto,
//   5=Neural, 6=Quantum, 7=Audio, 8=Graphics, 9=IO
//
// Build:  zig build          (produces libpanll_copro.so)
// Test:   zig build test

const std = @import("std");

// ---------------------------------------------------------------------------
// Backend identifiers — must stay in sync with Rust CoproBackend and
// ReScript coprocessorBackend.
// ---------------------------------------------------------------------------

/// Coprocessor backend identifiers.
pub const Backend = enum(u8) {
    maths = 0,
    vector = 1,
    tensor = 2,
    physics = 3,
    crypto = 4,
    neural = 5,
    quantum = 6,
    audio = 7,
    graphics = 8,
    io = 9,
    _,
};

// ---------------------------------------------------------------------------
// Internal state
// ---------------------------------------------------------------------------

/// Whether copro_init has been called.
var initialised: bool = false;

/// General-purpose allocator for result strings returned to the host.
/// We use the page allocator because it is simple, thread-safe, and does
/// not require a backing buffer.
var gpa = std.heap.page_allocator;

// ---------------------------------------------------------------------------
// Exported C ABI functions
// ---------------------------------------------------------------------------

/// Initialise the coprocessor library.
///
/// Returns 0 on success, non-zero on failure.
/// Safe to call multiple times (idempotent).
export fn copro_init() callconv(.C) i32 {
    if (initialised) return 0;
    initialised = true;
    // Future: initialise SIMD detection, thread pool, GPU context, etc.
    return 0;
}

/// Tear down the coprocessor library and release any held resources.
///
/// Safe to call even if `copro_init` was not called.
export fn copro_deinit() callconv(.C) void {
    initialised = false;
    // Future: release GPU contexts, join thread pool, etc.
}

/// Dispatch a computation to a backend.
///
/// # Parameters
/// - `backend`  — Backend ID (0–9). See `Backend` enum.
/// - `op`       — Null-terminated C string: operation name (e.g. "matrix_multiply").
/// - `payload`  — Null-terminated C string: JSON-encoded payload.
///
/// # Returns
/// A heap-allocated, null-terminated C string containing the JSON result.
/// The caller MUST free it with `copro_free`.
/// Returns a JSON error object if the backend or operation is unknown.
export fn copro_dispatch(
    backend: u8,
    op: [*c]const u8,
    payload: [*c]const u8,
) callconv(.C) [*c]u8 {
    const op_slice = span_from_c(op);
    const payload_slice = span_from_c(payload);

    const backend_enum: Backend = @enumFromInt(backend);

    const result_json = switch (backend_enum) {
        .maths => dispatch_maths(op_slice, payload_slice),
        .vector => dispatch_vector(op_slice, payload_slice),
        .tensor => dispatch_tensor(op_slice, payload_slice),
        .physics => dispatch_physics(op_slice, payload_slice),
        .crypto => dispatch_crypto(op_slice, payload_slice),
        .neural => dispatch_neural(op_slice, payload_slice),
        .quantum => dispatch_quantum(op_slice, payload_slice),
        .audio => dispatch_audio(op_slice, payload_slice),
        .graphics => dispatch_graphics(op_slice, payload_slice),
        .io => dispatch_io(op_slice, payload_slice),
        _ => error_json("unknown_backend", "Backend ID out of range"),
    };

    return alloc_c_string(result_json);
}

/// Free a result string previously returned by `copro_dispatch`.
///
/// Passing a null pointer is a safe no-op.
export fn copro_free(ptr: [*c]u8) callconv(.C) void {
    if (ptr == null) return;
    // We allocated with page_allocator using alloc_c_string.
    // Since page_allocator does not track individual allocations in a way
    // that allows single-pointer free, we use a sentinel approach:
    // the result strings are small enough that leaking in a stub is acceptable.
    // TODO: Switch to ArenaAllocator or GeneralPurposeAllocator for proper free.
    _ = ptr;
}

// ---------------------------------------------------------------------------
// Backend dispatch stubs — each returns a JSON string.
// These are minimal stubs; actual compute logic will be filled in later.
// ---------------------------------------------------------------------------

/// Maths backend: arithmetic, linear algebra, number theory.
fn dispatch_maths(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"maths\",\"status\":\"stub\",\"result\":null,\"message\":\"Maths backend stub — compute logic pending\"}";
}

/// Vector backend: vector operations, dot products, norms.
fn dispatch_vector(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"vector\",\"status\":\"stub\",\"result\":null,\"message\":\"Vector backend stub — SIMD dispatch pending\"}";
}

/// Tensor backend: tensor contractions, reshaping, broadcasting.
fn dispatch_tensor(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"tensor\",\"status\":\"stub\",\"result\":null,\"message\":\"Tensor backend stub — layout engine pending\"}";
}

/// Physics backend: rigid body, collision detection, fluid dynamics.
fn dispatch_physics(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"physics\",\"status\":\"stub\",\"result\":null,\"message\":\"Physics backend stub — simulation engine pending\"}";
}

/// Crypto backend: hashing, encryption, key derivation.
fn dispatch_crypto(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"crypto\",\"status\":\"stub\",\"result\":null,\"message\":\"Crypto backend stub — primitives pending\"}";
}

/// Neural backend: inference, activation functions, layer dispatch.
fn dispatch_neural(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"neural\",\"status\":\"stub\",\"result\":null,\"message\":\"Neural backend stub — inference engine pending\"}";
}

/// Quantum backend: gate simulation, state vectors, measurement.
fn dispatch_quantum(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"quantum\",\"status\":\"stub\",\"result\":null,\"message\":\"Quantum backend stub — simulator pending\"}";
}

/// Audio backend: FFT, convolution, sample processing.
fn dispatch_audio(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"audio\",\"status\":\"stub\",\"result\":null,\"message\":\"Audio backend stub — DSP pipeline pending\"}";
}

/// Graphics backend: shader dispatch, rasterisation helpers.
fn dispatch_graphics(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"graphics\",\"status\":\"stub\",\"result\":null,\"message\":\"Graphics backend stub — render pipeline pending\"}";
}

/// IO backend: async file operations, network helpers.
fn dispatch_io(op: []const u8, _payload: []const u8) []const u8 {
    _ = op;
    return "{\"backend\":\"io\",\"status\":\"stub\",\"result\":null,\"message\":\"IO backend stub — async dispatch pending\"}";
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Convert a C null-terminated string pointer to a Zig slice.
/// Returns an empty slice if the pointer is null.
fn span_from_c(ptr: [*c]const u8) []const u8 {
    if (ptr == null) return "";
    return std.mem.span(ptr);
}

/// Build a JSON error object as a string literal.
fn error_json(code: []const u8, message: []const u8) []const u8 {
    // For stubs, we return compile-time known strings.
    // In production, this would use fmt to build dynamic JSON.
    _ = code;
    _ = message;
    return "{\"error\":true,\"code\":\"unknown\",\"message\":\"Unsupported backend or operation\"}";
}

/// Allocate a null-terminated C string copy of a Zig slice.
///
/// The caller must free the result with `copro_free`.
/// On allocation failure, returns a static error string (never null).
fn alloc_c_string(slice: []const u8) [*c]u8 {
    const buf = gpa.alloc(u8, slice.len + 1) catch {
        // Allocation failure — return a static error string.
        // This is safe because the caller will try to free it,
        // and copro_free is a no-op for this stub.
        return @constCast(@ptrCast("{\"error\":true,\"message\":\"allocation failed\"}"));
    };
    @memcpy(buf[0..slice.len], slice);
    buf[slice.len] = 0; // Null terminator.
    return @ptrCast(buf.ptr);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "copro_init returns 0" {
    const rc = copro_init();
    try std.testing.expectEqual(@as(i32, 0), rc);
}

test "copro_init is idempotent" {
    _ = copro_init();
    const rc = copro_init();
    try std.testing.expectEqual(@as(i32, 0), rc);
}

test "copro_dispatch returns valid JSON for maths backend" {
    _ = copro_init();
    const result = copro_dispatch(0, "test_op", "{}");
    const slice = span_from_c(result);
    try std.testing.expect(slice.len > 0);
    try std.testing.expect(std.mem.startsWith(u8, slice, "{"));
}

test "copro_dispatch returns error for invalid backend" {
    _ = copro_init();
    const result = copro_dispatch(255, "test_op", "{}");
    const slice = span_from_c(result);
    try std.testing.expect(std.mem.indexOf(u8, slice, "error") != null);
}

test "copro_deinit does not crash" {
    copro_deinit();
}

test "copro_free null is safe" {
    copro_free(null);
}
