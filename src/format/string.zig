const std = @import("std");
const expect = std.testing.expect;
const test_gpa = std.testing.allocator;


/// Calculate length of ANSI color width padding (for buffers)
pub fn ColorStringWidthPadding(comptime rgb: [3]u8) usize {
    const str = "\x1B[38;2;;;m\x1B[0m";
    var sum = str.len;

    for (rgb) |v| {
        if (v > 99) {
            sum += 3;
        } else if (v > 9) {
            sum += 2;
        } else {
            sum += 1;
        }
    }
    return sum;
}

/// Coloring strings with ANSI escape codes using compile time known strings
pub fn colorStringComptime(comptime rgb: [3]u8, comptime str: []const u8) []const u8 {
    const r = rgb[0];
    const g = rgb[1];
    const b = rgb[2];
    return std.fmt.comptimePrint(
        "\x1B[38;2;{d};{d};{d}m{s}\x1B[0m",
        .{r, g, b, str}
    );
}

/// Coloring strings with ANSI escape codes using a buffer
pub fn colorStringBuf(buf: []u8, str: []const u8, r: u8, g: u8, b: u8) ![]const u8 {
    const final_str: []u8 = try std.fmt.bufPrint(
        buf,
        "\x1B[38;2;{d};{d};{d}m{s}\x1B[0m",
        .{r, g, b, str}
    );

    return final_str;
}

/// Coloring strings with ANSI escape codes using an allocator
/// Free this after use
pub fn colorStringAlloc(gpa: std.mem.Allocator, str: []const u8, r: u8, g: u8, b: u8) ![]const u8 {
    const final_str: []u8 = try std.fmt.allocPrint(
        gpa,
        "\x1B[38;2;{d};{d};{d}m{s}\x1B[0m",
        .{r, g, b, str}
    );

    return final_str;
}

/// Highlighting strings with ANSI escape codes using a buffer
pub fn highlightStringBuf(buf: []u8, str: []const u8, r: u8, g: u8, b: u8) ![]const u8 {
    const final_str: []u8 = try std.fmt.bufPrint(
        buf,
        "\x1B[7;38;2;{d};{d};{d}m{s}\x1B[0m",
        .{r, g, b, str}
    );

    return final_str;
}

/// Highlighting strings with ANSI escape codes using an allocator
/// Free this after use
pub fn highlightStringAlloc(gpa: std.mem.Allocator, str: []const u8, r: u8, g: u8, b: u8) ![]const u8 {
    const final_str: []u8 = try std.fmt.allocPrint(
        gpa,
        "\x1B[7;38;2;{d};{d};{d}m{s}\x1B[0m",
        .{r, g, b, str}
    );

    return final_str;
}

const FormatMode = enum(u8) {
    Bold = 1,
    Dim = 2,
    Underlined = 4,
    Blink = 5,
    Reverse = 7,
    Hidden = 8,
};

/// Format strings with ANSI escape codes using a buffer
/// Modes:
///     Bold
///     Dim
///     Underlined
///     Blink
///     Reverse (invert the foreground and background colors)
///     Hidden
pub fn formatStringBuf(buf: []u8, str: []const u8, mode: FormatMode) ![]const u8 {
    const final_str: []u8 = try std.fmt.bufPrint(
        buf,
        "\x1B[{d}m{s}\x1B[0m",
        .{@intFromEnum(mode), str}
    );

    return final_str;
}

/// Format strings with ANSI escape codes using an allocator
/// Modes:
///     Bold
///     Dim
///     Underlined
///     Blink
///     Reverse (invert the foreground and background colors)
///     Hidden
/// Free this after use
pub fn formatStringAlloc(gpa: std.mem.Allocator, str: []const u8, mode: FormatMode) ![]const u8 {
    const final_str: []u8 = try std.fmt.allocPrint(
        gpa,
        "\x1B[{d}m{s}\x1B[0m",
        .{@intFromEnum(mode), str}
    );

    return final_str;
}

test "format/string.zig" {
    std.debug.print("\n----- format/string.zig -----\n\n", .{});
}

test "Testing colorStringBuf" {
    std.debug.print("Testing colorStringBuf\n", .{});
    var buf: [256]u8 = std.mem.zeroes([256]u8);
    const str = "test string";
    const buf_slice = try colorStringBuf(&buf, str, 255, 255, 255);
    try expect(std.mem.indexOf(u8, buf_slice, "\x1B[38;2;255;255;255m") != null);
    try expect(std.mem.indexOf(u8, buf_slice, "\x1B[0m") != null);
}

test "Testing colorStringAlloc" {
    std.debug.print("Testing colorStringAlloc\n", .{});
    const str = "test string";
    const alloc_slice = try colorStringAlloc(test_gpa, str, 255, 255, 255);
    defer test_gpa.free(alloc_slice);
    try expect(std.mem.indexOf(u8, alloc_slice, "\x1B[38;2;255;255;255m") != null);
    try expect(std.mem.indexOf(u8, alloc_slice, "\x1B[0m") != null);
}

test "Testing formatStringBuf bold" {
    std.debug.print("Testing formatStringBuf bold\n", .{});
    var buf: [256]u8 = std.mem.zeroes([256]u8);
    const str = "test string";
    const buf_slice = try formatStringBuf(&buf, str, .Bold);
    try expect(std.mem.indexOf(u8, buf_slice, "\x1B[1m") != null);
    try expect(std.mem.indexOf(u8, buf_slice, "\x1B[0m") != null);
}

test "Testing formatStringAlloc bold" {
    std.debug.print("Testing formatStringAlloc bold\n", .{});
    const str = "test string";
    const alloc_slice = try formatStringAlloc(test_gpa, str, .Bold);
    defer test_gpa.free(alloc_slice);
    try expect(std.mem.indexOf(u8, alloc_slice, "\x1B[1m") != null);
    try expect(std.mem.indexOf(u8, alloc_slice, "\x1B[0m") != null);
}

test "Testing highlightStringAlloc" {
    std.debug.print("Testing highlightStringAlloc\n", .{});
    const str = "test string";
    const alloc_slice = try highlightStringAlloc(test_gpa, str, 255, 255, 255);
    defer test_gpa.free(alloc_slice);
    try expect(std.mem.indexOf(u8, alloc_slice, "\x1B[7;38;2;255;255;255m") != null);
    try expect(std.mem.indexOf(u8, alloc_slice, "\x1B[0m") != null);
}

test "Testing highlightStringBuf" {
    std.debug.print("Testing highlightStringBuf\n", .{});
    var buf: [256]u8 = std.mem.zeroes([256]u8);
    const str = "test string";
    const buf_slice = try highlightStringBuf(&buf, str, 255, 255, 255);
    try expect(std.mem.indexOf(u8, buf_slice, "\x1B[7;38;2;255;255;255m") != null);
    try expect(std.mem.indexOf(u8, buf_slice, "\x1B[0m") != null);
}
