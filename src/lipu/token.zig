///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import ("std");

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const TokenKind = enum
{
    ampersand,
    assign,
    asterisk,
    at,
    bang,
    bar,
    bin,
    close_block,
    close_paren,
    close_square,
    colon,
    comma,
    command,
    comment,
    digit,
    document,
    dollar,
    dot,
    double_quote,
    end_of_line,
    equal,
    escape,
    false,
    greater_than,
    greater_than_or_equal,
    hash,
    hat,
    hex,
    less_than,
    less_than_or_equal,
    letter,
    minus,
    not_equal,
    number,
    oct,
    open_block,
    open_paren,
    open_square,
    percent,
    plus,
    query,
    semicolon,
    shift_left,
    shift_right,
    single_quote,
    slash,
    space,
    tick,
    tilde,
    true,
    unknown,
    @"and",
    @"or",
    not,
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const Token = struct
{
    kind: TokenKind,
    index: TokenIndex,
    slice: []const u8,

    //////////////////////////////////////////////////////////////////////////////////////////

    pub fn format (self: Token, _:anytype, _:anytype, writer: anytype) !void
    {
        try writer.print ("{s} \"{}\"", .{@tagName (self.kind), std.zig.fmtEscapes (self.slice)});
    }
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const TokenIter = struct
{
    content: []const u8,
    index: TokenIndex,

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn dump (self: *TokenIter, allocator: std.mem.Allocator) ![]const u8
    {
        const old_index = self.index;

        var buffer = std.ArrayList (u8).init (allocator);
        var writer = buffer.writer ();

        try writer.writeAll ("Tokens:");

        while (self.next ()) |tk|
        {
            try writer.print ("\n  {}", .{tk});
        }

        self.index = old_index;

        return try buffer.toOwnedSlice ();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn next (self: *TokenIter) ?Token
    {
        if (self.index >= self.content.len)
        {
            return null;
        }

        const start_index = self.index;

        const ch = self.content[self.index];
        self.index += 1;

        const kind : TokenKind = switch (ch)
        {
            ' ', '\t' => blk: {
                while (self.index < self.content.len) : (self.index += 1)
                {
                    switch (self.content[self.index])
                    {
                        ' ', '\t' => {},
                        else => break
                    }
                }
                break :blk .space;
            },

            '\n' => .end_of_line,

            '\r' => blk: {
                if (self.index < self.content.len and self.content[self.index] == '\n')
                {
                    self.index += 1;
                }
                break :blk .end_of_line;
            },

            '!' => blk: {
                if (self.index < self.content.len)
                {
                    if (self.content[self.index] == '=')
                    {
                        self.index += 1;
                        break :blk .not_equal;
                    }
                }
                break :blk .bang;
            },
            '"' => .double_quote,
            '#' => blk: {
                if (self.index < self.content.len)
                {
                    if (self.content[self.index] == '#')
                    {
                        self.index += 1;
                        while (self.index < self.content.len) : (self.index += 1)
                        {
                            switch (self.content[self.index])
                            {
                                '\r', '\n' => break,
                                else => {}
                            }
                        }

                        if (self.index < self.content.len and self.content[self.index] == '\r')
                        {
                            self.index += 1;
                            if (self.index < self.content.len and self.content[self.index] == '\n')
                            {
                                self.index += 1;
                            }
                        }
                        else if (self.index < self.content.len and self.content[self.index] == '\n')
                        {
                            self.index += 1;
                        }

                        while (self.index < self.content.len) : (self.index += 1)
                        {
                            switch (self.content[self.index])
                            {
                                ' ', '\t' => {},
                                else => break
                            }
                        }
                        break :blk .comment;
                    }
                }
                break :blk .hash;
            },
            '$' => .dollar,
            '%' => .percent,
            '&' => .ampersand,
            '\'' => .single_quote,
            '(' => .open_paren,
            ')' => .close_paren,
            '*' => .asterisk,
            '+' => .plus,
            ',' => .comma,
            '-' => .minus,
            '.' => .dot,
            '/' => .slash,
            ':' => .colon,
            ';' => .semicolon,
            '<' => blk: {
                if (self.index < self.content.len)
                {
                    if (self.content[self.index] == '=')
                    {
                        self.index += 1;
                        break :blk .less_than_or_equal;
                    }
                    else if (self.content[self.index] == '<')
                    {
                        self.index += 1;
                        break :blk .shift_left;
                    }
                }
                break :blk .less_than;
            },
            '=' => blk: {
                if (self.index < self.content.len)
                {
                    if (self.content[self.index] == '=')
                    {
                        self.index += 1;
                        break :blk .equal;
                    }
                }
                break :blk .assign;
            },
            '>' => blk: {
                if (self.index < self.content.len)
                {
                    if (self.content[self.index] == '=')
                    {
                        self.index += 1;
                        break :blk .greater_than_or_equal;
                    }
                    else if (self.content[self.index] == '>')
                    {
                        self.index += 1;
                        break :blk .shift_right;
                    }
                }
                break :blk .greater_than;
            },
            '?' => .query,
            '@' => .at,
            '[' => .open_square,
            '\\' => blk: {
                if (self.index < self.content.len)
                {
                    switch (self.content[self.index])
                    {
                        '_', 'A' ... 'Z', 'a' ... 'z' => {
                            self.index += 1;
                            while (self.index < self.content.len) : (self.index += 1)
                            {
                                switch (self.content[self.index])
                                {
                                    '_', 'a' ... 'z', 'A' ... 'Z', '0' ... '9' => {},
                                    else => break
                                }
                            }
                            break :blk .command;
                        },
                        ' ', '\t', '\r', '\n' => break :blk .escape,
                        else => {
                            self.index += 1;
                            break :blk .unknown;
                        }
                    }
                }
                break :blk .escape;
            },
            ']' => .close_square,
            '^' => .hat,
            '`' => .tick,
            '{' => .open_block,
            '|' => .bar,
            '}' => .close_block,
            '~' => .tilde,

            '_', 'a' ... 'z', 'A' ... 'Z' => blk: {
                while (self.index < self.content.len) : (self.index += 1)
                {
                    switch (self.content[self.index])
                    {
                        '_',
                        '0' ... '9',
                        'a' ... 'z',
                        'A' ... 'Z' => {},
                        else => break
                    }
                }

                const word = self.content[start_index .. self.index];
                if (std.mem.eql (u8, "true", word))
                {
                    break :blk .true;
                }
                else if (std.mem.eql (u8, "false", word))
                {
                    break :blk .false;
                }
                else if (std.mem.eql (u8, "and", word))
                {
                    break :blk .@"and";
                }
                else if (std.mem.eql (u8, "or", word))
                {
                    break :blk .@"or";
                }
                else if (std.mem.eql (u8, "not", word))
                {
                    break :blk .@"not";
                }

                break :blk .letter;
            },

            '0' => blk: {
                if (self.index < self.content.len and self.content[self.index] == 'x')
                {
                    self.index += 1;
                    while (self.index < self.content.len) : (self.index += 1)
                    {
                        switch (self.content[self.index])
                        {
                            '_', '0' ... '9', 'a' ... 'f', 'A' ... 'F' => {},
                            else => break
                        }
                    }
                    break :blk .hex;
                }
                else if (self.index < self.content.len and self.content[self.index] == 'o')
                {
                    self.index += 1;
                    while (self.index < self.content.len) : (self.index += 1)
                    {
                        switch (self.content[self.index])
                        {
                            '_', '0' ... '7' => {},
                            else => break
                        }
                    }
                    break :blk .oct;
                }
                else if (self.index < self.content.len and self.content[self.index] == 'b')
                {
                    self.index += 1;
                    while (self.index < self.content.len) : (self.index += 1)
                    {
                        switch (self.content[self.index])
                        {
                            '_', '0' ... '1' => {},
                            else => break
                        }
                    }
                    break :blk .bin;
                }
                break :blk .digit;
            },

            '1' ... '9' => blk: {
                while (self.index < self.content.len) : (self.index += 1)
                {
                    switch (self.content[self.index])
                    {
                        '_', '0' ... '9' => {},
                        else => break
                    }
                }
                if (self.index < self.content.len and self.content[self.index] == '.')
                {
                    self.index += 1;
                    while (self.index < self.content.len) : (self.index += 1)
                    {
                        switch (self.content[self.index])
                        {
                            '_', '0' ... '9' => {},
                            else => break :blk .number
                        }
                    }
                    break :blk .number;
                }
                break :blk .digit;
            },
            else => .unknown,
        };

        return Token {
            .kind = kind,
            .index = start_index,
            .slice = self.content[start_index .. self.index],
        };
    }

    //////////////////////////////////////////////////////////////////////////////////////////

};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const TokenIndex = u32;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn tokenize (content: []const u8) TokenIter
{
    return .{
        .content = content,
        .index = 0,
    };
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: simple"
{
    const input = "Hello, World";

    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  letter "Hello"
        \\  comma ","
        \\  space " "
        \\  letter "World"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: end of lines"
{
    const input = "1\r2\n3\r\n4\n\r6";

    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  digit "1"
        \\  end_of_line "\r"
        \\  digit "2"
        \\  end_of_line "\n"
        \\  digit "3"
        \\  end_of_line "\r\n"
        \\  digit "4"
        \\  end_of_line "\n"
        \\  end_of_line "\r"
        \\  digit "6"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: words"
{
    const input = "a _b c_ a_A_z_Z_09";

    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  letter "a"
        \\  space " "
        \\  letter "_b"
        \\  space " "
        \\  letter "c_"
        \\  space " "
        \\  letter "a_A_z_Z_09"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: digits and numbers"
{
    const input = "0 1 10 10.1 10.9 0xCafe_Beef 0o774_215 0b1100_0101";

    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  digit "0"
        \\  space " "
        \\  digit "1"
        \\  space " "
        \\  digit "10"
        \\  space " "
        \\  number "10.1"
        \\  space " "
        \\  number "10.9"
        \\  space " "
        \\  hex "0xCafe_Beef"
        \\  space " "
        \\  oct "0o774_215"
        \\  space " "
        \\  bin "0b1100_0101"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: ascii"
{
    const input = "! \" # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \\ ] ^ _ ` { | } ~";
    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  bang "!"
        \\  space " "
        \\  double_quote "\""
        \\  space " "
        \\  hash "#"
        \\  space " "
        \\  dollar "$"
        \\  space " "
        \\  percent "%"
        \\  space " "
        \\  ampersand "&"
        \\  space " "
        \\  single_quote "'"
        \\  space " "
        \\  open_paren "("
        \\  space " "
        \\  close_paren ")"
        \\  space " "
        \\  asterisk "*"
        \\  space " "
        \\  plus "+"
        \\  space " "
        \\  comma ","
        \\  space " "
        \\  minus "-"
        \\  space " "
        \\  dot "."
        \\  space " "
        \\  slash "/"
        \\  space " "
        \\  colon ":"
        \\  space " "
        \\  semicolon ";"
        \\  space " "
        \\  less_than "<"
        \\  space " "
        \\  assign "="
        \\  space " "
        \\  greater_than ">"
        \\  space " "
        \\  query "?"
        \\  space " "
        \\  at "@"
        \\  space " "
        \\  open_square "["
        \\  space " "
        \\  escape "\\"
        \\  space " "
        \\  close_square "]"
        \\  space " "
        \\  hat "^"
        \\  space " "
        \\  letter "_"
        \\  space " "
        \\  tick "`"
        \\  space " "
        \\  open_block "{"
        \\  space " "
        \\  bar "|"
        \\  space " "
        \\  close_block "}"
        \\  space " "
        \\  tilde "~"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: compound symbols"
{
    const input = "<= >= == != << >>";
    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  less_than_or_equal "<="
        \\  space " "
        \\  greater_than_or_equal ">="
        \\  space " "
        \\  equal "=="
        \\  space " "
        \\  not_equal "!="
        \\  space " "
        \\  shift_left "<<"
        \\  space " "
        \\  shift_right ">>"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: comments"
{
    const input = "one## a comment\n  two##\r  three##\r\n  four";
    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  letter "one"
        \\  comment "## a comment\n  "
        \\  letter "two"
        \\  comment "##\r  "
        \\  letter "three"
        \\  comment "##\r\n  "
        \\  letter "four"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: commands"
{
    const input = "\\_ \\Hello \\a42_39z";
    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  command "\\_"
        \\  space " "
        \\  command "\\Hello"
        \\  space " "
        \\  command "\\a42_39z"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: escaped symbols and numbers"
{
    const input = "\\## \\49";
    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  unknown "\\#"
        \\  hash "#"
        \\  space " "
        \\  unknown "\\4"
        \\  digit "9"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: reserved words"
{
    const input = "true false and or not";
    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  true "true"
        \\  space " "
        \\  false "false"
        \\  space " "
        \\  and "and"
        \\  space " "
        \\  or "or"
        \\  space " "
        \\  not "not"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "token: combined spaces"
{
    const input = "one  two  \t three";
    var iter = tokenize (input);
    const output = try iter.dump (std.testing.allocator);
    defer std.testing.allocator.free (output);

    const expected =
        \\Tokens:
        \\  letter "one"
        \\  space "  "
        \\  letter "two"
        \\  space "  \t "
        \\  letter "three"
    ;

    try std.testing.expectFmt (expected, "{s}", .{output});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
