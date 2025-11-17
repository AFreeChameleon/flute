const std = @import("std");
const builtin = @import("builtin");

const util = @import("./util.zig");
const log = @import("./log.zig");

const test_gpa = std.testing.allocator;
const expect = std.testing.expect;


/// This is what controls the borders.
/// To change the characters used in the borders edit this struct like:
/// ```
/// flute.table.Borders.top = flute.table.Borders.Chars {
///     .left = "┌",
///     .right = "┐",
///     .separator = "┬"
/// };
/// ```
pub const Borders = struct {
    pub const Chars = struct { left: []const u8, right: []const u8, separator: []const u8 };

    pub var top = Chars{
        .left = "+",
        .right = "+",
        .separator = "+",
    };

    pub var bottom = Chars{
        .left = "+",
        .right = "+",
        .separator = "+",
    };

    pub var hori_line = "-";
    pub var vert_line = "|";

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
fn GenerateRowWidths(comptime Row: type) type {
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
            .alignment = @alignOf(usize),
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

/// This dynamically generates the type for:
/// ```
/// const Table = GenerateTableType(MainRow, MainRowWidths);
/// const table = Table.init(true);
/// ```
pub fn GenerateTableType(
    comptime Row: type
) type {
    const RowWidths = GenerateRowWidths(Row);
    return struct {
        const Self = @This();

        gpa: std.mem.Allocator,
        row_widths: RowWidths,
        rows: std.ArrayList(Row),
        lines_printed: u32,

        pub fn init(gpa: std.mem.Allocator) !Self {
            const table = Self {
                .rows = .empty,
                .row_widths = RowWidths{},
                .gpa = gpa,
                .lines_printed = 0
            };
            return table;
        }

        pub fn deinit(self: *Self) void {
            self.rows.clearAndFree(self.gpa);
            self.rows.clearRetainingCapacity();
            self.rows.deinit(self.gpa);
        }

        /// Adds a row to the table
        pub fn addRow(self: *Self, row: Row) !void {
            try self.rows.append(self.gpa, row);
            try self.updateRowWidths(&row);
        }

        /// Adds a row to the table
        // pub fn removeRows(self: *Self, num_rows: usize) !void {
        //     for (0..num_rows) |_| {
        //         self.rows.items[self.rows.items.len - 1].deinit();
        //         _ = self.rows.swapRemove(self.rows.items.len - 1);
        //     }
        // }

        /// Removes a row from the table
        pub fn removeRow(self: *Self, idx: usize) void {
            _ = self.rows.orderedRemove(idx);
        }

        fn refreshAllRowWidths(self: *Self) !void {
            for (self.rows.items) |*row| {
                try self.updateRowWidths(row);
            }
        }

        /// Iterates over every field and updates row widths to make it responsive
        fn updateRowWidths(self: *Self, new_row: *const Row) !void {
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

        /// Prints all rows in the table
        pub fn printTable(self: *Self, writer: anytype) !void {
            try self.printBorder(Borders.top, writer);
            for (0..self.rows.items.len) |i| {
                try self.printRow(i, writer);
            }
            try self.printBorder(Borders.bottom, writer);
        }

        /// Prints row in the table
        pub fn printRow(self: *Self, idx: usize, writer: anytype) !void {
            if (idx > self.rows.items.len) {
                return error.RowNotExists;
            }
            self.lines_printed += 1;

            const row = self.rows.items[idx];
            for (Borders.vert_line) |byte| {
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
                    for (Borders.vert_line) |byte| {
                        try writer.writeByte(byte);
                    }
                }
            }

            for (Borders.vert_line) |byte| {
                try writer.writeByte(byte);
            }

            try writer.writeByte('\n');
        }

        /// Prints a line of the table's border.
        pub fn printBorder(self: *Self, chars: Borders.Chars, writer: anytype) !void {
            self.lines_printed += 1;
            for (chars.left) |byte| {
                try writer.writeByte(byte);
            }

            inline for (@typeInfo(RowWidths).@"struct".fields, 0..) |field, i| {
                for (0..@field(self.row_widths, field.name)) |_| {
                    for (Borders.hori_line) |byte| {
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
            try writer.writeByte('\n');
        }

        /// Gets the width of the table
        pub fn getTotalTableWidth(self: *Self) usize {
            const fields = @typeInfo(RowWidths).@"struct".fields;

            // Borders in between
            var total_width: usize = fields.len + 1;
            inline for (fields) |field| {
                total_width += @field(self.row_widths, field.name);
            }
            return total_width;
        }

        /// Clears the printed table
        pub fn clear(self: *Self, writer: anytype) !void {
            // Length of table row in terminal columns
            const fl_row_width: f32 = @floatFromInt(self.getTotalTableWidth());
            const fl_window_cols: f32 = @floatFromInt(try log.getWindowCols());

            const total_lines_printed = calculateTotalRows(
                fl_row_width, fl_window_cols, self.lines_printed
            );

            // VT100 go up 1 line and erase it
            for (0..total_lines_printed) |_| try writer.writeAll("\x1b[A\x1b[2K");
        }

        fn calculateTotalRows(row_width: f32, window_cols: f32, num_of_rows: usize) usize {
            const overlap: usize = if (window_cols < row_width)
                @intFromFloat(@ceil(row_width / window_cols))
                else
                    1;

            // +2 for the top and bottom borders
            const total_lines_printed: usize = (num_of_rows * overlap);
            return total_lines_printed;
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

test "Remove one row" {
    std.debug.print("Remove one row\n", .{});

    const Row = struct {
        col1: []const u8,
        col2: []const u8,
        col3: []const u8,
        col4: []const u8,
    };

    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();

    try t.addRow(.{
        .col1 = "1",
        .col2 = "1",
        .col3 = "1",
        .col4 = "1",
    });
    try t.addRow(.{
        .col1 = "2",
        .col2 = "2",
        .col3 = "2",
        .col4 = "2",
    });

    t.removeRow(0);

    try expect(std.mem.eql(u8, t.rows.items[0].col1, "2"));
}

test "Count amount of rows printed" {
    std.debug.print("Count amount of rows printed\n", .{});

    const Row = struct {
        col1: []const u8,
        col2: []const u8,
        col3: []const u8,
        col4: []const u8,
    };

    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();

    try t.addRow(.{
        .col1 = "1",
        .col2 = "1",
        .col3 = "1",
        .col4 = "1",
    });
    try t.addRow(.{
        .col1 = "2",
        .col2 = "2",
        .col3 = "2",
        .col4 = "2",
    });
    
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(test_gpa);

    const wr = result.writer(test_gpa);

    try t.printTable(wr);

    try expect(t.lines_printed == 4);
    try expect(std.mem.eql(u8, result.items[0..17], "+---+---+---+---+"));
}

test "Count amount of rows cleared" {
    std.debug.print("Count amount of rows cleared\n", .{});

    const Row = struct {
        col1: []const u8,
        col2: []const u8,
        col3: []const u8,
        col4: []const u8,
    };

    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();

    try t.addRow(.{
        .col1 = "1",
        .col2 = "1",
        .col3 = "1",
        .col4 = "1",
    });
    try t.addRow(.{
        .col1 = "2",
        .col2 = "2",
        .col3 = "2",
        .col4 = "2",
    });
    
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(test_gpa);

    const wr = result.writer(test_gpa);
    try t.printTable(wr);

    try t.clear(wr);

    try expect(t.lines_printed == 4);
    try expect(std.mem.eql(u8, result.items[result.items.len - 7..], "\x1b[A\x1b[2K"));
    try expect(std.mem.eql(u8, result.items[result.items.len - 14..result.items.len - 7], "\x1b[A\x1b[2K"));
    try expect(std.mem.eql(u8, result.items[result.items.len - 21..result.items.len - 14], "\x1b[A\x1b[2K"));
    try expect(std.mem.eql(u8, result.items[result.items.len - 28..result.items.len - 21], "\x1b[A\x1b[2K"));
    try expect(result.items[28] != 'K');
}

test "Count amount of rows cleared on custom table" {
    std.debug.print("Count amount of rows cleared on custom table\n", .{});

    const Row = struct {
        col1: []const u8,
        col2: []const u8,
        col3: []const u8,
        col4: []const u8,
    };

    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();

    try t.addRow(.{
        .col1 = "1",
        .col2 = "1",
        .col3 = "1",
        .col4 = "1",
    });
    try t.addRow(.{
        .col1 = "2",
        .col2 = "2",
        .col3 = "2",
        .col4 = "2",
    });
    
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(test_gpa);

    const wr = result.writer(test_gpa);

    try t.printBorder(Borders.top, wr);
    try t.printRow(0, wr);
    try t.printBorder(Borders.top, wr);
    for (1..t.rows.items.len) |idx| {
        try t.printRow(idx, wr);
    }
    try t.printBorder(Borders.bottom, wr);

    try t.clear(wr);

    try expect(t.lines_printed == 5);
    try expect(std.mem.eql(u8, result.items[result.items.len - 7..], "\x1b[A\x1b[2K"));
    try expect(std.mem.eql(u8, result.items[result.items.len - 14..result.items.len - 7], "\x1b[A\x1b[2K"));
    try expect(std.mem.eql(u8, result.items[result.items.len - 21..result.items.len - 14], "\x1b[A\x1b[2K"));
    try expect(std.mem.eql(u8, result.items[result.items.len - 28..result.items.len - 21], "\x1b[A\x1b[2K"));
    try expect(std.mem.eql(u8, result.items[result.items.len - 35..result.items.len - 28], "\x1b[A\x1b[2K"));
}

test "Count amount of rows with a wrapped table" {
    std.debug.print("Count amount of rows with a wrapped table\n", .{});

    const Row = struct {
        col1: []const u8,
    };

    const Table = GenerateTableType(Row);
    var t = try Table.init(test_gpa);
    defer t.deinit();

    try t.addRow(.{
        .col1 = "12",
    });
    try t.addRow(.{
        .col1 = "2",
    });
    
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(test_gpa);

    const wr = result.writer(test_gpa);
    try t.printTable(wr);

    try t.clear(wr);

    const fl_row_width: f32 = @floatFromInt(t.getTotalTableWidth());
    const fl_window_cols: f32 = @floatFromInt(try log.getWindowCols());

    const total_lines_printed = Table.calculateTotalRows(
        fl_row_width, fl_window_cols, t.lines_printed
    );

    try expect(total_lines_printed == 8);
    try expect(std.mem.eql(u8, result.items[result.items.len - 56..result.items.len - 49], "\x1b[A\x1b[2K"));
}
