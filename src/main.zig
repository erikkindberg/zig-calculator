const std = @import("std");

const Command = enum { Exit, Add, Subtract, Multiply, Divide, Help, Unknown };

fn parseCommand(input: []const u8) Command {
    if (std.mem.eql(u8, input, "exit")) {
        return Command.Exit;
    } else if (std.mem.eql(u8, input, "add")) {
        return Command.Add;
    } else if (std.mem.eql(u8, input, "subtract")) {
        return Command.Subtract;
    } else if (std.mem.eql(u8, input, "multiply")) {
        return Command.Multiply;
    } else if (std.mem.eql(u8, input, "divide")) {
        return Command.Divide;
    } else if (std.mem.eql(u8, input, "help")) {
        return Command.Help;
    } else {
        return Command.Unknown;
    }
}

fn castAsInt(input: []const u8) !i32 {
    return std.fmt.parseInt(i32, input, 10);
}

fn castAsFloat(input: []const u8) !f32 {
    return std.fmt.parseFloat(f32, input);
}

fn intToString(value: i32, allocator: std.mem.Allocator) ![]const u8 {
    const result = try std.fmt.allocPrint(allocator, "{d}", .{value});
    return result;
}

fn floatToString(value: f32, allocator: std.mem.Allocator) ![]const u8 {
    const result = try std.fmt.allocPrint(allocator, "{d:.2}", .{value});
    return result;
}

fn addition(input: [][]const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len != 2) {
        return error.InvalidInput;
    }

    const first: i32 = try castAsInt(input[0]);
    const second: i32 = try castAsInt(input[1]);
    const sum: i32 = first + second;

    return try intToString(sum, allocator);
}

fn subtraction(input: [][]const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len != 2) {
        return error.InvalidInput;
    }

    const first: i32 = try castAsInt(input[0]);
    const second: i32 = try castAsInt(input[1]);
    const difference: i32 = first - second;

    return try intToString(difference, allocator);
}

fn multiplication(input: [][]const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len != 2) {
        return error.InvalidInput;
    }

    const first: i32 = try castAsInt(input[0]);
    const second: i32 = try castAsInt(input[1]);
    const product: i32 = first * second;

    return try intToString(product, allocator);
}

fn division(input: [][]const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len != 2) {
        return error.InvalidInput;
    }

    const first: f32 = try castAsFloat(input[0]);
    const second: f32 = try castAsFloat(input[1]);

    if (@abs(second) < 1e-10) {
        return error.DivisionByZero;
    }

    const quotient: f32 = first / second;

    return try floatToString(quotient, allocator);
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var buf: [256]u8 = undefined;

    const allocator = std.heap.page_allocator;

    while (true) {
        try stdout.print("Enter a command (or 'exit' to quit): ", .{});

        const line = try stdin.readUntilDelimiterOrEof(&buf, '\n');

        if (line) |actualLine| {
            const input = std.mem.trimRight(u8, actualLine, "\r\n");
            var iterator = std.mem.tokenizeAny(u8, input, " \t\n\r");

            var tokens = std.ArrayList([]const u8).init(allocator);

            while (iterator.next()) |token| {
                try tokens.append(token);
            }
            defer tokens.deinit();

            std.debug.print("tokens: {s}\n", .{tokens.items});

            const command = parseCommand(tokens.items[0]);

            switch (command) {
                Command.Exit => try stdout.print("Exit\n", .{}),
                Command.Add => {
                    const result = try addition(tokens.items[1..], allocator);
                    try stdout.print("{s}\n", .{result});
                },
                Command.Subtract => {
                    const result = try subtraction(tokens.items[1..], allocator);
                    try stdout.print("{s}\n", .{result});
                },
                Command.Multiply => {
                    const result = try multiplication(tokens.items[1..], allocator);
                    try stdout.print("{s}\n", .{result});
                },
                Command.Divide => {
                    const result = try division(tokens.items[1..], allocator);
                    try stdout.print("{s}\n", .{result});
                },
                Command.Help => try stdout.print("Help\n", .{}),
                Command.Unknown => try stdout.print("Unknown Command\n", .{}),
            }
        } else {
            break;
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
