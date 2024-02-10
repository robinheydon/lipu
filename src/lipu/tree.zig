///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import ("std");

const log = @import ("log.zig");

const token_zig = @import ("token.zig");
const TokenKind = token_zig.TokenKind;
const TokenIndex = token_zig.TokenIndex;

const lipu_zig = @import ("lipu.zig");
const Lipu = lipu_zig.Lipu;
const FileIndex = lipu_zig.FileIndex;

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
    owner: *Lipu,

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn init (allocator: std.mem.Allocator, owner: *Lipu) Tree
    {
        return .{
            .nodes = std.ArrayList (Node).init (allocator),
            .owner = owner,
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

    pub const IndexNode = struct
    {
        index: NodeIndex,
        node: Node,
    };

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub const Iterator = struct
    {
        tree: *const Tree,
        index: NodeIndex,

        pub fn next (self: *Iterator) ?IndexNode
        {
            if (self.index < self.tree.nodes.items.len)
            {
                const index = self.index;
                const node = self.tree.nodes.items[self.index];

                if (node.next_sibling == 0)
                {
                    self.index = @truncate (self.tree.nodes.items.len);
                }
                else
                {
                    self.index = node.next_sibling;
                }

                return .{
                    .node = node,
                    .index = index,
                };
            }
            return null;
        }

        pub fn children (self: *Iterator, index: NodeIndex) @This()
        {
            if (index < self.tree.nodes.items.len)
            {
                const node = self.tree.nodes.items[index];

                if (node.first_child != 0)
                {
                    return .{
                        .tree = self.tree,
                        .index = node.first_child,
                    };
                }
            }
            return .{
                .tree = self.tree,
                .index = @truncate (self.tree.nodes.items.len),
            };
        }
    };

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn iterator (self: *const Tree, index: NodeIndex) Iterator
    {
        return .{
            .tree = self,
            .index = index,
        };
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn dump (self: Tree, writer: anytype) !void
    {
        try self.dump_node (0, 0, false, writer);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn dump_node (self: Tree, index: NodeIndex, depth: usize, newline: bool, writer: anytype) !void
    {
        var need_newline = newline;
        var i = index;
        while (i < self.nodes.items.len)
        {
            const item = self.nodes.items[i];

            switch (item.kind)
            {
                .document, .end_of_line => {
                    if (need_newline)
                    {
                        try writer.writeAll ("\n");
                    }
                    try writer.print ("{s}{s}", .{
                        lots_of_spaces[0..depth*2],
                        @tagName (item.kind)
                    });
                },
                else => {
                    if (need_newline)
                    {
                        try writer.writeAll ("\n");
                    }
                    const slice = self.owner.getSlice (item.file, item.index);
                    try writer.print ("{s}{s} \"{}\"", .{
                        lots_of_spaces[0..depth*2],
                        @tagName (item.kind),
                        std.zig.fmtEscapes (slice)
                    });
                }
            }


            if (item.first_child != 0)
            {
                try self.dump_node (item.first_child, depth+1, true, writer);
            }
            if (item.next_sibling == 0)
            {
                break;
            }

            i = item.next_sibling;
            need_newline = true;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
