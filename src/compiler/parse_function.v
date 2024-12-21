module compiler

const token_nil = &TokenRef{}

fn (mut c Compiler) parse_function() !Node0 {
	left := TokenRef{
		...c.current_token
	}
	pos_line := c.current_token.pos_line
	pos_char := c.current_token.pos_char
	c.match_next(.function_name)!
	function_name := TokenRef{
		...c.current_token
	}
	fun := c.get_function_value(function_name) or {
		return c.parse_error('not found function', c.current_token)
	}

	idx_function := fun.idx

	mut right := []Node0{}
	right << TokenRef{
		...c.current_token
	}
	args := c.maybe_parse_args() or { []Arg{} }
	type_idx := c.parse_typespec() or { 0 }

	mut vars := []string{}
	for arg in args {
		if arg.is_should_match {
			if ident_match := arg.idents_from_match {
				vars << ident_match.get_vars()
			}
		} else {
			if v := c.get_ident_value(arg.ident) {
				vars << v
			}
		}
	}
	c.functions[idx_function].scoped_vars = vars
	defer {
		c.functions[idx_function].scoped_vars.clear()
	}
	c.current_function_idx = fun.idx
	guard := c.parse_guard() or { Node0(Nil{}) }
	hashed := c.make_args_match_hash(args, guard)
	c.current_function_idx = -1

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
	mut right0 := []Node0{}
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
			mut functions := []Node0{}
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

	for c.peak_token.token != .end {
		c.current_function_idx = fun.idx
		parsed := c.parse_expr()!
		c.current_function_idx = -1
		right0 << parsed
		if !function_has_end_token {
			break
		}
		if c.peak_token.token != .end {
			c.next_token()
		}
	}
	right << Tuple2.new(TokenRef{ token: .do }, right0)
	if function_has_end_token {
		c.match_next(.end)!
	}

	c.functions_body[function_name.idx] = right0
	return Tuple3.new(left, right)
}

fn (mut c Compiler) maybe_parse_args() ?[]Arg {
	if c.peak_token.token == .lpar {
		mut args := []Arg{}
		mut default_args := []Node0{}
		mut default_args0 := []TokenRef{}
		mut default_values0 := []Node0{}
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
			arg := c.parse_expr() or {
				eprintln("can't parse args")
				exit(1)
			}
			arg_right := arg.right()
			arg_right_left := arg.right().left()
			mut ident := token_nil
			ident = c.get_left_ident(arg_right_left) or { ident }
			if ident.token != .match {
				ident = c.get_left_ident(arg.left()) or { ident }
			}
			attrs := arg.get_attributes() or { NodeAttributes{} }
			match ident.token {
				.match {
					// when is struct or map
					ident_from_match := c.extract_idents_from_match_expr(arg_right) or {
						return none
					}
					args << Arg{
						ident:             token_nil
						idents_from_match: ident_from_match
						type:              attrs.type_id
						type_match:        ident_from_match.hash()
						is_should_match:   true
						match_expr:        arg
					}
				}
				else {
					args << Arg{
						ident:           ident
						type:            attrs.type_id
						type_match:      attrs.type_match
						is_should_match: attrs.is_should_match
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
		token := TokenRef{
			...c.current_token
		}
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

fn (mut c Compiler) parse_guard() ?Node0 {
	if c.peak_token.token == .when {
		c.next_token()
		c.next_token()
		return c.parse_expr() or { return none }
	}
	return none
}
