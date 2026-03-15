// SPDX-License-Identifier: PMPL-1.0-or-later
//
// PanLL Coprocessor FFI — Zig build configuration.
//
// Produces: libpanll_copro.so (Linux), libpanll_copro.dylib (macOS),
//           panll_copro.dll (Windows).
//
// Usage:
//   zig build                 — Build the shared library (debug).
//   zig build -Doptimize=ReleaseFast — Build optimised for production.
//   zig build test            — Run unit tests.
//
// Output: zig-out/lib/libpanll_copro.so

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // -- Shared library: libpanll_copro --
    const lib = b.addSharedLibrary(.{
        .name = "panll_copro",
        .root_source_file = b.path("src/coprocessor.zig"),
        .target = target,
        .optimize = optimize,
        // Ensure C ABI exports are visible.
        .version = .{ .major = 0, .minor = 2, .patch = 0 },
    });

    // Link libc for C ABI compatibility.
    lib.linkLibC();

    // Install the library to zig-out/lib/.
    b.installArtifact(lib);

    // -- Unit tests --
    const tests = b.addTest(.{
        .root_source_file = b.path("src/coprocessor.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run coprocessor FFI unit tests");
    test_step.dependOn(&run_tests.step);
}
