const std = @import("std");
const testing = std.testing;

const token = @import ("token.zig");

pub const version = std.SemanticVersion {.major = 0, .minor = 0, .patch = 0};

pub const Ast = struct
{
    allocator: std.mem.Allocator,
    content: []const u8,
    filename: []const u8,

    pub fn deinit (self: *Ast) void
    {
        self.allocator.free (self.content);
    }
};

pub const ParseOptions = struct
{
    debug_tokens : bool = false,
    filename : []const u8,
};

pub fn parse (allocator: std.mem.Allocator, options: ParseOptions) !Ast
{
    const cwd = std.fs.cwd ();
    const content = try cwd.readFileAlloc (allocator, options.filename, std.math.maxInt (token.TokenIndex));

    var iter = token.tokenize (content);
    if (options.debug_tokens)
    {
        while (iter.next ()) |tk|
        {
            std.log.info ("Token {}\n", .{tk});
        }
    }

    const ast = Ast {
        .allocator = allocator,
        .content = content,
        .filename = options.filename,
    };

    return ast;
}

test "check version" {
    try testing.expectFmt("0.0.0", "{}", .{version});
}

test "tokens" {
    _ = @import ("token.zig");
}
