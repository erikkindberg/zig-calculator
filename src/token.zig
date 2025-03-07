pub const TokenType = enum {
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
pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: ?f64,

    pub fn init(token_type: TokenType, lexeme: []const u8, literal: ?f64) Token {
        return Token{
            .type = token_type,
            .lexeme = lexeme,
            .literal = literal,
        };
    }
};
