pub const table = @import("./table/index.zig");
pub const format = @import("./format/index.zig");

test "Main" {
    const std = @import("std");

    _ = @import("table/index.zig");
    _ = @import("format/string.zig");
    std.testing.refAllDecls(@This());
}
