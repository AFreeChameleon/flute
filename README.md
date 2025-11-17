# Flute
A lightweight, modular and simple library for generating tables and formatting text in the terminal.

This package was designed with simplicity and control over utility.

Works on:
- Windows
- Macos
- Linux
- FreeBSD

## Installation & Usage

This works on Zig versions 0.14 and 0.15. To fetch the package, run:
```
zig fetch --save git+https://github.com/AFreeChameleon/flute/#0.14
```

And in your `build.zig` add these lines underneath where your exe_mod is defined:
```
const flute = b.dependency("flute", .{
    .target = target,
    .optimize = optimize
});
const flute_mod = flute.module("flute");

exe_mod.addImport("flute", flute_mod);
```

And now, you can import flute!
```
const flute = @import("flute");
```

## Tables
To get started, make a struct with every property being a string, this will be your row layout.
```
const Row = struct {
    first_name: []const u8,
    last_name: []const u8,
    date_of_birth: []const u8,
    favourite_food: []const u8,
};
```

And plug this into the `GenerateTableType` function. It's a comptime function so you can create it right underneath your row declaration!
```
const flute = @import("flute");

const Table = flute.table.GenerateTableType(Row);
```

Now to initialize the table, just run `.init` on the Table type. Also don't forget to run `.deinit` after it's used.
```
const gpa = std.heap.page_allocator;
var t = try Table.init(gpa); 
defer t.deinit();
```
NOTE: `.deinit` doesn't free any column strings.

To add rows, create a struct of your row type and put it into the `.addRow` function. To print the table, run `.printTable`:

```
const row = Row {
    first_name: "John",
    last_name: "Doe",
    date_of_birth: "01/01/2000",
    favourite_food: "Fries",
};

try t.addRow(row);
try t.printTable();
```

Here's a full working example for you:
```
const std = @import("std");
const flute = @import("flute");

const Row = struct {
    first_name: []const u8,
    last_name: []const u8,
    date_of_birth: []const u8,
    favourite_food: []const u8,
};
const Table = flute.table.GenerateTableType(Row);

fn main() !void {
    const gpa = std.heap.page_allocator;
    const t = Table.init(gpa);
    defer t.deinit();

    try t.addRow(.{
        first_name: "John",
        last_name: "Doe",
        date_of_birth: "01/01/2000",
        favourite_food: "Fries",
    });
    try t.addRow(.{
        first_name: "Jane",
        last_name: "Doe",
        date_of_birth: "01/01/2000",
        favourite_food: "Fries",
    });
    try t.printTable();
}
```

### Borders
To change the table borders, all you'll need to do is edit the `Borders` struct and put in your own values.

```
flute.table.Borders.top = flute.table.Borders.Chars {
    .left = "┌",
    .right = "┐",
    .separator = "┬"
};
flute.table.Borders.bottom = flute.table.Borders.Chars {
    .left = "└",
    .right = "┘",
    .separator = "┴",
};
flute.table.Borders.hori_line = "─";
flute.table.Borders.vert_line = "│";
```

### Custom layout
"I want to make my table have a border underneath my headers"

While there isn't a specific function to cater to this customisation, what I instead looked to do was
make it easy to make whatever you want rather than using the built in `printTable` function.

Take the example from before, how would I be able to add a border in between the two?
```
try t.addRow(.{
    first_name: "John",
    last_name: "Doe",
    date_of_birth: "01/01/2000",
    favourite_food: "Fries",
});
try t.addRow(.{
    first_name: "Jane",
    last_name: "Doe",
    date_of_birth: "01/01/2000",
    favourite_food: "Fries",
});

try t.printBorder(flute.Borders.top, wr);
try t.printRow(0, wr);
// Or whatever characters you'd like
try t.printBorder(flute.Borders.top, wr);
for (1..t.rows.items.len) |idx| {
    try t.printRow(idx, wr);
}
try t.printBorder(flute.Borders.bottom, wr);
```

## String formatting
These are a couple of functions to color, highlight and format strings for your terminal.

They come in both `Alloc` and `Buf` for allocators and buffers.

To color or highlight text, run these functions passing in rgb values:
```
const flute = @import("flute");

const gpa = std.heap.page_allocator;

const purple_text = try flute.format.string.colorStringAlloc(gpa, "this is purple", 128, 0, 128);
defer gpa.free(purple_text);

const highlight_purple_text = try flute.format.string.highlightStringAlloc(gpa, "this is highlighted purple", 128, 0, 128);
defer gpa.free(highlight_purple_text);
```

To format strings in either:
- Bold
- Dim
- Underline
- Blink
- Reverse (invert the foreground and background colors)
- Hidden
Run this:
```
var buf: [256]u8 = std.mem.zeroes([256]u8);
const str = "test string";
const buf_slice = try flute.format.string.formatStringBuf(&buf, str, .Bold);
```

# License

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Flute is under the GPL v3 license.
