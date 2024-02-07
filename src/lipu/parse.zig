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

test "parse: hello"
{
    var doc = try lipu.init (.{
        .allocator = std.testing.allocator,
    });
    defer doc.deinit ();
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
