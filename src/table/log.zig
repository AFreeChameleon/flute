const std = @import("std");
const builtin = @import("builtin");

pub var stdout_file: std.fs.File = undefined;
pub var stderr_file: std.fs.File = undefined;
const TIOCGWINSZ = 0x5413;

pub fn init() void {
    stdout_file = std.io.getStdOut();
    stderr_file = std.io.getStdErr();
}

pub fn print(comptime text: []const u8, args: anytype) !void {
    const stdout = stdout_file.writer();
    try stdout.print(text, args);
}

pub fn print_err(comptime text: []const u8, args: anytype) !void {
    const stderr = stderr_file.writer();
    try stderr.print(text, args);
}

/// Sets the cols to whatever columns the window has
pub fn get_window_cols() !u32 {
    var cols: u32 = 0;
    if (comptime builtin.target.os.tag != .windows) {
        var w: std.posix.winsize = undefined;
        _ = std.c.ioctl(std.c.STDOUT_FILENO, TIOCGWINSZ, &w);
        cols = w.ws_col;
    } else {
        var csbi: std.os.windows.CONSOLE_SCREEN_BUFFER_INFO = std.mem.zeroes(std.os.windows.CONSOLE_SCREEN_BUFFER_INFO);
        const res = std.os.windows.GetConsoleScreenBufferInfo(std.os.windows.GetStdHandle(std.os.windows.STD_OUTPUT_HANDLE), &csbi);
        if (res == 0) {
            try print_err("Windows error code: {d}", .{std.os.windows.GetLastError()});
            return error.FailedToSetWindowCols;
        }
        cols = @intCast(csbi.srWindow.Right - csbi.srWindow.Left + 1);
    }
    return cols;
}