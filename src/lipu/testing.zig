///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import ("std");

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const log = @import ("log.zig");

const lipu = @import ("lipu.zig");
const Lipu = lipu.Lipu;
const FileIndex = lipu.FileIndex;

const tree = @import ("tree.zig");
const NodeIndex = tree.NodeIndex;

const token = @import ("token.zig");
const TokenIter = token.TokenIter;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn test_parse (input_text: []const u8, expected: []const u8) !void
{
    var doc = try lipu.init (.{
        .allocator = std.testing.allocator,
    });
    defer std.testing.allocator.destroy (doc);
    defer doc.deinit ();

    try log.init (.{
        .allocator = std.testing.allocator,
    });
    defer log.deinit ();

    log.startTest ();

    const content = try std.testing.allocator.dupe (u8, input_text);

    try doc.include (content, "test.lipu");

    const dump = try doc.dump (std.testing.allocator);
    defer std.testing.allocator.free (dump);
    log.info ("{s}", .{dump});

    const output = log.endTest ();

    const trimmed_expected = std.mem.trim (u8, expected, "\r\n \t");
    const trimmed_output = std.mem.trim (u8, output, "\r\n \t");

    if (std.mem.eql (u8, trimmed_expected, trimmed_output))
    {
        return;
    }

    var expected_lines = std.mem.splitAny (u8, trimmed_expected, "\n");
    var output_lines = std.mem.splitAny (u8, trimmed_output, "\n");
    var count : usize = 0;

    std.debug.print ("\n====== expected ======================================================= :: output ===================================\n", .{});

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
                    std.debug.print ("{d:5}: {s:<64} == {s}\n", .{count, el, ol});
                }
                else
                {
                    std.debug.print ("{d:5}: {s:<64} <> {s}\n", .{count, el, ol});
                }
            }
            else
            {
                std.debug.print ("{d:5}: {s:<64} <<\n", .{count, el});
            }
        }
        else
        {
            if (output_line) |ol|
            {
                std.debug.print ("{d:5}: {s:<64} >> {s}\n", .{count, "", ol});
            }
        }
    }

    std.debug.print ("------ expected ------------------------------------------------------- :: output -----------------------------------\n", .{});
    return error.TextExpectedEqual;
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
