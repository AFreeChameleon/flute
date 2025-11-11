# Flute
A lightweight, modular and simple library for generating tables and formatting text in the terminal.

## Tables
Tables were designed with simplicity in mind and having control over utility.

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
const Table = GenerateTableType(Row);
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

## String formatting
These are a couple of functions to color, highlight and format strings for your terminal.
