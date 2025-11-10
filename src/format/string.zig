const std = @import("std");
const expect = std.testing.expect;
const test_gpa = std.testing.allocator;

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

/// Make strings bold with ANSI escape codes using a buffer
pub fn boldStringBuf(buf: []u8, str: []const u8) ![]const u8 {
    const final_str: []u8 = try std.fmt.bufPrint(
        buf,
        "\x1B[1m{s}\x1B[0m",
        .{str}
    );

    return final_str;
}

/// Make strings bold with ANSI escape codes using an allocator
/// Free this after use
pub fn boldStringAlloc(gpa: std.mem.Allocator, str: []const u8) ![]const u8 {
    const final_str: []u8 = try std.fmt.allocPrint(
        gpa,
        "\x1B[1m{s}\x1B[0m",
        .{str}
    );

    return final_str;
}

test "format/string.zig" {
    std.debug.print("----- format/string.zig -----\n\n", .{});
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

test "Testing boldStringBuf" {
    std.debug.print("Testing boldStringAlloc\n", .{});
    var buf: [256]u8 = std.mem.zeroes([256]u8);
    const str = "test string";
    const buf_slice = try boldStringBuf(&buf, str);
    try expect(std.mem.indexOf(u8, buf_slice, "\x1B[1m") != null);
    try expect(std.mem.indexOf(u8, buf_slice, "\x1B[0m") != null);
}

test "Testing boldStringAlloc" {
    std.debug.print("Testing boldStringAlloc\n", .{});
    const str = "test string";
    const alloc_slice = try boldStringAlloc(test_gpa, str);
    defer test_gpa.free(alloc_slice);
    try expect(std.mem.indexOf(u8, alloc_slice, "\x1B[1m") != null);
    try expect(std.mem.indexOf(u8, alloc_slice, "\x1B[0m") != null);
}
