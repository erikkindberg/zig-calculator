const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var buf: [256]u8 = undefined;

    while (true) {
        try stdout.print("Enter a command (or 'exit' to quit): ", .{});
        const line = try stdin.readUntilDelimiterOrEof(&buf, '\n');

        if (line) |actualLine| {
            const input = std.mem.trimRight(u8, actualLine, "\r\n");
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer _ = gpa.deinit();
            const allocator = gpa.allocator();
            var lexer = Lexer.init(input, allocator);
            var tokens = try lexer.scanTokens();
            defer tokens.deinit();

            var parser = Parser.init(tokens.items);
            const result = try parser.parse();

            std.debug.print("Result: {d}\n", .{result});
        }
    }
}
