const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const HashMap = @import("hashmap.zig").HashMap;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var map = try HashMap.init(gpa.allocator(), 10);
    defer map.deinit();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var buf: [256]u8 = undefined;

    while (true) {
        try stdout.print("Enter a command (or 'exit' to quit): ", .{});
        const line = try stdin.readUntilDelimiterOrEof(&buf, '\n');

        if (line) |actualLine| {
            const input = std.mem.trimRight(u8, actualLine, "\r\n");

            const delimiter: u8 = ':';
            var parts = std.mem.splitScalar(u8, input, delimiter);

            var parts_list = std.ArrayList([]const u8).init(gpa.allocator());
            defer parts_list.deinit();

            while (parts.next()) |x| {
                try parts_list.append(x);
            }

            const parts_slice = parts_list.items;

            const allocator = gpa.allocator();

            var lexer = Lexer.init(parts_slice[0], allocator, &map);

            const tokens = try lexer.scanTokens();

            for (tokens.items) |token| {
                std.debug.print("Token: {s}\n", .{token.lexeme});
            }

            defer tokens.deinit();

            var parser = Parser.init(tokens.items, &map);
            const result = try parser.parse();

            if (parts_slice.len >= 2) {
                const var_name = std.mem.trim(u8, parts_slice[1], " \t\r\n");
                const key_copy = try allocator.dupe(u8, var_name);
                errdefer allocator.free(key_copy); // Add this

                if (map.put(key_copy, result, allocator)) |_| {
                    try stdout.print("Result: {d}\nSaved to variable: {s}\n", .{ result, var_name });
                } else |err| {
                    // HashMap put failed, free the key_copy
                    allocator.free(key_copy);
                    try stdout.print("Error saving variable: {s}\n", .{@errorName(err)});
                }
            } else {
                try stdout.print("Result: {d}\n", .{result});
            }

            map.printAllKeys();
        }
    }
}
