const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const HashMap = @import("hashmap.zig").HashMap;
const Literal = @import("token.zig").Literal;
const std = @import("std");

const ParserError = error{
    ParseError,
    UnexpectedToken,
    MissingRightParen,
    InvalidNumber,
    OutOfMemory,
    MissingLiteral,
    InvalidLiteralType,
};

pub const Parser = struct {
    tokens: []Token,
    current: usize,
    map: *HashMap,

    pub fn init(tokens: []Token, map: *HashMap) Parser {
        return Parser{
            .tokens = tokens,
            .current = 0,
            .map = map,
        };
    }

    pub fn parse(self: *Parser) !f64 {
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
            const literal = self.previous().literal;
            if (literal == null) {
                return error.MissingLiteral;
            }

            return switch (literal.?) {
                .Float => literal.?.Float,
                .String => {
                    const value = self.map.get(literal.?.String) orelse {
                        std.debug.print("Constant not found: {s}\n", .{literal.?.String});
                        return error.InvalidLiteralType;
                    };
                    return value;
                },
            };
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
