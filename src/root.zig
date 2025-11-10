//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;
const table = @import("./table/index");
const GenerateTableType = table.GenerateTableType;

test "Main" {
    _ = @import("table/index.zig");
    _ = @import("format/string.zig");
    std.testing.refAllDecls(@This());
}
