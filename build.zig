///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import("std");

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

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

    const main_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
        .name = "main",
    });

    main_unit_tests.root_module.addImport ("lipu", lipu);
    const run_main_unit_tests = b.addRunArtifact(main_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lipu_unit_tests.step);
    test_step.dependOn(&run_main_unit_tests.step);

    std.fs.cwd ().makeDir ("kcov-out") catch {};

    const remove_kcov_main_directory = b.addRemoveDirTree ("kcov-out/main");
    const kcov_main_unit_tests = b.addSystemCommand (&.{
        "kcov",
        "--collect-only",
        "kcov-out/main",
        "--exclude-path=/snap/zig",
    });
    kcov_main_unit_tests.addArtifactArg (main_unit_tests);
    kcov_main_unit_tests.step.dependOn (&remove_kcov_main_directory.step);

    const remove_kcov_lipu_directory = b.addRemoveDirTree ("kcov-out/lipu");
    const kcov_lipu_unit_tests = b.addSystemCommand (&.{
        "kcov",
        "--collect-only",
        "kcov-out/lipu",
        "--exclude-path=/snap/zig",
    });
    kcov_lipu_unit_tests.addArtifactArg (lipu_unit_tests);
    kcov_lipu_unit_tests.step.dependOn (&remove_kcov_lipu_directory.step);

    const merge_coverage_results = b.addSystemCommand (&.{
        "kcov",
        "--merge",
        "kcov-out/coverage",
        "kcov-out/main",
        "kcov-out/lipu",
    });
    merge_coverage_results.step.dependOn (&kcov_main_unit_tests.step);
    merge_coverage_results.step.dependOn (&kcov_lipu_unit_tests.step);

    const coverage_step = b.step ("coverage", "Run coverage unit tests");
    coverage_step.dependOn (&merge_coverage_results.step);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

fn show_coverage_summary (b: *std.Build.Step, progress: *std.Progress.Node) !void
{
    _ = b;
    _ = progress;

    std.debug.print ("Show Coverage Summary\n", .{});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const OutputFileContents = struct
{
    step: std.Build.Step,
    output: std.Build.LazyPath,

    pub fn create (owner: *std.Build, name: []const u8, output: std.Build.LazyPath) *OutputFileContents {
        const self = owner.allocator.create (OutputFileContents) catch @panic ("OOM");
        self.* = .{
            .step = std.Build.Step.init (.{
                .id = .custom,
                .name = name,
                .owner = owner,
                .makeFn = make,
            }),
            .output = output,
        };
        return self;
    }

    fn make (step: *std.Build.Step, prog_node: *std.Progress.Node) !void
    {
        const b = step.owner;
        const self = @fieldParentPtr(OutputFileContents, "step", step);
        _ = prog_node;

        const cwd = std.fs.cwd ();
        const content = try cwd.readFileAlloc (b.allocator, self.output.generated.path.?, std.math.maxInt (usize));
        std.debug.print ("{s}\n", .{content});
    }
};
