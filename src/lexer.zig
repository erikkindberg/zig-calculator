const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const isDigit = @import("helperFunctions.zig").isDigit;
const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Lexer = struct {
    source: []const u8,
    tokens: std.ArrayList(Token),
    start: usize,
    current: usize,
    allocator: Allocator,

    pub fn init(source: []const u8, allocator: Allocator) Lexer {
        return Lexer{
            .source = source,
            .tokens = std.ArrayList(Token).init(allocator),
            .start = 0,
            .current = 0,
            .allocator = allocator,
        };
    }

    pub fn scanTokens(self: *Lexer) !std.ArrayList(Token) {
        while (!self.isAtEnd()) {
            // We are at the beginning of the next lexeme
            self.start = self.current;
            try self.scanToken();
        }

        try self.tokens.append(Token.init(TokenType.EOF, "", null));
        return self.tokens;
    }

    fn scanToken(self: *Lexer) !void {
        const c = self.advance();

        switch (c) {
            '(' => try self.addToken(TokenType.LeftParen),
            ')' => try self.addToken(TokenType.RightParen),
            '+' => try self.addToken(TokenType.Plus),
            '-' => try self.addToken(TokenType.Minus),
            '*' => try self.addToken(TokenType.Star),
            '/' => try self.addToken(TokenType.Slash),
            ' ', '\r', '\t', '\n' => {}, // Ignore whitespace
            else => {
                if (isDigit(c)) {
                    try self.number();
                } else {
                    std.debug.print("Unexpected character: {c}\n", .{c});
                }
            },
        }
    }

    fn number(self: *Lexer) !void {
        while (self.peek().? >= '0' and self.peek().? <= '9') {
            _ = self.advance();
        }

        // Look for a decimal part
        if (self.peek() == '.' and isDigit(self.peekNext() orelse '0')) {
            // Consume the "."
            _ = self.advance();

            while (isDigit(self.peek().?)) {
                _ = self.advance();
            }
        }

        const value = try std.fmt.parseFloat(f64, self.source[self.start..self.current]);
        try self.addTokenLiteral(TokenType.Number, value);
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Lexer) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn addToken(self: *Lexer, token_type: TokenType) !void {
        const text = self.source[self.start..self.current];
        try self.tokens.append(Token.init(token_type, text, null));
    }

    fn addTokenLiteral(self: *Lexer, token_type: TokenType, literal: f64) !void {
        const text = self.source[self.start..self.current];
        try self.tokens.append(Token.init(token_type, text, literal));
    }

    fn peek(self: *Lexer) ?u8 {
        if (self.isAtEnd()) return null;
        return self.source[self.current];
    }

    fn peekNext(self: *Lexer) ?u8 {
        if (self.current + 1 >= self.source.len) return null;
        return self.source[self.current + 1];
    }
};
