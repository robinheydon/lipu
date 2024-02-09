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

    try log.init (.{
        .allocator = allocator,
        .verbosity = options.verbosity,
        .quiet = options.quiet,
        .filename = options.log_filename,
    });
    defer log.deinit ();

    if (options.d_args)
    {
        log.info("{n}", .{options});
    }

    log.info("lipu v{}", .{lipu.version});

    var doc = try lipu.create (.{
        .allocator = allocator,
        .debug_tokens = options.d_tokens,
    });
    defer doc.destroy ();

    if (options.inputs.items.len == 0)
    {
        log.err ("No input file\n", .{});
        return;
    }
    else if (options.inputs.items.len > 1)
    {
        log.err ("Too many input files\n", .{});
        return;
    }

    var parse_tree = doc.import (options.inputs.items[0]) catch |err|
    {
        switch (err)
        {
            error.FileNotFound => {
                log.err ("File \"{}\" not found", .{ std.zig.fmtEscapes (options.inputs.items[0]) });
                return;
            },
            else => return err
        }
    };
    defer parse_tree.deinit ();

    {
        var buffer = std.ArrayList (u8).init (allocator);
        defer buffer.deinit ();
        const writer = buffer.writer ();
        try parse_tree.dump (writer);
        log.info ("{s}", .{buffer.items});
    }

    {
        const dump = try doc.dump ();
        defer allocator.free (dump);
        log.info ("{s}", .{dump});
    }
}

test "main test" {
    _ = @import ("command_line_parser.zig");
}

test "lipu testing" {
    _ = @import ("lipu");
}
