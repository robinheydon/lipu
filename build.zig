const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "lipu",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const lipu = b.addModule ("lipu", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/lipu/lipu.zig" },
    });

    exe.root_module.addImport ("lipu", lipu);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lipu_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/lipu/lipu.zig" },
        .target = target,
        .optimize = optimize,
        .name = "lipu",
    });

    const run_lipu_unit_tests = b.addRunArtifact(lipu_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
        .name = "main",
    });

    exe_unit_tests.root_module.addImport ("lipu", lipu);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lipu_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);

    std.fs.cwd ().makeDir ("kcov-out") catch {};

    const kcov_exe_unit_tests = b.addSystemCommand (&.{
        "kcov",
        "--collect-only",
        "kcov-out/main",
        "--exclude-path=/snap/zig",
    });
    _ = kcov_exe_unit_tests.captureStdErr ();
    kcov_exe_unit_tests.addArtifactArg (exe_unit_tests);

    const kcov_lipu_unit_tests = b.addSystemCommand (&.{
        "kcov",
        "--collect-only",
        "kcov-out/lipu",
        "--exclude-path=/snap/zig",
    });
    _ = kcov_lipu_unit_tests.captureStdErr ();
    kcov_lipu_unit_tests.addArtifactArg (lipu_unit_tests);

    const merge_coverage_results = b.addSystemCommand (&.{
        "kcov",
        "--merge",
        "kcov-out/coverage",
        "kcov-out/main",
        "kcov-out/lipu",
    });
    merge_coverage_results.step.dependOn (&kcov_exe_unit_tests.step);
    merge_coverage_results.step.dependOn (&kcov_lipu_unit_tests.step);

    const summary_results = b.addSystemCommand (&.{
        "python3",
        "tools/coverage.py",
        "kcov-out/coverage/kcov-merged",
    });
    const summary_stdout = summary_results.addOutputFileArg ("results.txt");
    summary_results.step.dependOn (&merge_coverage_results.step);

    _ = summary_stdout;
    var show_coverage_results = std.Build.Step.init(.{
        .id = .run,
        .name = "show coverage summary",
        .owner = b,
        .makeFn = show_coverage_summary,
    });
    show_coverage_results.dependOn (&summary_results.step);

    const coverage_step = b.step ("coverage", "Run coverage unit tests");
    coverage_step.dependOn (&show_coverage_results);
}

fn show_coverage_summary (b: *std.Build.Step, progress: *std.Progress.Node) !void
{
    _ = b;
    _ = progress;

    std.debug.print ("Show Coverage Summary\n", .{});
}
