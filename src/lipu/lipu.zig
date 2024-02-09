///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const std = @import("std");
const testing = std.testing;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const token_zig = @import ("token.zig");
const TokenIndex = token_zig.TokenIndex;
const TokenIter = token_zig.TokenIter;
const tokenize = token_zig.tokenize;

const tree_zig = @import ("tree.zig");
const Tree = tree_zig.Tree;

const parse_zig = @import ("parse.zig");
const parse = parse_zig.parse;

const string_zig = @import ("string.zig");
const String = string_zig.String;
const intern = string_zig.intern;

const scope_zig = @import ("scope.zig");
const Scope = scope_zig.Scope;
const ScopeIndex = scope_zig.ScopeIndex;
const Scopes = scope_zig.Scopes;

const value_zig = @import ("value.zig");
const Value = value_zig.Value;

pub const log = @import ("log.zig");

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const version = std.SemanticVersion {.major = 0, .minor = 0, .patch = 0};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

const LipuOptions = struct
{
    allocator : std.mem.Allocator,
    debug_tokens : bool = false,
};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const FileIndex = u32;

pub const Lipu = struct
{
    allocator : std.mem.Allocator,
    debug_tokens : bool = false,
    files : std.ArrayList ([]const u8),
    filenames : std.StringHashMap (FileIndex),
    scopes: Scopes,
    global: ScopeIndex = undefined,

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn destroy (self: *Lipu) void
    {
        for (self.files.items) |item|
        {
            self.allocator.free (item);
        }
        self.files.deinit ();

        var iter = self.filenames.iterator ();
        while (iter.next ()) |kv|
        {
            const filename = kv.key_ptr.*;
            self.allocator.free (filename);
        }
        self.filenames.deinit ();

        self.scopes.deinit ();

        self.allocator.destroy (self);

        string_zig.deinit ();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn import (self: *Lipu, filename: []const u8) !Tree
    {
        const cwd = std.fs.cwd ();
        const content = try cwd.readFileAlloc (self.allocator, filename, std.math.maxInt (TokenIndex));

        const file : FileIndex = @intCast (self.files.items.len);
        const filename_copy = try self.allocator.dupe (u8, filename);
        try self.files.append (content);
        try self.filenames.put (filename_copy, file);

        var iter = token_zig.tokenize (content);
        if (self.debug_tokens)
        {
            const output = try iter.dump (self.allocator);
            defer self.allocator.free (output);
            log.debug ("tokens", "{s}", .{output});
        }

        return try parse (self, &iter, file);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn include (self: *Lipu, content: []const u8, filename: []const u8) !Tree
    {
        const file : FileIndex = @intCast (self.files.items.len);
        const filename_copy = try self.allocator.dupe (u8, filename);
        try self.files.append (content);
        try self.filenames.put (filename_copy, file);

        var iter = tokenize (content);
        if (self.debug_tokens)
        {
            const output = try iter.dump (self.allocator);
            defer self.allocator.free (output);
            log.debug ("tokens", "{s}", .{output});
        }

        return try parse (self, &iter, file);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn dump (self: Lipu) ![]const u8
    {
        var buffer = std.ArrayList (u8).init (self.allocator);
        const writer = buffer.writer ();
        try writer.writeAll ("Files:");
        var iter = self.filenames.iterator ();
        while (iter.next ()) |kv|
        {
            const filename = kv.key_ptr.*;
            const index = kv.value_ptr.*;
            try writer.print ("\n  {}: {s}", .{index, filename});
        }

        try writer.writeAll ("\nScopes:");
        for (self.scopes.all_scopes.items) |scope|
        {
            try scope.dump (self.allocator, writer);
        }

        return buffer.toOwnedSlice ();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn getSlice (self: Lipu, file: FileIndex, index: TokenIndex) []const u8
    {
        if (file >= self.files.items.len)
        {
            return "";
        }

        const content = self.files.items[file];
        var iter = TokenIter {
            .content = content,
            .index = index,
        };
        if (iter.next ()) |tk|
        {
            return tk.slice;
        }
        return "";
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

    pub fn createScope (self: *Lipu, label: String, parent: ?ScopeIndex) !ScopeIndex
    {
        return try self.scopes.init (label, parent);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////

};

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn new_page_command (lipu: *Lipu) void { _ = lipu; std.debug.print ("New Page Command\n", .{}); }
pub fn new_paragraph_command (lipu: *Lipu) void { _ = lipu; std.debug.print ("New Paragraph Command\n", .{}); }
pub fn bold_command (lipu: *Lipu) void { _ = lipu; std.debug.print ("Bold Command\n", .{}); }
pub fn italic_command (lipu: *Lipu) void { _ = lipu; std.debug.print ("Italic Command\n", .{}); }

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub fn create (options: LipuOptions) !*Lipu
{
    const self = try options.allocator.create (Lipu);
    errdefer options.allocator.destroy (self);

    try string_zig.init (options.allocator);
    errdefer string_zig.deinit ();

    var scopes = scope_zig.init (options.allocator);
    errdefer scopes.deinit ();

    const global = try scopes.create (options.allocator, try intern ("Global"), null);

    var global_scope = scopes.get (global);
    try global_scope.set (try intern ("version"), Value.string (try intern ("v0.0.1")));
    try global_scope.set (try intern ("version_major"), Value.integer (0));
    try global_scope.set (try intern ("version_minor"), Value.integer (0));
    try global_scope.set (try intern ("version_patch"), Value.integer (1));
    try global_scope.set (try intern ("\\NewPage"), Value.command (new_page_command));
    try global_scope.set (try intern ("\\NewParagraph"), Value.command (new_paragraph_command));
    try global_scope.set (try intern ("\\Bold"), Value.command (bold_command));
    try global_scope.set (try intern ("\\Italic"), Value.command (italic_command));

    self.* = .{
        .allocator = options.allocator,
        .debug_tokens = options.debug_tokens,
        .files = std.ArrayList ([]const u8).init (options.allocator),
        .filenames = std.StringHashMap (FileIndex).init (options.allocator),
        .scopes = scopes,
        .global = global,
    };

    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

pub const Command = *const fn (lipu: *Lipu) void;

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "check version" {
    try testing.expectFmt("0.0.0", "{}", .{version});
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

test "tokens" {
    _ = @import ("parse.zig");
    _ = @import ("testing.zig");
    _ = @import ("token.zig");
    _ = @import ("value.zig");
    _ = @import ("string.zig");
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
