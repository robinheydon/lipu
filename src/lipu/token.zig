const std = @import ("std");

pub const TokenKind = enum
{
    unknown,
};

pub const Token = struct
{
    kind: TokenKind,
    index: TokenIndex,
    slice: []const u8,
};

pub const TokenIter = struct
{
    content: []const u8,
    index: TokenIndex,

    pub fn next (self: TokenIter) ?Token
    {
        _ = self;
        return null;
    }
};

pub const TokenIndex = u32;

pub fn tokenize (content: []const u8) TokenIter
{
    return .{
        .content = content,
        .index = 0,
    };
}

test "simple"
{
    const input = "Hello, World\n";

    var iter = tokenize (input);
    while (iter.next ()) |tk|
    {
        _ = tk;
    }
}
