//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

// const std = @import("std");
// 
// const flute = @import("./table/index.zig");
// const GenerateTableType = flute.GenerateTableType;
// 
// 
// const Row = struct {
//     col1: []const u8,
//     col2: []const u8,
//     col3: []const u8,
//     col4: []const u8,
// };
// pub const Table = GenerateTableType(Row);
// 
// pub fn main() !void {
//     const allocator = std.heap.page_allocator;
// 
//     var t = try Table.init(allocator);
//     defer t.deinit();
//     const new_row1: Row = Row {
//         // .col1 = "你好",
//         // .col2 = "狗",
//         // .col3 = "你今天吃饭了吗",
//         // .col4 = "不想要"
//         .col1 = "ВГ",
//         .col2 = "ДВГ",
//         .col3 = "ЧЧЧЧЧ",
//         .col4 = "СССС"
//     };
//     try t.add_row(new_row1);
// 
//     try t.print_table();
// }
//
//
const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    std.debug.print("Hello from Zig {}\n", .{builtin.zig_version});
    
    const defstr = "12345";
    const deflen = get_len(defstr[0..]);
    std.debug.print("def str: {d}\n", .{deflen});

    const cyrstr = "ВГДВГЧ";
    const cyrlen = get_len(cyrstr[0..]);
    std.debug.print("cyr str: {d}\n", .{cyrlen});

    const chistr = "你今天吃饭了吗";
    const chilen = get_len(chistr[0..]);
    std.debug.print("chi str: {d}\n", .{chilen});
}

fn get_len(str: []const u8) u32 {
    var iter: std.unicode.Utf8Iterator = .{.bytes = str, .i = 0};
    var count: u32 = 0;
    while (iter.nextCodepoint()) |code_point| {
        // std.debug.print("codepoint: {any}\n", .{sl});
        // const len = std.unicode.utf8CodepointSequenceLength(sl[0]) catch return 0;
        // std.debug.print("codepoint seq len: {d}\n", .{len});
        const width = unicodeWidth(code_point);
    	count += width;
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
