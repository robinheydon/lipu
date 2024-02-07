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

const testing = @import ("testing.zig");

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
    const item = self.tree.nodes.items[parent];
    const slice = self.getSlice (item.file, item.index);
    log.err ("Found '{{' without matching '}}'\n  {s} \"{}\"", .{@tagName (item.kind), std.zig.fmtEscapes (slice),});
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

    try testing.test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "parse: blocks"
{
    const content = "1{2,3}4";

    const expected =
        \\info    : Tree
        \\        :   document
        \\        :     digit "1"
        \\        :     open_block "{"
        \\        :       digit "2"
        \\        :       comma ","
        \\        :       digit "3"
        \\        :       close_block "}"
        \\        :     digit "4"
        ;

    try testing.test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "parse: nested blocks"
{
    const content = "1{2{3,4}5{6,7}8}9";

    const expected =
        \\info    : Tree
        \\        :   document
        \\        :     digit "1"
        \\        :     open_block "{"
        \\        :       digit "2"
        \\        :       open_block "{"
        \\        :         digit "3"
        \\        :         comma ","
        \\        :         digit "4"
        \\        :         close_block "}"
        \\        :       digit "5"
        \\        :       open_block "{"
        \\        :         digit "6"
        \\        :         comma ","
        \\        :         digit "7"
        \\        :         close_block "}"
        \\        :       digit "8"
        \\        :       close_block "}"
        \\        :     digit "9"
        ;

    try testing.test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "parse: missing open block"
{
    const content = "1}";

    const expected =
        \\ERROR   : Found '}' without matching '{'
        \\        :   close_block "}"
        \\info    : Tree
        \\        :   document
        \\        :     digit "1"
        \\        :     close_block "}"
        ;

    try testing.test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "parse: missing close block"
{
    const content = "1{2";

    const expected =
        \\ERROR   : Found '{' without matching '}'
        \\        :   open_block "{"
        \\info    : Tree
        \\        :   document
        \\        :     digit "1"
        \\        :     open_block "{"
        \\        :       digit "2"
        ;

    try testing.test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
