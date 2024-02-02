const std = @import("std");
const lipu = @import ("lipu");

const command_line_parser = @import ("command_line_parser.zig");

pub const std_options = struct {
    pub const log_level = .debug;
    pub const logFn = log_function;
};

pub fn log_function (
    comptime level: std.log.Level,
    comptime scope: @TypeOf (.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_prefix = "(" ++ @tagName (scope) ++ "): ";
    const prefix = "[" ++ comptime level.asText () ++ "]" ++ scope_prefix;
    std.debug.print (prefix ++ format ++ "\n", args);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator (.{}){};
    const allocator = gpa.allocator ();
    defer std.debug.assert (gpa.deinit () == .ok);

    var options = try command_line_parser.parseArgs (allocator);
    defer options.deinit ();

    if (options.errors.items.len > 0)
    {
        for (options.errors.items) |message|
        {
            std.debug.print("{s}\n", .{message});
        }

        std.process.exit (1);
    }

    if (options.d_args)
    {
        std.log.info("{n}\n", .{options});
    }

    var ast = try lipu.parse (allocator, .{
        .debug_tokens = options.d_tokens,
        .filename = options.inputs.items[0],
    });
    defer ast.deinit ();

    std.log.info("lipu\n", .{});
    std.log.info("{}\n", .{ast});

    std.log.info("version: {}\n", .{lipu.version});
}

test "main test" {
    _ = @import ("command_line_parser.zig");
}

test "lipu testing" {
    _ = @import ("lipu");
}
