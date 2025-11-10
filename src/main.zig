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
const format = @import("./format/string.zig");

pub fn main() !void {
    std.debug.print("Hello from Zig {}\n", .{builtin.zig_version});
    var buf: [256]u8 = std.mem.zeroes([256]u8);
    const str = "poopy";
    const res = try format.boldStringBuf(&buf, str);
    std.debug.print("{s}\n", .{res});
}
