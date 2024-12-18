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
		return c.parse_error_custom('unexpected term ${c.current_token.token}, should be ${token}',
			c.current_token)
	}
}

fn (mut c Compiler) maybe_match_next(tokens []Token) !Token {
	c.next_token()
	if c.current_token.token in tokens {
		return c.current_token.token
	} else {
		return c.parse_error_custom('unexpected term ${c.current_token.token}, should be in ${tokens}',
			c.current_token)
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
		.import {
			c.match_next(.module_name)!
			token := c.current_token
			mut args := []NodeEl{}
			for c.peak_token.token == .comma {
				c.next_token()
				c.next_token() // fix this double caller
				args << c.parse_expr()!
			}
			c.imports << Import{
				token: token
				args:  args
			}
			return c.parse_stmt()!
		}
		.alias {
			c.match_next(.module_name)!
			token := c.current_token
			mut args := []NodeEl{}
			for c.peak_token.token == .comma {
				c.next_token()
				c.next_token() // fix this double caller
				args << c.parse_expr()!
			}
			c.aliases << Alias{
				token: token
				args:  args
			}
			return c.parse_stmt()!
		}
		.def, .defp {
			return c.parse_function()!
		}
		else {
			return c.parse_expr()!
		}
	}
	return error('unhandled this error')
}

fn (mut c Compiler) parse_expr() !NodeEl {
	term := c.parse_term()!
	if c.peak_token.token == .operator {
		c.next_token()
		match c.current_token.bin {
			'=>' {
				c.next_token()
				value := c.parse_expr()!
				return Keyword{
					key:   term
					value: value
				}
			}
			'=' {
				// need to be check if is a matchble expression
				c.next_token()
				left := c.parse_expr()!
				type_id, type_match := match term {
					Node {
						if type_match := c.to_value_str(term.left) {
							term.type_id, type_match
						} else {
							term.type_id, ''
						}
					}
					else {
						0, ''
					}
				}
				return NodeEl(Node{
					left:            left
					right:           term
					is_should_match: true
					type_id:         type_id
					type_match:      type_match
				})
			}
			'in' {
				in_tok := c.current_token
				c.next_token()
				right := c.parse_expr()!
				return NodeEl(Node{
					left:  in_tok
					right: [term, right]
				})
			}
			'->' {
				// bypass to handle inside defined functions
				return term
			}
			else {
				return error('To do something with this operator `${c.current_token.bin}`')
			}
		}
	}
	return term
}

fn (mut c Compiler) parse_term() !NodeEl {
	match c.current_token.token {
		.module_name {
			return NodeEl(Node{
				left:  TokenRef{
					token: .__aliases__
				}
				right: [NodeEl(c.current_token)]
			})
		}
		.not {
			curr := c.current_token
			c.next_token()
			return NodeEl(Node{
				left:  curr
				right: c.parse_expr()!
			})
		}
		.cond {
			c.match_next(.do)!
			mut clauses := []NodeEl{}
			mut clauses_header := map[int]NodeEl{}
			mut clauses_body := map[int][]NodeEl{}
			mut i := 0
			for c.peak_token.token != .end {
				c.next_token()
				clause := c.parse_expr()!

				if c.current_token.token == .operator && c.current_token.bin == '->' {
					i++
					clauses_header[i] = clause
				} else {
					clauses_body[i] << clause
				}
			}
			c.match_next(.end)!
			for i0, clause in clauses_header {
				clauses << Node{
					left:  clause
					right: clauses_body[i0]
				}
			}
			return Node{
				left:  TokenRef{
					token: .cond
				}
				right: clauses
			}
		}
		.percent {
			// only for structs
			c.match_next(.lcbr)!
			mut keyword_list := []NodeEl{}
			// c.next_token()
			for c.peak_token.token != .rcbr {
				c.next_token()
				key_value := c.parse_expr()!
				keyword_list << key_value
				if c.peak_token.token == .comma {
					c.next_token()
				}
			}
			c.match_next(.rcbr)!
			return Node{
				left:  TokenRef{
					token: .percent
				}
				right: keyword_list
			}
		}
		.lsbr {
			// lists
			mut items := []NodeEl{}
			for c.peak_token.token != .rsbr {
				c.next_token()
				items << c.parse_expr()!
				if c.peak_token.token == .comma {
					c.next_token()
				}
			}
			c.match_next(.rsbr)!
			return items
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
						mut parse_until_function := true
						for parse_until_function {
							node0 := c.parse_stmt()!
							if node0 is Node {
								n := node0 as Node
								n_left := n.left as TokenRef
								if n_left.token == .def {
									parse_until_function = false
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
								ret := c.parse_expr()!
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
						// ident := c.parse_expr()!
						token := c.current_token
						c.next_token()
						value := c.parse_expr()!
						c.constants << Const{
							token: token
							value: value
						}
						return c.parse_stmt()!
						// c.match_next(.ident)!
						// c.match_next(.string)!
						// if moduledoc := c.get_string_value(c.current_token) {
						// 	c.moduledoc = moduledoc
						// 	return NodeEl(Node{left: TokenRef{token: .moduledoc}, right: [NodeEl(token), c.current_token]})
						// }
						// return c.parse_error_custom('not defined parse custom attribute for `${c.get_ident_value(c.current_token)}`', c.current_token)
					}
				}
			}
		}
		.caller_function {
			mut caller := c.current_token
			if c.peak_token.token == .lpar {
				c.next_token()

				mut inside_parens := -1
				mut args := []Arg{}
				for {
					if c.current_token.token == .lpar {
						inside_parens++
						c.next_token()
					}

					if c.current_token.token == .comma {
						c.next_token()
					} else if c.current_token.token == .rpar && inside_parens == 0 {
						break
					} else if c.current_token.token == .rpar {
						inside_parens--
						c.next_token()
					}
					arg := c.parse_expr()!
					if arg is Node {
						if ident := c.get_left_ident(arg.left) {
							match ident.token {
								.percent {
									// when is struct or map
									args << Arg{
										ident:             ident
										idents_from_match: c.extract_idents_from_match_expr(arg.right)!
										type:              arg.type_id
										type_match:        arg.type_match
										is_should_match:   arg.is_should_match
										match_expr:        arg.right
									}
								}
								else {
									args << Arg{
										ident:           ident
										type:            arg.type_id
										type_match:      arg.type_match
										is_should_match: arg.is_should_match
									}
								}
							}
						}
					}
					c.next_token()
				}

				if caller_name := c.get_ident_value(caller) {
					// args_bin := args.map(|a| a.clean_str()).join(',')
					hash := c.make_args_match_hash(args, NodeEl{})
					fn_hash := '${caller_name}/${hash}'
					if idx0 := c.functions_idx[fn_hash] {
						mut idx_caller := c.functions_caller.len
						mut new := true
						if idx_caller0 := c.functions_caller_idx[fn_hash] {
							idx_caller = idx_caller0
							new = false
						}
						c.functions_caller_idx[fn_hash] = idx_caller
						if new {
							c.functions_caller << &CallerFunction{
								name:         caller_name
								hash:         fn_hash
								line:         c.current_line
								char:         c.source.char - caller_name.len
								starts:       c.tokens.len
								function_idx: idx0
							}
						}
						caller.idx = idx0
						caller.table = .functions_caller
					} else {
						mut idx_caller := c.functions_caller_undefined.len
						mut new := true
						if idx_caller0 := c.functions_caller_undefined_idx[fn_hash] {
							idx_caller = idx_caller0
							new = false
						}
						caller.idx = idx_caller
						caller.table = .functions_caller_undefined
						c.functions_caller_undefined_idx[fn_hash] = idx_caller
						if new {
							c.functions_caller_undefined << &CallerFunction{
								name:   caller_name
								hash:   fn_hash
								line:   c.source.line
								char:   c.source.char - caller_name.len
								starts: c.tokens.len
								// function_idx: idx0
							}
						}
					}
				}
			}
			return NodeEl(caller)
		}
		.colon {
			if c.peak_token.token == .ident {
				c.next_token()
				return NodeEl(c.current_token)
			}
		}
		.ident {
			ident := c.current_token
			mut type_id := 0
			if c.peak_token.token == .colon {
				// is list
				mut keyword_list := []NodeEl{}
				for {
					c.next_token()
					c.next_token()
					value := c.parse_expr()!
					keyword_list << NodeEl(Keyword{ident, value})
					if c.peak_token.token != .comma {
						break
					}
				}
				// parse_list
				return NodeEl(keyword_list)
			}
			if c.peak_token.token == .typespec {
				c.next_token()
				c.match_next(.ident)!
				ident_type0 := c.current_token
				if ident_type := c.get_ident_value(ident_type0) {
					type_id = c.types.len
					type_idx0 := c.types.index(ident_type)
					if type_idx0 != -1 {
						type_id = type_idx0
					} else {
						c.types << ident_type
					}
				}
			}
			if c.peak_token.token == .default_arg {
				// fix default here
				c.next_token()
				c.next_token()
				value := c.parse_expr()!
				return NodeEl(Node{
					left:    NodeEl(ident)
					right:   value
					type_id: type_id
				})
			}
			if nil_ := c.get_ident_value(ident) {
				if nil_ == 'nil' {
					type_id = c.types.index('nil')
				}
			}
			return NodeEl(Node{
				left:    NodeEl(ident)
				type_id: type_id
			})
		}
		.float {
			return NodeEl(Node{
				left:    NodeEl(c.current_token)
				type_id: c.types.index('float')
			})
		}
		.integer {
			return NodeEl(Node{
				left:    NodeEl(c.current_token)
				type_id: c.types.index('integer')
			})
		}
		.string {
			return NodeEl(Node{
				left:    NodeEl(c.current_token)
				type_id: c.types.index('string')
			})
		}
		else {}
	}
	return c.parse_error('parse_expr()', c.current_token)
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

fn (c Compiler) parse_error(func string, token TokenRef) IError {
	return error('[${c.filesource}:${token.pos_line}:${token.pos_char}] `${func}` not defined for ${token}')
}

fn (c Compiler) parse_error_custom(str string, token TokenRef) IError {
	return error('[${c.filesource}:${token.pos_line}:${token.pos_char}] ${str}')
}
