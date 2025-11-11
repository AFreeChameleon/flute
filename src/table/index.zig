const std = @import("std");
const builtin = @import("builtin");

const util = @import("./util.zig");
const log = @import("./log.zig");

const test_gpa = std.testing.allocator;
const expect = std.testing.expect;

const Separators = struct {
    const Chars = struct { left: []const u8, right: []const u8, separator: []const u8 };

    const top = Chars{
        .left = "+",
        .right = "+",
        .separator = "+",
    };

    const bottom = Chars{
        .left = "+",
        .right = "+",
        .separator = "+",
    };

    const middle = Chars{
        .left = "+",
        .right = "+",
        .separator = "+",
    };

    const hori_line = "-";
    const vert_line = "|";

    // These cool unicode separators cause gibberish on some terminals
    // so I'll keep them commented until I can include them on non utf8 terminals
    // const top = Chars{
    //     .left = "┌",
    //     .right = "┐",
    //     .separator = "┬",
    // };

    // const bottom = Chars{
    //     .left = "└",
    //     .right = "┘",
    //     .separator = "┴",
    // };

    // const middle = Chars{
    //     .left = "├",
    //     .right = "┤",
    //     .separator = "┼",
    // };

    // const hori_line = "─";
    // const vert_line = "│";
};

const ROW_WIDTH: usize = 0;
pub fn GenerateRowWidths(comptime Row: type) type {
    const row_fields = @typeInfo(Row).@"struct".fields;
    var fields: [row_fields.len]std.builtin.Type.StructField = undefined;
    inline for (row_fields, 0..) |field, i| {
        if (field.type != []const u8) {
            @panic("All fields in the table must be []const u8");
        }
        fields[i] = std.builtin.Type.StructField{
            .name = field.name,
            .type = usize,
            .default_value_ptr = &ROW_WIDTH,
            .alignment = 0,
            .is_comptime = false
        };
    }
    const RowWidths = @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .fields = &fields,
            .is_tuple = false,
            .decls = &.{},
            .backing_integer = null
        }
    });
    return RowWidths;
}

/// Because there are multiple table types, the main one and the stats, this
/// dynamically generates the type for either:
/// const Table = GenerateTableType(MainRow, MainRowWidths);
/// const table = Table.init(true);
pub fn GenerateTableType(
    comptime Row: type
) type {
    const RowWidths = GenerateRowWidths(Row);
    return struct {
        const Self = @This();

        gpa: std.mem.Allocator,
        row_widths: RowWidths,
        rows: std.ArrayList(Row),

        pub fn init(gpa: std.mem.Allocator) !Self {
            log.init();
            const rows = std.ArrayList(Row).init(gpa);
            const table = Self {
                .rows = rows,
                .row_widths = RowWidths{},
                .gpa = gpa
            };
            return table;
        }

        pub fn deinit(self: *Self) void {
            self.rows.clearAndFree();
            self.rows.clearRetainingCapacity();
            self.rows.deinit();
        }

        pub fn addRow(self: *Self, row: Row) !void {
            try self.rows.append(row);
            try self.updateRowWidths(&row);
        }

        pub fn removeRows(self: *Self, num_rows: usize) !void {
            for (0..num_rows) |_| {
                self.rows.items[self.rows.items.len - 1].deinit();
                _ = self.rows.swapRemove(self.rows.items.len - 1);
            }
        }

        fn refreshAllRowWidths(self: *Self) !void {
            for (self.rows.items) |*row| {
                try self.updateRowWidths(row);
            }
        }

        /// Iterates over every field and updates row widths to make it responsive
        pub fn updateRowWidths(self: *Self, new_row: *const Row) !void {
            inline for (@typeInfo(RowWidths).@"struct".fields) |field| {
                // Adding a space of padding on either side
                const new_field = try util.getStringVisualLength(
                    @field(new_row, field.name)
                ) + 2;
                const old_field = @field(self.row_widths, field.name);
                if (old_field < new_field) {
                    @field(self.row_widths, field.name) = new_field;
                }
            }
        }

        /// Prints all headers and rows in the table
        pub fn printTable(self: *Self) !void {
            try self.printBorder(Separators.top);
            for (self.rows.items) |row| {
                try self.printRow(&row);
            }
            try self.printBorder(Separators.bottom);
        }

        fn printRow(self: *Self, row: *const Row) !void {
            var buf_list = std.ArrayList(u8).init(self.gpa);
            defer buf_list.deinit();
            var writer = buf_list.writer();

            for (Separators.vert_line) |byte| {
                try writer.writeByte(byte);
            }

            inline for (@typeInfo(RowWidths).@"struct".fields, 0..) |field, i| {
                try writer.writeByte(' ');
                const row_width = @field(row, field.name).len;
                const visual_row_width = try util.getStringVisualLength(
                    @field(row, field.name)
                );
                // -1 because left padding has already been added
                for (0..row_width) |j| {
                    try writer.writeByte(@field(row, field.name)[j]);
                }
                // Adding right padding
                for (visual_row_width..(@field(self.row_widths, field.name) - 1)) |_| {
                    try writer.writeByte(' ');
                }

                if (i != @typeInfo(RowWidths).@"struct".fields.len - 1) {
                    for (Separators.vert_line) |byte| {
                        try writer.writeByte(byte);
                    }
                }
            }

            for (Separators.vert_line) |byte| {
                try writer.writeByte(byte);
            }

            try log.print("{s}\n", .{buf_list.items});
        }

        fn printBorder(self: *Self, chars: Separators.Chars) !void {
            var buf_list = std.ArrayList(u8).init(self.gpa);
            defer buf_list.deinit();
            var writer = buf_list.writer();

            for (chars.left) |byte| {
                try writer.writeByte(byte);
            }

            inline for (@typeInfo(RowWidths).@"struct".fields, 0..) |field, i| {
                for (0..@field(self.row_widths, field.name)) |_| {
                    for (Separators.hori_line) |byte| {
                        try writer.writeByte(byte);
                    }
                }

                if (i != @typeInfo(RowWidths).@"struct".fields.len - 1) {
                    for (chars.separator) |byte| {
                        try writer.writeByte(byte);
                    }
                }
            }

            for (chars.right) |byte| {
                try writer.writeByte(byte);
            }
            try log.print("{s}\n", .{buf_list.items});
        }

        pub fn getTotalRowWidth(self: *Self) usize {
            const fields = @typeInfo(RowWidths).@"struct".fields;

            // Borders in between
            var total_width: usize = fields.len + 1;
            inline for (fields) |field| {
                total_width += @field(self.row_widths, field.name);
            }
            return total_width;
        }

        /// Clears the printed table
        pub fn clear(self: *Self) !void {
            const num_of_rows = self.rows.items.len;
            // Length of table row in terminal columns
            const fl_row_width: f32 = @floatFromInt(self.getTotalRowWidth());
            const fl_window_cols: f32 = @floatFromInt(try log.getWindowCols());

            const total_rows_printed = calculate_total_rows(fl_row_width, fl_window_cols, num_of_rows);

            // VT100 go up 1 line and erase it
            for (0..total_rows_printed) |_| try log.print("\x1b[A\x1b[2K", .{});
        }

        fn calculate_total_rows(row_width: f32, window_cols: f32, num_of_rows: usize) usize {
            const overlap: usize = if (window_cols < row_width)
                @intFromFloat(@ceil(row_width / window_cols))
                else
                    1;

                // +2 for the top and bottom borders
                const total_rows_printed: usize = (num_of_rows * overlap);
                return total_rows_printed;
        }

        pub fn reset(self: *Self) void {
            for (self.rows.items) |*it| {
                if (!it.header) {
                    it.deinit();
                }
            }
            self.rows.clearAndFree();
            self.rows.clearRetainingCapacity();
            self.row_widths = RowWidths{};
        }
    };
}


test "table/index.zig" {
    std.debug.print("\n----- table/index.zig -----\n\n", .{});
}

test "Successfully make table with one row" {
    std.debug.print("Successfully make table with one row\n", .{});

    const Row = struct {
        col1: []const u8,
        col2: []const u8,
        col3: []const u8,
        col4: []const u8,
    };
    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();
    const new_row: Row = Row {
        .col1 = "col1",
        .col2 = "col2",
        .col3 = "col3",
        .col4 = "col4"
    };
    try t.addRow(new_row);

    try expect(t.rows.items.len == 1);
}

test "Make table with multiple rows and check row width" {
    std.debug.print("Make table with multiple rows and check row width\n", .{});

    const Row = struct {
        col1: []const u8,
        col2: []const u8,
        col3: []const u8,
        col4: []const u8,
    };
    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();
    const new_row1: Row = Row {
        .col1 = "col1",
        .col2 = "col2",
        .col3 = "col3",
        .col4 = "col4"
    };
    const new_row2: Row = Row {
        .col1 = "col1",
        .col2 = "col2222",
        .col3 = "col33",
        .col4 = "col44444"
    };
    try t.addRow(new_row1);
    try t.addRow(new_row2);

    try expect(t.rows.items.len == 2);
    try expect(t.row_widths.col1 == 6);
    try expect(t.row_widths.col2 == 9);
    try expect(t.row_widths.col3 == 7);
    try expect(t.row_widths.col4 == 10);
}

test "Make table with one row with cyrillic characters and check row width" {
    std.debug.print("Make table with one row with cyrillic characters and check row width\n", .{});

    const Row = struct {
        col1: []const u8,
        col2: []const u8,
        col3: []const u8,
        col4: []const u8,
    };
    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();
    const new_row1: Row = Row {
        .col1 = "ВГ",
        .col2 = "ДВГ",
        .col3 = "ЧЧЧЧЧ",
        .col4 = "СССС"
    };
    try t.addRow(new_row1);

    try expect(t.rows.items.len == 1);
    try expect(t.row_widths.col1 == 4);
    try expect(t.row_widths.col2 == 5);
    try expect(t.row_widths.col3 == 7);
    try expect(t.row_widths.col4 == 6);
    
}

test "Make table with one row with chinese characters and check row width" {
    std.debug.print("Make table with one row with chinese characters and check row width\n", .{});

    const Row = struct {
        col1: []const u8,
        col2: []const u8,
        col3: []const u8,
        col4: []const u8,
    };
    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();
    const new_row1: Row = Row {
        .col1 = "你好",
        .col2 = "狗",
        .col3 = "你今天吃饭了吗",
        .col4 = "不想要"
    };
    try t.addRow(new_row1);

    try expect(t.rows.items.len == 1);
    try expect(t.row_widths.col1 == 6);
    try expect(t.row_widths.col2 == 4);
    try expect(t.row_widths.col3 == 16);
    try expect(t.row_widths.col4 == 8);
}
