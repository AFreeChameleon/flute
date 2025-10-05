//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");

const flute = @import("./table/index.zig");
const GenerateTableType = flute.GenerateTableType;

pub const Row = struct {
    id: []const u8,
    namespace: []const u8,
    command: []const u8,
    location: []const u8,
    pid: []const u8,
    status: []const u8,
    memory: []const u8,
    cpu: []const u8,
    runtime: []const u8,
    // child: bool,
    // header: bool,
    // table: *Table,

    pub fn init() Row {
        return Row {
            .id = "",
            .namespace = "",
            .command = "",
            .location = "",
            .pid = "",
            .status = "",
            .memory = "",
            .cpu = "",
            .runtime = "",
            // .child = false,
            // .header = false,
            // .table = t,
        };
    }
};

pub const Table = GenerateTableType(Row);


pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var table = try Table.init(allocator);
    var row = Row.init();
    row.id = "123";
    row.namespace = "namespacess";
    row.command = "command";
    row.location = "hihhihihihihihi";
    row.pid = "1";
    row.status = "online";
    row.memory = "gooby";
    row.cpu = "25%";
    row.runtime = "12 billion years";
    try table.add_row(row);
    var row1 = Row.init();
    row1.id = "123";
    row1.namespace = "namespacess";
    row1.command = "command";
    row1.location = "hihhihihihihifasdfsddasfshi";
    row1.pid = "1";
    row1.status = "online";
    row1.memory = "gooby";
    row1.cpu = "25%";
    row1.runtime = "12 billion years";
    try table.add_row(row1);
    try table.print_table();
}
