const std = @import("std");

pub fn getStringVisualLength(str: []const u8) !u32 {
    var iter: std.unicode.Utf8Iterator = .{.bytes = str, .i = 0};
    var count: u32 = 0;
    var within_ansi = false;
    while (iter.nextCodepointSlice()) |code_point_str| {
        const char = code_point_str[0];
        switch (isAnsiCode(char, within_ansi)) {
            .yes => { within_ansi = true; continue; },
            .no => within_ansi = false,
            .no_skip => { within_ansi = false; continue; }
        }

        const code_point = try std.unicode.utf8Decode(code_point_str);
        count += unicodeWidth(code_point);
    }
    return count;
}

fn unicodeWidth(code_point: u21) u8 {
    // C0 and DEL
    if (code_point == 0) return 0;
    if (code_point < 0x20 or (code_point >= 0x7f and code_point < 0xa0)) return 0;

    // wide or Fullwidth ranges (based on wcwidth.c and Unicode TR11)
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

    return 1;
}

/// Takes in first char string and says if you're in an ansi code
fn isAnsiCode(char: u8, within_one: bool) enum (u4) { yes, no, no_skip } {
    if (!within_one) {
        if (char == 0x1B) {
            return .yes;
        }
        return .no;
    }

    if (char == '[') {
        return .yes;
    }

    if (char == 'm') {
        return .no_skip;
    }

    if (char == ';' or std.ascii.isDigit(char)) {
        return .yes;
    }

    return .no;
}
