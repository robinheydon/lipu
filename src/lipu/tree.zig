///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import ("std");

const log = @import ("log.zig");

const token = @import ("token.zig");
const TokenKind = token.TokenKind;
const TokenIndex = token.TokenIndex;

const lipu = @import ("lipu.zig");
const Lipu = lipu.Lipu;
const FileIndex = lipu.FileIndex;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const lots_of_spaces = " "**128;

pub const NodeIndex = u32;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const Node = struct
{
    kind: TokenKind, // kind of token
    file: FileIndex, // which file
    index: TokenIndex = 0, // index into file content
    first_child: NodeIndex = 0, // first child
    last_child: NodeIndex = 0, // last child
    next_sibling: NodeIndex = 0, // next sibling
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const Tree = struct
{
    nodes: std.ArrayList (Node),
    lipu: *Lipu,

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn init (allocator: std.mem.Allocator, owner: *Lipu) Tree
    {
        return .{
            .nodes = std.ArrayList (Node).init (allocator),
            .lipu = owner,
        };
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn deinit (self: *Tree) void
    {
        self.nodes.deinit ();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn append (self: *Tree, parent: ?NodeIndex, kind: TokenKind, index: TokenIndex, file: FileIndex) !NodeIndex
    {
        const new_index : NodeIndex = @truncate (self.nodes.items.len);

        try self.nodes.append (.{
            .kind = kind,
            .file = file,
            .index = index,
        });

        if (parent) |parent_index|
        {
            var parent_node = &self.nodes.items[parent_index];
            if (parent_node.first_child == 0)
            {
                parent_node.first_child = new_index;
                parent_node.last_child = new_index;
            }
            else
            {
                var last_child = &self.nodes.items[parent_node.last_child];
                last_child.next_sibling = new_index;
                parent_node.last_child = new_index;
            }
        }

        return new_index;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn dump (self: Tree, writer: anytype) !void
    {
        try writer.writeAll ("Tree");

        try self.dump_node (0, 1, writer);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn dump_node (self: Tree, index: NodeIndex, depth: usize, writer: anytype) !void
    {
        var i = index;
        while (true)
        {
            const item = self.nodes.items[i];

            switch (item.kind)
            {
                .document, .end_of_line => {
                    try writer.print ("\n{s}{s}", .{
                        lots_of_spaces[0..depth*2],
                        @tagName (item.kind)
                    });
                },
                else => {
                    const slice = self.lipu.getSlice (item.file, item.index);
                    try writer.print ("\n{s}{s} \"{}\"", .{
                        lots_of_spaces[0..depth*2],
                        @tagName (item.kind),
                        std.zig.fmtEscapes (slice)
                    });
                }
            }


            if (item.first_child != 0)
            {
                try self.dump_node (item.first_child, depth+1, writer);
            }
            if (item.next_sibling == 0)
            {
                break;
            }

            i = item.next_sibling;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
