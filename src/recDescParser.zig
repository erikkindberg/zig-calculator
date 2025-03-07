const std = @import("std");
const Allocator = std.mem.Allocator;

// Token types
const TokenType = enum {
    Number,
    Plus,
    Minus,
    Star,
    Slash,
    LeftParen,
    RightParen,
    EOF,
};

// Token structure
const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: ?f64,

    fn init(token_type: TokenType, lexeme: []const u8, literal: ?f64) Token {
        return Token{
            .type = token_type,
            .lexeme = lexeme,
            .literal = literal,
        };
    }
};

// Lexer structure
const Lexer = struct {
    source: []const u8,
    tokens: std.ArrayList(Token),
    start: usize,
    current: usize,
    allocator: Allocator,

    fn init(source: []const u8, allocator: Allocator) Lexer {
        return Lexer{
            .source = source,
            .tokens = std.ArrayList(Token).init(allocator),
            .start = 0,
            .current = 0,
            .allocator = allocator,
        };
    }

    fn scanTokens(self: *Lexer) !std.ArrayList(Token) {
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
        while (true) {
            const c = self.peek();
            if (c == null or !isDigit(c.?)) break;
            _ = self.advance();
        }

        // Look for a decimal part
        if (self.peek() != null and self.peek().? == '.') {
            // Check if the next character is a digit
            const next = self.peekNext();
            if (next != null and isDigit(next.?)) {
                // Consume the "."
                _ = self.advance();

                // Consume digits after decimal
                while (true) {
                    const c = self.peek();
                    if (c == null or !isDigit(c.?)) break;
                    _ = self.advance();
                }
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

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

const ParserError = error{
    ParseError,
    UnexpectedToken,
    MissingRightParen,
    InvalidNumber,
    OutOfMemory,
};

// Parser structure
const Parser = struct {
    tokens: []Token,
    current: usize,

    fn init(tokens: []Token) Parser {
        return Parser{
            .tokens = tokens,
            .current = 0,
        };
    }

    fn parse(self: *Parser) !f64 {
        return try self.expression();
    }

    fn expression(self: *Parser) ParserError!f64 {
        var result = try self.term();

        while (self.match(&[_]TokenType{ TokenType.Plus, TokenType.Minus })) {
            const operator = self.previous().type;
            const right = try self.term();

            result = switch (operator) {
                TokenType.Plus => result + right,
                TokenType.Minus => result - right,
                else => unreachable,
            };
        }

        return result;
    }

    fn term(self: *Parser) !f64 {
        var result = try self.factor();

        while (self.match(&[_]TokenType{ TokenType.Star, TokenType.Slash })) {
            const operator = self.previous().type;
            const right = try self.factor();

            result = switch (operator) {
                TokenType.Star => result * right,
                TokenType.Slash => result / right,
                else => unreachable,
            };
        }

        return result;
    }

    fn factor(self: *Parser) !f64 {
        if (self.match(&[_]TokenType{TokenType.Number})) {
            return self.previous().literal.?;
        }

        if (self.match(&[_]TokenType{TokenType.LeftParen})) {
            const expr = try self.expression();
            _ = try self.consume(TokenType.RightParen, "Expect ')' after expression.");
            return expr;
        }

        return error.ParseError;
    }

    fn match(self: *Parser, types: []const TokenType) bool {
        for (types) |t| {
            if (self.check(t)) {
                _ = self.advance();
                return true;
            }
        }

        return false;
    }

    fn consume(self: *Parser, t: TokenType, message: []const u8) !Token {
        if (self.check(t)) return self.advance();

        std.debug.print("Parse error: {s}\n", .{message});
        return error.ParseError;
    }

    fn check(self: *Parser, t: TokenType) bool {
        if (self.isAtEnd()) return false;
        return self.peek().type == t;
    }

    fn advance(self: *Parser) Token {
        if (!self.isAtEnd()) self.current += 1;
        return self.previous();
    }

    fn isAtEnd(self: *Parser) bool {
        return self.peek().type == TokenType.EOF;
    }

    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }

    fn previous(self: *Parser) Token {
        return self.tokens[self.current - 1];
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source = "3.14 * (2 + 4) / 3";
    var lexer = Lexer.init(source, allocator);
    var tokens = try lexer.scanTokens();
    defer tokens.deinit();

    std.debug.print("Tokens:\n", .{});
    for (tokens.items, 0..) |token, i| {
        // Print token type
        std.debug.print("{d}: Type: {s}", .{ i, @tagName(token.type) });

        // Print lexeme
        std.debug.print(", Lexeme: '{s}'", .{token.lexeme});

        // Print literal value if exists
        if (token.literal) |value| {
            std.debug.print(", Value: {d}", .{value});
        }

        std.debug.print("\n", .{});
    }

    var parser = Parser.init(tokens.items);
    const result = try parser.parse();

    std.debug.print("Result: {d}\n", .{result});
}
