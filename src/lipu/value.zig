///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import ("std");

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const string_zig = @import ("string.zig");
const String = string_zig.String;
const intern = string_zig.intern;

const lipu_zig = @import ("lipu.zig");
const Command = lipu_zig.Command;
const Lipu = lipu_zig.Lipu;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const Value = union (enum)
{
    _b: bool,
    _i: i64,
    _n: f64,
    _s: String,
    _c: Command,

    pub fn boolean (b: bool) Value
    {
        return .{ ._b = b };
    }

    pub fn integer (i: i64) Value
    {
        return .{ ._i = i };
    }

    pub fn number (n: f64) Value
    {
        return .{ ._n = n };
    }

    pub fn string (s: String) Value
    {
        return .{ ._s = s };
    }

    pub fn command (c: Command) Value
    {
        return .{ ._c = c };
    }

    pub fn add (lhs: Value, rhs: Value) !Value
    {
        if (lhs == ._i and rhs == ._i)
        {
            return integer (lhs._i + rhs._i);
        }
        else if (lhs == ._n and rhs == ._n)
        {
            return number (lhs._n + rhs._n);
        }
        else if (lhs == ._i and rhs == ._n)
        {
            return number (@as (f64, @floatFromInt (lhs._i)) + rhs._n);
        }
        else if (lhs == ._n and rhs == ._i)
        {
            return number (lhs._n + @as (f64, @floatFromInt (rhs._i)));
        }
        else
        {
            return error.TypeMismatch;
        }
    }

    pub fn sub (lhs: Value, rhs: Value) !Value
    {
        if (lhs == ._i and rhs == ._i)
        {
            return integer (lhs._i - rhs._i);
        }
        else if (lhs == ._n and rhs == ._n)
        {
            return number (lhs._n - rhs._n);
        }
        else if (lhs == ._i and rhs == ._n)
        {
            return number (@as (f64, @floatFromInt (lhs._i)) - rhs._n);
        }
        else if (lhs == ._n and rhs == ._i)
        {
            return number (lhs._n - @as (f64, @floatFromInt (rhs._i)));
        }
        else
        {
            return error.TypeMismatch;
        }
    }

    pub fn mul (lhs: Value, rhs: Value) !Value
    {
        if (lhs == ._i and rhs == ._i)
        {
            return integer (lhs._i * rhs._i);
        }
        else if (lhs == ._n and rhs == ._n)
        {
            return number (lhs._n * rhs._n);
        }
        else if (lhs == ._i and rhs == ._n)
        {
            return number (@as (f64, @floatFromInt (lhs._i)) * rhs._n);
        }
        else if (lhs == ._n and rhs == ._i)
        {
            return number (lhs._n * @as (f64, @floatFromInt (rhs._i)));
        }
        else
        {
            return error.TypeMismatch;
        }
    }

    pub fn format (self: Value, comptime fmt:anytype, _:anytype, writer: anytype) !void
    {
        switch (self)
        {
            ._b => |b|
            {
                switch (b)
                {
                    true => try writer.writeAll ("true"),
                    false => try writer.writeAll ("false"),
                }
            },
            ._i => |i|
            {
                try writer.print ("{d}", .{i});
            },
            ._n => |n|
            {
                try writer.print ("{d:0.6}", .{n});
            },
            ._s => |s|
            {
                try writer.print ("{" ++ fmt ++ "}", .{s});
            },
            ._c =>
            {
                try writer.writeAll ("__built_in_command__");
            }
        }
    }
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "value: init"
{
    try string_zig.init (std.testing.allocator);
    defer string_zig.deinit ();

    const v0 = Value.boolean (true);
    const v1 = Value.boolean (false);
    const v2 = Value.integer (37);
    const v3 = Value.integer (42);
    const v4 = Value.number (3.14159);
    const v5 = Value.number (2.71828);

    _ = try intern ("Hell");
    const old = try intern ("old");
    const hello = try intern ("Hello");
    const v6 = Value.string (hello);
    const v7 = Value.string (old);

    try std.testing.expectFmt ("true", "{}", .{ v0 });
    try std.testing.expectFmt ("false", "{}", .{ v1 });
    try std.testing.expectFmt ("37", "{}", .{ v2 });
    try std.testing.expectFmt ("42", "{}", .{ v3 });
    try std.testing.expectFmt ("3.141590", "{}", .{ v4 });
    try std.testing.expectFmt ("2.718280", "{}", .{ v5 });
    try std.testing.expectFmt ("Hello", "{}", .{ v6 });
    try std.testing.expectFmt ("old", "{}", .{ v7 });

    const v8 = Value.string (try intern ("Hello"));
    try std.testing.expectFmt ("Hello", "{}", .{ v8 });
    try std.testing.expectFmt ("'Hello'", "{'}", .{ v8 });

    const v9 = Value.command (test_command);
    try std.testing.expectFmt ("__built_in_command__", "{}", .{ v9 });
}

fn test_command (_: *Lipu) void
{
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "value: add"
{
    const v0 = Value.boolean (true);
    const v1 = Value.boolean (false);
    const v2 = Value.integer (37);
    const v3 = Value.integer (42);
    const v4 = Value.number (3.14159);
    const v5 = Value.number (2.71828);

    try std.testing.expectError (error.TypeMismatch, v0.add (v1));
    const v7 = try v2.add (v3);
    const v8 = try v4.add (v5);
    const v9 = try v2.add (v5);
    const v10 = try v4.add (v3);

    try std.testing.expectEqual (v7._i, 79);
    try std.testing.expectEqual (v8._n, 5.85987);
    try std.testing.expectEqual (v9._n, 39.71828);
    try std.testing.expectEqual (v10._n, 45.14159);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "value: sub"
{
    const v0 = Value.boolean (true);
    const v1 = Value.boolean (false);
    const v2 = Value.integer (37);
    const v3 = Value.integer (42);
    const v4 = Value.number (3.14159);
    const v5 = Value.number (2.71828);

    try std.testing.expectError (error.TypeMismatch, v0.sub (v1));
    const v7 = try v2.sub (v3);
    const v8 = try v4.sub (v5);
    const v9 = try v2.sub (v5);
    const v10 = try v4.sub (v3);

    try std.testing.expectEqual (v7._i, -5);
    try std.testing.expect (std.math.approxEqAbs (f64, v8._n, 0.42331, 0.000001));
    try std.testing.expect (std.math.approxEqAbs (f64, v9._n, 34.28172, 0.000001));
    try std.testing.expect (std.math.approxEqAbs (f64, v10._n, -38.85841, 0.000001));
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "value: mul"
{
    const v0 = Value.boolean (true);
    const v1 = Value.boolean (false);
    const v2 = Value.integer (37);
    const v3 = Value.integer (42);
    const v4 = Value.number (3.14159);
    const v5 = Value.number (2.71828);

    try std.testing.expectError (error.TypeMismatch, v0.mul (v1));
    const v7 = try v2.mul (v3);
    const v8 = try v4.mul (v5);
    const v9 = try v2.mul (v5);
    const v10 = try v4.mul (v3);

    try std.testing.expectEqual (v7._i, 1554);
    try std.testing.expect (std.math.approxEqAbs (f64, v8._n, 8.539721, 0.000001));
    try std.testing.expect (std.math.approxEqAbs (f64, v9._n, 100.57636, 0.000001));
    try std.testing.expect (std.math.approxEqAbs (f64, v10._n, 131.94678, 0.000001));
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
