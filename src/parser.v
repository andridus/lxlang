fn (c Compiler) eof() bool {
	return c.current_position >= c.tokens.len
}

fn (c Compiler) eof_next() bool {
	return (c.current_position + 1) >= c.tokens.len
}

fn (mut c Compiler) next_token() {
	c.current_position++
	if !c.eof() {
		c.current_token = c.tokens[c.current_position]
		if !c.eof_next() {
			c.peak_token = c.tokens[c.current_position + 1]
		} else {
			c.peak_token = TokenRef{
				token: .eof
			}
		}
	}
}

fn (mut c Compiler) match_next(token Token) ! {
	c.next_token()
	if c.current_token.token != token {
		return error('unexpected term ${c.current_token.token}, should be ${token}')
	}
}

fn (mut c Compiler) maybe_match_next(tokens []Token) !Token {
	c.next_token()
	if c.current_token.token in tokens {
		return c.current_token.token
	} else {
		return error('unexpected term ${c.current_token.token}, should be in ${tokens}')
	}
}

fn (mut c Compiler) parse_stmt() !NodeEl {
	c.next_token()
	match c.current_token.token {
		.defmodule {
			left := c.current_token.to_node()
			c.match_next(.module_name)!
			mut right := c.current_token.to_node()

			c.match_next(.do)!

			mut elems := []NodeEl{}
			for !c.eof() {
				if c.peak_token.token == .end {
					break
				}
				right0 := c.parse_stmt()!
				elems << right0
			}
			right1 := into_block(elems)
			c.match_next(.end)!
			return Node{
				left:  left
				right: [right,
					[
						NodeEl(Keyword{TokenRef{
							token: .do
						}, right1}),
					]]
			}
		}
		.def {
			left := c.current_token.to_node()
			c.match_next(.function_name)!
			mut right := [c.current_token.to_node()]
			tk := c.maybe_match_next([.typespec, .do, .rpar])!
			match tk {
				.typespec {
					c.match_next(.ident)!
				}
				.rpar {
					// parse args`
				}
				else {}
			}

			if c.peak_token.token != .end {
				do := TokenRef{
					token: .do
				}
				right << NodeEl(Keyword{do, c.parse_stmt()!})
			}
			c.match_next(.end)!
			return Node{
				left:  left
				right: right
			}
		}
		.float {}
		.integer {
			return NodeEl(c.current_token)
		}
		.caller_function {}
		else {}
	}
	return error('finish')
}

fn into_block(elems []NodeEl) NodeEl {
	if elems.len == 1 {
		return elems[0]
	} else {
		return NodeEl(Node{
			left:  TokenRef{
				token: .__block__
			}
			right: elems
		})
	}
}
