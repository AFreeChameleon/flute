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

/// Zig implementation of:
/// [https://github.com/sindresorhus/string-width/blob/main/index.js]
/// Missing east asian width, probably won't implement that (sorry east asia)
/// I'll probably have to write tests for this
pub fn get_string_visual_length(gpa: std.mem.Allocator, str: []const u8) !u32 {
    var width: u32 = 0;
    const stripped_str = try strip_ansi_codes(gpa, str);
    defer gpa.free(stripped_str);
    for (stripped_str) |char| {
        // Ignore control characters
        if (
            char <= 0x1F or
            (char >= 0x7F and char <= 0x9F)
        ) continue;

        // Ignore zero-width characters
        if (
            (char >= 0x20_0B and char <= 0x20_0F) or
            char == 0xFE_FF
        ) continue;


        // Ignore combining characters
        if (
            (char >= 0x3_00 and char <= 0x3_6F) or // Combining diacritical marks
            (char >= 0x1A_B0 and char <= 0x1A_FF) or // Combining diacritical marks extended
            (char >= 0x1D_C0 and char <= 0x1D_FF) or // Combining diacritical marks supplement
            (char >= 0x20_D0 and char <= 0x20_FF) or // Combining diacritical marks for symbols
            (char >= 0xFE_20 and char <= 0xFE_2F) // Combining half marks
        ) continue;

        // Ignore surrogate pairs
        if (char >= 0xD8_00 and char <= 0xDF_FF) continue;

        // Ignore variation selectors
        if (char >= 0xFE_00 and char <= 0xFE_0F) continue;

        width += 1;
    }
    return width;
}