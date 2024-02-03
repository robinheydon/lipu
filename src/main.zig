const std = @import("std");
const lipu = @import ("lipu");

const command_line_parser = @import ("command_line_parser.zig");

const log = lipu.log;

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

    log.init (.{
        .allocator = allocator,
    });

    if (options.d_args)
    {
        log.info("{n}", .{options});
    }

    log.info("lipu", .{});
    log.info("version: {}", .{lipu.version});

    var ast = try lipu.parse (allocator, .{
        .debug_tokens = options.d_tokens,
        .filename = options.inputs.items[0],
    });
    defer ast.deinit ();
}

test "main test" {
    _ = @import ("command_line_parser.zig");
}

test "lipu testing" {
    _ = @import ("lipu");
}
