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
const Tree = tree_zig.Tree;
const NodeIndex = tree_zig.NodeIndex;

const token_zig = @import ("token.zig");
const TokenIter = token_zig.TokenIter;

const testing_zig = @import ("testing.zig");
const test_parse = testing_zig.test_parse;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn parse (lipu: *Lipu, iter: *TokenIter, file: FileIndex) !Tree
{
    var tree = Tree.init (lipu.allocator, lipu);

    const index = try tree.append (null, .document, 0, file);

    while (iter.next ()) |tk|
    {
        switch (tk.kind)
        {
            .comment => {},
            .open_block => {
                const blk_index = try tree.append (index, tk.kind, tk.index, file);
                try parse_block (&tree, blk_index, iter, file);
            },
            .close_block => {
                log.err ("Found '}}' without matching '{{'\n  {}", .{tk});
                _ = try tree.append (index, tk.kind, tk.index, file);
            },
            else =>
            {
                _ = try tree.append (index, tk.kind, tk.index, file);
            }
        }
    }

    return tree;
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn parse_block (tree: *Tree, parent: NodeIndex, iter: *TokenIter, file: FileIndex) !void
{
    while (iter.next ()) |tk|
    {
        switch (tk.kind)
        {
            .comment => {},
            .open_block => {
                const blk_index = try tree.append (parent, tk.kind, tk.index, file);
                try parse_block (tree, blk_index, iter, file);
            },
            .close_block => {
                _ = try tree.append (parent, tk.kind, tk.index, file);
                return;
            },
            else =>
            {
                _ = try tree.append (parent, tk.kind, tk.index, file);
            }
        }
    }
    const item = tree.nodes.items[parent];
    const slice = tree.owner.getSlice (item.file, item.index);
    log.err ("Found '{{' without matching '}}'\n  {s} \"{}\"", .{@tagName (item.kind), std.zig.fmtEscapes (slice),});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "parse: hello"
{
    const content = "Hello, World\n";

    const expected =
        \\info    : document
        \\        :   letter "Hello"
        \\        :   comma ","
        \\        :   space " "
        \\        :   letter "World"
        \\        :   end_of_line
        ;

    try test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "parse: blocks"
{
    const content = "1{2,3}4";

    const expected =
        \\info    : document
        \\        :   digit "1"
        \\        :   open_block "{"
        \\        :     digit "2"
        \\        :     comma ","
        \\        :     digit "3"
        \\        :     close_block "}"
        \\        :   digit "4"
        ;

    try test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "parse: nested blocks"
{
    const content = "1{2{3,4}5{6,7}8}9";

    const expected =
        \\info    : document
        \\        :   digit "1"
        \\        :   open_block "{"
        \\        :     digit "2"
        \\        :     open_block "{"
        \\        :       digit "3"
        \\        :       comma ","
        \\        :       digit "4"
        \\        :       close_block "}"
        \\        :     digit "5"
        \\        :     open_block "{"
        \\        :       digit "6"
        \\        :       comma ","
        \\        :       digit "7"
        \\        :       close_block "}"
        \\        :     digit "8"
        \\        :     close_block "}"
        \\        :   digit "9"
        ;

    try test_parse (content, expected);
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
        \\info    : document
        \\        :   digit "1"
        \\        :   close_block "}"
        ;

    try test_parse (content, expected);
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
        \\info    : document
        \\        :   digit "1"
        \\        :   open_block "{"
        \\        :     digit "2"
        ;

    try test_parse (content, expected);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
