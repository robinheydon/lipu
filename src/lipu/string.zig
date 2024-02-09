///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import ("std");

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const StringIntern = struct
{
    string_memory : std.ArrayList (u8),

    pub fn deinit (self: *StringIntern) void
    {
        self.string_memory.deinit ();
    }

    pub fn intern (self: *StringIntern, slice: []const u8) !StringIndex
    {
        if (std.mem.indexOf (u8, self.string_memory.items, slice)) |index|
        {
            return .{
                .index = @truncate (index),
                .len = @truncate (slice.len),
            };
        }
        const index = self.string_memory.items.len;
        try self.string_memory.appendSlice (slice);
        return .{
            .index = @truncate (index),
            .len = @truncate (slice.len),
        };
    }

    pub fn get (self: *StringIntern, str: StringIndex) []const u8
    {
        const index = str.index;
        const len = str.len;
        const slice = self.string_memory.items[index .. index+len];

        return slice;
    }

    pub fn concat (self: *StringIntern, lhs: StringIndex, rhs: StringIndex) !StringIndex
    {
        if (lhs.index + lhs.len == rhs.index)
        {
            return .{
                .index = lhs.index,
                .len = @truncate (lhs.len + rhs.len),
            };
        }

        const left = self.get (lhs);
        const right = self.get (rhs);

        const index = self.string_memory.items.len;
        try self.string_memory.appendSlice (left);
        try self.string_memory.appendSlice (right);
        return .{
            .index = @truncate (index),
            .len = @truncate (left.len + right.len),
        };
    }

    pub fn dump (self: *StringIntern, writer: anytype) !void
    {
        try writer.print ("\"{}\"", .{
            std.zig.fmtEscapes (self.string_memory.items),
        });
    }

};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const StringIndex = packed struct
{
    index: u32,
    len: u32,
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn init (allocator: std.mem.Allocator) !StringIntern
{
    return .{
        .string_memory = try std.ArrayList (u8).initCapacity (allocator, 256*1024),
    };
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "string: init"
{
    var strings = try init (std.testing.allocator);
    defer strings.deinit ();
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "string: hello world"
{
    var strings = try init (std.testing.allocator);
    defer strings.deinit ();

    const hello = try strings.intern ("Hello");
    const world = try strings.intern ("World");
    const hello2 = try strings.intern ("Hello");
    const hell = try strings.intern ("Hell");

    const hi = strings.get (hello);
    try std.testing.expectFmt ("Hello", "{s}", .{ hi });

    const monde = strings.get (world);
    try std.testing.expectFmt ("World", "{s}", .{ monde });

    const hi2 = strings.get (hello2);
    try std.testing.expectFmt ("Hello", "{s}", .{ hi2 });

    try std.testing.expectEqual (hi, hi2);

    try std.testing.expectEqual (hell.index, hello.index);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "string: concatination"
{
    var strings = try init (std.testing.allocator);
    defer strings.deinit ();

    const hello = try strings.intern ("Hello");
    const comma = try strings.intern (",");
    const space = try strings.intern (" ");
    const world = try strings.intern ("World");
    const bang = try strings.intern ("!");

    const hc = try strings.concat (hello, comma);
    const hcs = try strings.concat (hc, space);
    const hcsw = try strings.concat (hcs, world);
    const hcswb = try strings.concat (hcsw, bang);

    const phrase = strings.get (hcswb);
    try std.testing.expectFmt ("Hello, World!", "{s}", .{ phrase });

    var dump = std.ArrayList (u8).init (std.testing.allocator);
    defer dump.deinit ();

    const writer = dump.writer ();
    try strings.dump (writer);

    try std.testing.expectFmt ("\"Hello, World!\"", "{s}", .{dump.items});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "string: hard concatination"
{
    var strings = try init (std.testing.allocator);
    defer strings.deinit ();

    const space = try strings.intern (" ");
    const bang = try strings.intern ("!");
    const comma = try strings.intern (",");
    const hello = try strings.intern ("Hello");
    const world = try strings.intern ("World");

    const hc = try strings.concat (hello, comma);
    const hcs = try strings.concat (hc, space);
    const hcsw = try strings.concat (hcs, world);
    const hcswb = try strings.concat (hcsw, bang);

    const phrase = strings.get (hcswb);
    try std.testing.expectFmt ("Hello, World!", "{s}", .{ phrase });

    var dump = std.ArrayList (u8).init (std.testing.allocator);
    defer dump.deinit ();

    const writer = dump.writer ();
    try strings.dump (writer);

    try std.testing.expectFmt ("\" !,HelloWorldHello,Hello, Hello, WorldHello, World!\"", "{s}", .{dump.items});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
