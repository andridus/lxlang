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
		return c.parse_error_custom('unexpected term ${c.current_token.token}, should be ${token}', c.current_token)
	}
}

fn (mut c Compiler) maybe_match_next(tokens []Token) !Token {
	c.next_token()
	if c.current_token.token in tokens {
		return c.current_token.token
	} else {
		return c.parse_error_custom('unexpected term ${c.current_token.token}, should be in ${tokens}', c.current_token)
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
				args << c.parse_script()!
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
				args << c.parse_script()!
			}
			c.aliases << Alias{
				token: token
				args:  args
			}
			return c.parse_stmt()!
		}
		.def {
			left := c.current_token.to_node()

			mut args := []Arg{}
			mut default_args := map[Token]NodeEl{}
			c.match_next(.function_name)!
			function_name := c.current_token
			mut idx_function := 0
			if name := c.get_ident_value(function_name){
				if idx_function0 := c.functions_idx[name]{
					idx_function = idx_function0
				}
			}
			println(idx_function)
			mut right := [c.current_token.to_node()]

			match c.peak_token.token {
				.typespec {
					c.next_token()
					c.match_next(.ident)!
					c.put_returns_into_function(function_name.idx)!
					c.next_token()
				}
				.lpar {
					c.next_token()
					mut args_ident := map[int]TokenRef{}
					mut args_type := map[int]TokenRef{}
					mut default_args0 := []TokenRef{}
					mut default_values0 := []NodeEl{}
					mut i := -1
					// get args token

					mut is_typespec := false
					for {
						if c.peak_token.token == .rpar {
							break
						} else if c.peak_token.token == .typespec {
							c.next_token()
							is_typespec = true
						} else if c.current_token.token == .ident && is_typespec {
							args_type[i] = c.current_token
							is_typespec = false
						} else if c.current_token.token == .ident {
							i++
							args_ident[i] = c.current_token
							if c.peak_token.token == .default_arg {
								c.next_token()
								c.next_token()

								default_args0 << args_ident[i]
								default_values0 << c.parse_script()!
								continue
							}
						}  else if c.peak_token.token == .comma {
							c.next_token()
						}
						c.next_token()
					}

					// prepare function args
					println(args_ident)

					for k, arg_token in args_ident {
						if type_value := args_type[k] {
							if ident := c.idents[type_value.idx] {
								mut type_idx := c.types.len
								type_idx0 := c.types.index(ident)
								if type_idx0 != -1 {
									type_idx = type_idx0
								} else {
									c.types << ident
								}
								args << Arg{
									token: arg_token
									type:  type_idx
								}
							}
						} else {
							args << Arg{
								token: arg_token
								type:  0
							}
						}
					}

					for i0, key in default_args0 {
						default_args[key.token] = default_values0[i0]
					}
					// maybe get the return
					c.match_next(.rpar)!

					if c.peak_token.token == .typespec {
						c.match_next(.ident)!
						token1 := c.current_token
						if ident := c.idents[token1.idx] {
							mut type_idx := c.types.len
							type_idx0 := c.types.index(ident)
							if type_idx0 != -1 {
								type_idx = type_idx0
							} else {
								c.types << ident
							}
							c.functions[c.in_function_id].returns = type_idx
						}
					}

				}
				else {}
			}

			mut args_str := []string{}
			for a in args {
				if type_ := c.types[a.type] {
					args_str << type_
				}
			}
			hashed := args_str.join('|')
			println(hashed)
			// println(c.tokens)
			if _ := c.functions[idx_function].matches[hashed] {
				return error("Function ${hashed} already defined")
			} else {
				if c.peak_token.token != .def {
					c.functions[idx_function].matches[hashed] = FunctionMatch {
						default_args: default_args
						args: args
					}
				}
			}
			// println(c.functions)
			mut right0 := []NodeEl{}
			mut has_ending_function := true
			if c.peak_token.token == .comma {
				c.next_token()
				c.match_next(.do)!
				c.match_next(.colon)!
				c.next_token()
				has_ending_function = false

			} else if c.peak_token.token == .do {
				c.next_token()

			} else if c.peak_token.token == .def {
				c.functions[idx_function].args = args
				mut functions := []NodeEl{}
				for c.peak_token.token == .def {
					functions << c.parse_stmt()!
					// c.next_token()
				}

				println(functions)
				return functions[0]

			} else {
				return error("missing function definition")
			}
			if c.current_token.token != .end {
				do := TokenRef{
					token: .do
				}
				parsed :=c.parse_script()!
				right0 << parsed
				right << NodeEl(Keyword{do, parsed})
			}
			if has_ending_function {
				c.match_next(.end)!
			}
			c.functions_body[function_name.idx] = right0
			return Node{
				left:  left
				right: right
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
		.module_name {
			return NodeEl(Node{
				left:  TokenRef{
					token: .__aliases__
				}
				right: [NodeEl(c.current_token)]
			})
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
						// ident := c.parse_script()!
						token := c.current_token
						c.next_token()
						value := c.parse_script()!
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
			caller := c.current_token
			if c.peak_token.token == .lpar {
				c.next_token()

				mut inside_parens := -1
				mut args := []NodeEl{}
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
					args << c.parse_script()!
					c.next_token()
				}

				if caller_name := c.get_ident_value(caller) {
					args_bin := args.map(|a| a.str()).join(',')
					fn_hash := '${caller_name}/${args_bin}'
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
								hash: fn_hash
								line:         c.current_line
								char:         c.source.char - caller_name.len
								starts:       c.tokens.len
								function_idx: idx0
							}
						}

					} else {
						mut idx_caller :=  c.functions_caller_undefined.len
						mut new := true
						if idx_caller0 := c.functions_caller_undefined_idx[fn_hash] {
							idx_caller = idx_caller0
							new = false
						}
						c.functions_caller_undefined_idx[fn_hash] = idx_caller
						if new {
							c.functions_caller_undefined << &CallerFunction{
								name:   caller_name
								hash: fn_hash
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

			if c.peak_token.token == .colon {
				// is list
				mut keyword_list := []NodeEl{}
				for {
					c.next_token()
					c.next_token()
					value := c.parse_script()!
					keyword_list << NodeEl(Keyword{ident, value})
					if c.peak_token.token != .comma {
						break
					}
				}
				// parse_list
				return NodeEl(keyword_list)
			} else {
				return NodeEl(c.current_token)
			}
		}
		.float {
			return NodeEl(c.current_token)
		}
		.integer {
			return NodeEl(c.current_token)
		}
		.string {
			return NodeEl(c.current_token)
		}
		else {}
	}
	println(c.tokens)
	return c.parse_error('parse_script()', c.current_token)
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
