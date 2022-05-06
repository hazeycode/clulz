const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("clulz", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const example = b.addExecutable("example", "src/example.zig");
    example.setBuildMode(mode);
    example.install();

    const example_run_step = example.run();
    example_run_step.step.dependOn(b.getInstallStep());

    const run = b.step("example", "Build and run example");
    run.dependOn(&example_run_step.step);
}
