const std = @import("std");

const Command = enum { Exit, Add, Subtract, Multiply, Divide, Help, Unknown };

fn parseCommand(input: []const u8) Command {
    if (std.mem.eql(u8, input, "exit")) {
        return Command.Exit;
    } else if (std.mem.eql(u8, input, "+")) {
        return Command.Add;
    } else if (std.mem.eql(u8, input, "-")) {
        return Command.Subtract;
    } else if (std.mem.eql(u8, input, "*")) {
        return Command.Multiply;
    } else if (std.mem.eql(u8, input, "/")) {
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
    if (input.len != 3) {
        return error.InvalidInput;
    }

    const first: i32 = try castAsInt(input[0]);
    const second: i32 = try castAsInt(input[2]);
    const sum: i32 = first + second;

    return try intToString(sum, allocator);
}

fn subtraction(input: [][]const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len != 3) {
        return error.InvalidInput;
    }

    const first: i32 = try castAsInt(input[0]);
    const second: i32 = try castAsInt(input[2]);
    const difference: i32 = first - second;

    return try intToString(difference, allocator);
}

fn multiplication(input: [][]const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len != 3) {
        return error.InvalidInput;
    }

    const first: i32 = try castAsInt(input[0]);
    const second: i32 = try castAsInt(input[2]);
    const product: i32 = first * second;

    return try intToString(product, allocator);
}

fn division(input: [][]const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len != 3) {
        return error.InvalidInput;
    }

    const first: f32 = try castAsFloat(input[0]);
    const second: f32 = try castAsFloat(input[2]);

    if (@abs(second) < 1e-10) {
        return error.DivisionByZero;
    }

    const quotient: f32 = first / second;

    return try floatToString(quotient, allocator);
}
