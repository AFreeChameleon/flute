const std = @import("std");

/// Remove ANSI codes starting with 0x1B[ and ending with 'm'
pub fn strip_ansi_codes(gpa: std.mem.Allocator, str: []const u8) ![]u8 {
    var start_idx: i32 = -1;

    var str_buf = try gpa.alloc(u8, str.len);
    var str_buf_idx: usize = 0;
    defer gpa.free(str_buf);

    for (str, 0..) |char, i| {
        // These two if statements take care of the "0x1B[" characters
        if (start_idx + 1 == i and char == '[') {
            continue;
        }
        if (char == 0x1B) {
            start_idx = @intCast(i);
            continue;
        }

        // If we're in the start esc sequence
        if (start_idx != -1) {
            if (char == 'm') {
                start_idx = -1;
                continue;
            } else if (
                char == ';' or
                std.ascii.isDigit(char)
            ) {
                continue;
                
            } else start_idx = -1;
        }
        str_buf[str_buf_idx] = char;
        str_buf_idx += 1;
    }
    return try gpa.dupe(u8, str_buf[0..str_buf_idx]);
}


pub fn get_string_visual_length(str: []const u8) !u32 {
    var iter: std.unicode.Utf8Iterator = .{.bytes = str, .i = 0};
    var count: u32 = 0;
    while (iter.nextCodepoint()) |code_point| {
    	count += unicodeWidth(code_point);
    }
    return count;
}

/// Return terminal display width (0, 1, or 2) for a single Unicode code point.
/// Based on Unicode 15 East Asian Width table (simplified).
fn unicodeWidth(code_point: u21) u8 {
    // C0 and DEL
    if (code_point == 0) return 0;
    if (code_point < 32 or (code_point >= 0x7f and code_point < 0xa0)) return 0;

    // Wide or Fullwidth ranges (based on wcwidth.c and Unicode TR11)
    if ((code_point >= 0x1100 and code_point <= 0x115F) or
        code_point == 0x2329 or code_point == 0x232A or
        (code_point >= 0x2E80 and code_point <= 0xA4CF and code_point != 0x303F) or
        (code_point >= 0xAC00 and code_point <= 0xD7A3) or
        (code_point >= 0xF900 and code_point <= 0xFAFF) or
        (code_point >= 0xFE10 and code_point <= 0xFE19) or
        (code_point >= 0xFE30 and code_point <= 0xFE6F) or
        (code_point >= 0xFF00 and code_point <= 0xFF60) or
        (code_point >= 0xFFE0 and code_point <= 0xFFE6) or
        (code_point >= 0x1F300 and code_point <= 0x1F64F) or
        (code_point >= 0x1F900 and code_point <= 0x1F9FF) or
        (code_point >= 0x20000 and code_point <= 0x3FFFD))
    {
        return 2;
    }

    // Everything else is narrow
    return 1;
}
