const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const HashMap = @import("hashmap.zig").HashMap;

pub fn main() !void {
    var hashmap_allocator = std.heap.page_allocator;

    var map = try HashMap.init(&hashmap_allocator, 10);
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

            var parts_list = std.ArrayList([]const u8).init(hashmap_allocator);
            defer parts_list.deinit();

            while (parts.next()) |x| {
                try parts_list.append(x);
            }

            const parts_slice = parts_list.items;

            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer _ = gpa.deinit();

            const allocator = gpa.allocator();

            var lexer = Lexer.init(parts_slice[0], allocator, &map);

            var tokens = try lexer.scanTokens();
            defer tokens.deinit();

            var parser = Parser.init(tokens.items);
            const result = try parser.parse();

            if (parts_slice.len >= 2) {
                try map.put(parts_slice[1], result);
                try stdout.print("Result: {d}\nSaved to variable: {s}\n", .{ result, parts_slice[1] });
            } else {
                try stdout.print("Result: {d}\n", .{result});
            }
        }
    }
}
