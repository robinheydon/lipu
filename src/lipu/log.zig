///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import ("std");

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

var log_allocator : std.mem.Allocator = undefined;
var log_verbosity : u8 = 0;
var log_quiet : bool = false;
var log_filename : ?[]const u8 = null;
var log_file : ?std.fs.File = null;
var log_testing : bool = false;
var log_test_output : std.ArrayList(u8) = undefined;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const LogOptions = struct {
    allocator : std.mem.Allocator,
    verbosity : u8 = 0,
    quiet : bool = false,
    filename : ?[]const u8 = null,
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn init (options: LogOptions) !void
{
    log_allocator = options.allocator;
    log_verbosity = options.verbosity;
    log_quiet = options.quiet;
    if (options.filename) |filename|
    {
        const cwd = std.fs.cwd ();

        log_filename = filename;
        log_file = try cwd.createFile (filename, .{});

        std.debug.print ("{?s}\n", .{log_filename});
    }
    log_testing = false;
    log_test_output = std.ArrayList (u8).init (log_allocator);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn deinit () void
{
    if (log_file) |file|
    {
        file.close ();
    }
    log_testing = false;
    log_test_output.deinit ();
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn startTest () void
{
    log_testing = true;
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn endTest () []const u8
{
    return log_test_output.items;
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn output (level: i8, comptime label: []const u8, comptime format: []const u8, args: anytype) void
{
    const use_stdout = (level <= log_verbosity and !log_quiet) or (log_quiet and level < 0);
    const use_file = log_filename != null and level <= log_verbosity;

    if (use_stdout == false and use_file == false and log_testing == false)
    {
        return;
    }

    var stdout = std.io.getStdOut ();
    var stdout_writer = stdout.writer ();

    var buffer = std.ArrayList (u8).init (log_allocator);
    defer buffer.deinit ();

    var writer = buffer.writer ();

    writer.print (format, args) catch return;

    var iter = std.mem.splitAny (u8, buffer.items, "\r\n");
    var count : usize = 0;
    while (iter.next ()) |line| : (count += 1)
    {
        if (use_stdout)
        {
            if (count == 0)
            {
                stdout_writer.print ("{s:<8}: {s}\n", .{ label, line }) catch {};
            }
            else
            {
                stdout_writer.print ("{s:<8}: {s}\n", .{ "", line }) catch {};
            }
        }

        if (use_file)
        {
            if (log_file) |file|
            {
                var file_writer = file.writer ();
                if (count == 0)
                {
                    file_writer.print ("{s:<8}: {s}\n", .{ label, line }) catch {};
                }
                else
                {
                    file_writer.print ("{s:<8}: {s}\n", .{ "", line }) catch {};
                }
            }
        }

        if (log_testing)
        {
            var test_writer = log_test_output.writer ();
            if (count == 0)
            {
                test_writer.print ("{s:<8}: {s}\n", .{ label, line }) catch {};
            }
            else
            {
                test_writer.print ("{s:<8}: {s}\n", .{ "", line }) catch {};
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn err (comptime format: []const u8, args: anytype) void
{
    output (-1, "ERROR", format, args);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn warn (comptime format: []const u8, args: anytype) void
{
    output (0, "Warn", format, args);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn debug (comptime label: []const u8, comptime format: []const u8, args: anytype) void
{
    output (0, label, format, args);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn info (comptime format: []const u8, args: anytype) void
{
    output (1, "info", format, args);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn note (comptime format: []const u8, args: anytype) void
{
    output (2, "note", format, args);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn trace (comptime format: []const u8, args: anytype) void
{
    output (3, "trace", format, args);
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
