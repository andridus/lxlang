module compiler

fn (mut c Compiler) parse_function() !NodeEl {
	left := c.current_token.to_node()
	pos_line := c.current_token.pos_line
	pos_char := c.current_token.pos_char
	c.match_next(.function_name)!
	function_name := c.current_token
	fun := c.get_function_value(function_name) or {
		return c.parse_error('not found function', c.current_token)
	}

	idx_function := fun.idx

	mut right := [c.current_token.to_node()]
	args := c.maybe_parse_args() or { []Arg{} }
	type_idx := c.parse_typespec() or { 0 }
	guard := c.parse_guard() or { c_nil }
	mut vars := ['a', 'a.id', 'code', 'branch_country']
	for arg in args {
		if arg.is_should_match {
			vars << arg.idents_from_match
		} else {
			if v := c.get_ident_value(arg.ident) {
				vars << v
			}
		}
	}

	hashed := c.make_args_match_hash(args, guard)
	// Define functions arity (function matches)
	if _ := fun.matches[hashed] {
		return c.parse_error_custom('Function ${fun.name} ${hashed} already defined',
			c.current_token)
	} else if c.peak_token.token != .def {
		c.functions[idx_function].matches[hashed] = FunctionMatch{
			args:        args
			scoped_vars: vars
			guard:       guard
			pos_char:    pos_char
			pos_line:    pos_line
			returns:     type_idx
		}
	}
	mut right0 := []NodeEl{}
	mut function_has_end_token := true
	match true {
		c.peak_token.token == .comma {
			c.next_token()
			c.match_next(.do)!
			c.match_next(.colon)!
			c.next_token()
			function_has_end_token = false
		}
		c.peak_token.token == .do {
			c.match_next(.do)!
			c.next_token()
		}
		c.peak_token.token == .def {
			c.functions[idx_function].args = args
			mut functions := []NodeEl{}
			for c.peak_token.token == .def {
				functions << c.parse_stmt()!
			}
			// NOTE: Fix to return all functions body
			return functions[0]
		}
		else {
			return c.parse_error_custom('missing function definition', c.current_token)
		}
	}

	if c.current_token.token != .end {
		c.current_function_idx = fun.idx
		c.current_function_hashed = hashed
		parsed := c.parse_expr()!
		c.current_function_idx = -1
		c.current_function_hashed = ''
		right0 << parsed
		right << NodeEl(Keyword{TokenRef{
			token: .do
		}, parsed})
	}
	if function_has_end_token {
		c.match_next(.end)!
	}
	c.functions_body[function_name.idx] = right0
	return Node{
		left:  left
		right: right
	}
}

fn (mut c Compiler) maybe_parse_args() ?[]Arg {
	if c.peak_token.token == .lpar {
		mut args := []Arg{}
		mut default_args := []NodeEl{}
		mut default_args0 := []TokenRef{}
		mut default_values0 := []NodeEl{}
		c.in_function_args = true
		defer {
			c.in_function_args = false
		}
		c.match_next(.lpar) or { return none }
		for {
			if c.peak_token.token == .rpar {
				break
			}
			c.next_token()
			arg := c.parse_expr() or { return none }
			if arg is Node {
				if ident := c.get_left_ident(arg.left) {
					match ident.token {
						.match {
							// when is struct or map
							arg_right := arg.right as []NodeEl
							ident0, right := if arg_right.len == 2 {
								ident0 := c.get_left_ident(arg_right[1]) or { TokenRef{} }
								ident0, arg_right[0]
							} else {
								TokenRef{}, arg_right[0]
							}
							args << Arg{
								ident:             ident0
								idents_from_match: c.extract_idents_from_match_expr(right) or {
									return none
								}
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
			if c.peak_token.token == .comma {
				c.next_token()
			}
		}
		for i0, key in default_args0 {
			default_args[key.token] = default_values0[i0]
		}
		c.match_next(.rpar) or { return none }
		return args
	}
	return none
}

fn (mut c Compiler) parse_typespec() ?int {
	if c.peak_token.token == .typespec {
		c.next_token()
		c.match_next(.ident) or { return none }
		token := c.current_token
		if ident := c.idents[token.idx] {
			mut type_idx := c.types.len
			type_idx0 := c.types.index(ident)
			if type_idx0 != -1 {
				type_idx = type_idx0
			} else {
				c.types << ident
			}
			return type_idx
		}
	}
	return none
}

fn (mut c Compiler) parse_guard() ?NodeEl {
	if c.peak_token.token == .when {
		c.next_token()
		c.next_token()
		return c.parse_expr() or { return none }
	}
	return none
}

// fn extract_vars(hashed string) []string {
// 	mut vars0 := []string{}
// 	for v in hashed.split("|") {

// 		println(v)
// 	}
// 	println('=---------------=\n\n')
// 	// for v in vars {
// 	// 	println(v)
// 	// 	vars0 << v
// 	// }
// 	return vars0
// }
