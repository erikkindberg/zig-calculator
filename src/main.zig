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

            // First, handle the exit command early
            if (std.mem.eql(u8, input, "exit")) {
                std.debug.print("Exiting program...\n", .{});
                break;
            }

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
            const result = parser.parse() catch |err| {
                std.debug.print("Error parsing expression: {s}\n", .{@errorName(err)});
                continue; // Skip to the next command, don't try to save variables
            };

            if (parts_slice.len >= 2) {
                const var_name = std.mem.trim(u8, parts_slice[1], " \t\r\n");

                // Create a key_copy inside a scope with a defer to handle errors
                const key_copy = blk: {
                    const kc = allocator.dupe(u8, var_name) catch {
                        std.debug.print("Memory allocation failed for variable name\n", .{});
                        continue; // Skip to next command
                    };
                    break :blk kc;
                };

                // Use an errdefer to free key_copy if map.put fails
                errdefer allocator.free(key_copy);

                // Store the result in the HashMap
                map.put(key_copy, result, allocator) catch |err| {
                    // HashMap put failed, free the key_copy
                    allocator.free(key_copy);
                    std.debug.print("Error saving variable: {s}\n", .{@errorName(err)});
                    continue;
                };

                try stdout.print("Result: {d}\nSaved to variable: {s}\n", .{ result, var_name });
            } else {
                try stdout.print("Result: {d}\n", .{result});
            }

            map.printAllKeys();
        }
    }
}
