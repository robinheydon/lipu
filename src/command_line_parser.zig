const std = @import ("std");

pub const Options = struct
{
    allocator : std.mem.Allocator,
    verbosity : u8 = 0,
    quiet : bool = false,
    inputs : std.ArrayListUnmanaged ([]const u8) = .{},
    outputs : std.ArrayListUnmanaged ([]const u8) = .{},
    errors : std.ArrayListUnmanaged ([]const u8) = .{},
    d_args : bool = false,
    d_tokens : bool = false,
    d_ast : bool = false,

    pub fn deinit (self: *Options) void
    {
        for (self.inputs.items) |item|
        {
            self.allocator.free (item);
        }
        self.inputs.deinit (self.allocator);
        for (self.outputs.items) |item|
        {
            self.allocator.free (item);
        }
        self.outputs.deinit (self.allocator);
        for (self.errors.items) |item|
        {
            self.allocator.free (item);
        }
        self.errors.deinit (self.allocator);
    }

    pub fn format (self: Options, comptime fmt:anytype, _:anytype, writer: anytype) !void
    {
        var flag_newline = false;
        inline for (fmt) |ch|
        {
            if (ch == 'n')
            {
                flag_newline = true;
            }
            else
            {
                @compileError (std.fmt.comptimePrint ("Unknown format '{c}'\n", .{ch}));
            }
        }

        const add = if (flag_newline) ",\n  " else ", ";
        const start = if (flag_newline) "\n  " else " ";
        const end = if (flag_newline) ",\n" else " ";
        try writer.writeAll ("Options{");
        try writer.writeAll (start);
        try writer.print (".verbosity={}", .{self.verbosity});
        try writer.writeAll (add);
        try writer.print (".quiet={}", .{self.quiet});
        for (0.., self.inputs.items) |i, input|
        {
            try writer.writeAll (add);
            try writer.print (".inputs[{}]=\"{}\"", .{i, std.zig.fmtEscapes (input)});
        }
        for (0.., self.outputs.items) |i, output|
        {
            try writer.writeAll (add);
            try writer.print (".outputs[{}]=\"{}\"", .{i, std.zig.fmtEscapes (output)});
        }
        try writer.writeAll (add);
        try writer.print (".d_args={}", .{self.d_args});
        try writer.writeAll (add);
        try writer.print (".d_tokens={}", .{self.d_tokens});
        try writer.writeAll (add);
        try writer.print (".d_ast={}", .{self.d_ast});
        for (0.., self.errors.items) |i, message|
        {
            try writer.writeAll (add);
            try writer.print (".errors[{}]=\"{}\"", .{i, std.zig.fmtEscapes (message)});
        }
        try writer.writeAll (end);
        try writer.writeAll ("}");
    }
};

pub fn parse (allocator: std.mem.Allocator, args: []const []const u8) !Options
{
    var options = Options {
        .allocator = allocator,
    };

    const len = args.len;
    var i : usize = 1;

    while (i < len) : (i += 1)
    {
        if (std.mem.eql (u8, args[i], "-v"))
        {
            options.verbosity = 1;
        }
        else if (std.mem.eql (u8, args[i], "-vv"))
        {
            options.verbosity = 2;
        }
        else if (std.mem.eql (u8, args[i], "-vvv"))
        {
            options.verbosity = 3;
        }
        else if (std.mem.eql (u8, args[i], "-q"))
        {
            options.quiet = true;
        }
        else if (std.mem.eql (u8, args[i], "--quiet"))
        {
            options.quiet = true;
        }
        else if (std.mem.eql (u8, args[i], "-o"))
        {
            i += 1;
            try options.outputs.append (allocator, try allocator.dupe (u8, args[i]));
        }
        else if (std.mem.eql (u8, args[i], "-Dargs"))
        {
            options.d_args = true;
        }
        else if (std.mem.eql (u8, args[i], "-Dtokens"))
        {
            options.d_tokens = true;
        }
        else if (std.mem.eql (u8, args[i], "-Dast"))
        {
            options.d_ast = true;
        }
        else if (args[i][0] == '-')
        {
            const message = try std.fmt.allocPrint (allocator, "Argument \"{}\" is unknown", .{std.zig.fmtEscapes (args[i])});
            try options.errors.append (allocator, message);
        }
        else
        {
            try options.inputs.append (allocator, try allocator.dupe (u8, args[i]));
        }
    }

    return options;
}

pub fn parseArgs (allocator: std.mem.Allocator) !Options
{
    const args = try std.process.argsAlloc (allocator);
    defer std.process.argsFree (allocator, args);

    return parse (allocator, args);
}

test "command_line_parser: options"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", });
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=false,
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: null options inline"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", });
    defer options.deinit ();

    const expected =
        \\Options{ .verbosity=0, .quiet=false, .d_args=false, .d_tokens=false, .d_ast=false }
        ;

    try std.testing.expectFmt (expected, "{}", .{options});
}

test "command_line_parser: -v"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-v"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=1,
        \\  .quiet=false,
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: -vv"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-vv"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=2,
        \\  .quiet=false,
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: -vvv"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-vvv"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=3,
        \\  .quiet=false,
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: -q"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-q"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=true,
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: --quiet"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "--quiet"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=true,
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: -unknown-flag"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-unknown-flag"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=false,
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\  .errors[0]="Argument \"-unknown-flag\" is unknown",
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: input files"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "one.lipu", "two.lipu"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=false,
        \\  .inputs[0]="one.lipu",
        \\  .inputs[1]="two.lipu",
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: output files"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-o", "one.pdf", "one.lipu", "-o", "one.html"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=false,
        \\  .inputs[0]="one.lipu",
        \\  .outputs[0]="one.pdf",
        \\  .outputs[1]="one.html",
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: debug args"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-Dargs"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=false,
        \\  .d_args=true,
        \\  .d_tokens=false,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: debug tokens"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-Dtokens"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=false,
        \\  .d_args=false,
        \\  .d_tokens=true,
        \\  .d_ast=false,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}

test "command_line_parser: debug ast"
{
    var options = try parse (std.testing.allocator, &[_][]const u8 {"name.exe", "-Dast"});
    defer options.deinit ();

    const expected =
        \\Options{
        \\  .verbosity=0,
        \\  .quiet=false,
        \\  .d_args=false,
        \\  .d_tokens=false,
        \\  .d_ast=true,
        \\}
        ;

    try std.testing.expectFmt (expected, "{n}", .{options});
}
