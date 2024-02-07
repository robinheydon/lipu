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

pub fn parse (self: *Lipu, iter: *TokenIter, file: FileIndex) !void
{
    const index = try self.tree.append (null, .document, 0, file);

    while (iter.next ()) |tk|
    {
        switch (tk.kind)
        {
            .comment => {},
            .open_block => {
                const blk_index = try self.tree.append (index, tk.kind, tk.index, file);
                try parse_block (self, blk_index, iter, file);
            },
            .close_block => {
                log.err ("Found '}}' without matching '{{'\n  {}", .{tk});
                _ = try self.tree.append (index, tk.kind, tk.index, file);
            },
            else =>
            {
                _ = try self.tree.append (index, tk.kind, tk.index, file);
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn parse_block (self: *Lipu, parent: NodeIndex, iter: *TokenIter, file: FileIndex) !void
{
    while (iter.next ()) |tk|
    {
        switch (tk.kind)
        {
            .comment => {},
            .open_block => {
                const blk_index = try self.tree.append (parent, tk.kind, tk.index, file);
                try parse_block (self, blk_index, iter, file);
            },
            .close_block => {
                _ = try self.tree.append (parent, tk.kind, tk.index, file);
                return;
            },
            else =>
            {
                _ = try self.tree.append (parent, tk.kind, tk.index, file);
            }
        }
    }
    const parent_token = self.tree.nodes.items[parent];
    log.err ("Found '{{' without matching '}}'\n  {}", .{parent_token.index});
}

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

    try std.testing.expectFmt (trimmed_expected, "{s}", .{trimmed_output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "parse: hello"
{
    const content = "Hello, World\n";

    const expected =
        \\info    : Tree
        \\        :   document
        \\        :     letter "Hello"
        \\        :     comma ","
        \\        :     space " "
        \\        :     letter "World"
        \\        :     end_of_line
        ;

    try test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
