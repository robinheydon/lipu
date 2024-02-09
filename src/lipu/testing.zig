///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import ("std");

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const log = @import ("log.zig");

const lipu_zig = @import ("lipu.zig");
const Lipu = lipu_zig.Lipu;
const FileIndex = lipu_zig.FileIndex;

const tree_zig = @import ("tree.zig");
const NodeIndex = tree_zig.NodeIndex;

const token_zig = @import ("token.zig");
const TokenIter = token_zig.TokenIter;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

fn compare_text (expected: []const u8, output: []const u8, writer: anytype) !void
{
    const trimmed_expected = std.mem.trim (u8, expected, "\r\n \t");
    const trimmed_output = std.mem.trim (u8, output, "\r\n \t");

    if (std.mem.eql (u8, trimmed_expected, trimmed_output))
    {
        return;
    }

    var expected_lines = std.mem.splitAny (u8, trimmed_expected, "\n");
    var output_lines = std.mem.splitAny (u8, trimmed_output, "\n");
    var count : usize = 0;

    try writer.print ("\n====== expected ======================================================= :: output ===================================\n", .{});

    while (true)
    {
        const expected_line = expected_lines.next ();
        const output_line = output_lines.next ();
        count += 1;

        if (expected_line == null and output_line == null)
        {
            break;
        }

        if (expected_line) |el|
        {
            if (output_line) |ol|
            {
                if (std.mem.eql (u8, el, ol))
                {
                    try writer.print ("{d:5}: {s:<64} == {s}\n", .{count, el, ol});
                }
                else
                {
                    try writer.print ("{d:5}: {s:<64} <> {s}\n", .{count, el, ol});
                }
            }
            else
            {
                try writer.print ("{d:5}: {s:<64} <<\n", .{count, el});
            }
        }
        else
        {
            if (output_line) |ol|
            {
                try writer.print ("{d:5}: {s:<64} >> {s}\n", .{count, "", ol});
            }
        }
    }

    try writer.print ("------ expected ------------------------------------------------------- :: output -----------------------------------\n", .{});

    return error.TextExpectedEqual;
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn test_parse (input_text: []const u8, expected: []const u8) !void
{
    var doc = try lipu_zig.create (.{
        .allocator = std.testing.allocator,
    });
    defer doc.destroy ();

    try log.init (.{
        .allocator = std.testing.allocator,
    });
    defer log.deinit ();

    log.startTest ();

    const content = try std.testing.allocator.dupe (u8, input_text);

    var tree = try doc.include (content, "test.lipu");
    defer tree.deinit ();

    var buffer = std.ArrayList (u8).init (std.testing.allocator);
    defer buffer.deinit ();
    const writer = buffer.writer ();
    try tree.dump (writer);
    log.info ("{s}", .{buffer.items});

    const output = log.endTest ();

    const stdout = std.io.getStdOut ();

    try compare_text (expected, output, stdout.writer ());
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "testing: same"
{
    var buffer = std.ArrayList (u8).init (std.testing.allocator);
    defer buffer.deinit ();
    const writer = buffer.writer ();

    try compare_text ("aaa", "aaa\n", writer);
    try compare_text ("aaa\n", "aaa", writer);
    try std.testing.expectError (
        error.TextExpectedEqual,
        compare_text ("aaa", "bbb", writer)
    );
    try std.testing.expectError (
        error.TextExpectedEqual,
        compare_text ("aaa\nbbb", "aaa", writer)
    );
    try std.testing.expectError (
        error.TextExpectedEqual,
        compare_text ("aaa", "aaa\nbbb", writer)
    );
    try std.testing.expectError (
        error.TextExpectedEqual,
        compare_text ("aaa\nccc", "aaa\nbbb", writer)
    );
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
