pub const TokenType = enum {
    Number,
    Constant,
    Plus,
    Minus,
    Star,
    Slash,
    LeftParen,
    RightParen,
    EOF,
};

pub const Literal = union {
    Float: f64,
    String: []const u8,
};

// Token structure
pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: ?Literal,

    pub fn init(token_type: TokenType, lexeme: []const u8, literal: ?Literal) Token {
        return Token{
            .type = token_type,
            .lexeme = lexeme,
            .literal = literal,
        };
    }
};
