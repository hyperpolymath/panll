// {{PROJECT}} FFI Build Configuration
// SPDX-License-Identifier: PMPL-1.0-or-later

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Root module shared by the library/test artifacts (Zig 0.15 API).
    const root_mod = b.createModule(.{
            .link_libc = true,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Shared library (.so, .dylib, .dll)
    const lib = b.addLibrary(.{
        .name = "panel_clades",
        .linkage = .dynamic,
        .root_module = root_mod,
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
    });

    // Static library (.a)
    const lib_static = b.addLibrary(.{
        .name = "panel_clades",
        .linkage = .static,
        .root_module = root_mod,
    });

    // Install artifacts
    b.installArtifact(lib);
    b.installArtifact(lib_static);

    // Install the C header (Zig 0.15 API).
    const header = b.addInstallFileWithDir(
        b.path("include/panel_clades.h"),
        .header,
        "panel_clades.h",
    );
    b.getInstallStep().dependOn(&header.step);

    // Unit tests
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .link_libc = true,
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);

    // Integration tests
    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .link_libc = true,
            .root_source_file = b.path("test/integration_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    integration_tests.linkLibrary(lib);

    const run_integration_tests = b.addRunArtifact(integration_tests);

    const integration_test_step = b.step("test-integration", "Run integration tests");
    integration_test_step.dependOn(&run_integration_tests.step);

    // Documentation
    const docs = b.addTest(.{
        .root_module = b.createModule(.{
            .link_libc = true,
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .Debug,
        }),
    });

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&b.addInstallDirectory(.{
        .source_dir = docs.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    }).step);

    // Benchmark (if needed)
    const bench = b.addExecutable(.{
        .name = "panel_clades-bench",
        .root_module = b.createModule(.{
            .link_libc = true,
            .root_source_file = b.path("bench/bench.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        }),
    });

    bench.linkLibrary(lib);

    const run_bench = b.addRunArtifact(bench);

    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&run_bench.step);
}
