module compiler

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
			c.module_name = c.current_token
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
			function_name := c.current_token
			mut right := [c.current_token.to_node()]
			tk := c.maybe_match_next([.typespec, .do, .rpar])!
			match tk {
				.typespec {
					c.match_next(.ident)!
					c.put_returns_into_function(function_name.idx)!
					c.next_token()
				}
				.rpar {
					// parse args`
				}
				else {}
			}

			mut right0 := []NodeEl{}
			if c.peak_token.token != .end {
				do := TokenRef{
					token: .do
				}
				parsed := c.parse_stmt()!
				right0 << parsed
				right << NodeEl(Keyword{do, parsed})
			}
			c.match_next(.end)!
			c.functions_body[function_name.idx] = right0
			return Node{
				left:  left
				right: right
			}
		}
		.arroba {
			c.match_next(.ident)!
			if attribute := c.get_ident_value(c.current_token) {
				match attribute {
					'moduledoc' {
						token := c.current_token
						c.match_next(.string)!
						if moduledoc := c.get_string_value(c.current_token) {
							c.moduledoc = moduledoc
							return NodeEl(Node{
								left:  TokenRef{
									token: .moduledoc
								}
								right: [NodeEl(token), c.current_token]
							})
						}
					}
					'doc' {
						mut docstr := ''
						c.match_next(.string)!
						if doc := c.get_string_value(c.current_token) {
							docstr = doc
						}
						mut next_not_is_function := true
						for next_not_is_function {
							node0 := c.parse_stmt()!
							if node0 is Node {
								n := node0 as Node
								n_left := n.left as TokenRef
								if n_left.token == .def {
									next_not_is_function = true
									n_right := n.right as []NodeEl
									n_right0 := n_right[0] as Node
									n_right0_left := n_right0.left as TokenRef
									if function := c.get_function_value(n_right0_left) {
										c.function_doc[function.name] = docstr
										return node0
									} else {
										return error('not found function')
									}
								}
							}
						}

						println('error not found function')
					}
					'spec' {
						c.match_next(.ident)!
						if atom := c.get_ident_value(c.current_token) {
							if function_idx := c.functions_idx[atom] {
								c.match_next(.typespec)!
								c.next_token()
								ret := c.parse_script()!
								if ret is TokenRef && ret.token == .ident {
									if ident0 := c.idents[ret.idx] {
										mut type_idx := c.types.len
										type_idx0 := c.types.index(ident0)
										if type_idx0 != -1 {
											type_idx = type_idx0
										} else {
											c.types << ident0
										}
										c.functions[function_idx].returns = type_idx
									}
								}
							}
						}
						token := c.current_token
						return NodeEl(token)
					}
					else {
						// token := c.current_token
						// c.match_next(.string)!
						// if moduledoc := c.get_string_value(c.current_token) {
						// 	c.moduledoc = moduledoc
						// 	return NodeEl(Node{left: TokenRef{token: .moduledoc}, right: [NodeEl(token), c.current_token]})
						// }
						println('not defined for other attribute')
					}
				}
			}
		}
		else {
			return c.parse_script()!
		}
	}
	return error('unhandled this error')
}

fn (mut c Compiler) parse_script() !NodeEl {
	match c.current_token.token {
		.ident {
			return NodeEl(c.current_token)
		}
		.float {}
		.integer {
			return NodeEl(c.current_token)
		}
		.caller_function {}
		else {}
	}
	return error('finish parse script in token ${c.current_token.token}  ')
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

fn (mut c Compiler) put_returns_into_function(function_idx int) ! {
	if atom := c.get_ident_value(c.current_token) {
		mut type_idx := c.types.len
		type_idx0 := c.types.index(atom)
		if type_idx0 != -1 {
			type_idx = type_idx0
		} else {
			c.types << atom
		}
		c.functions[function_idx].returns = type_idx
	}
}
