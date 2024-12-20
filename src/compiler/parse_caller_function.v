module compiler

fn (mut c Compiler) parse_caller_function() !Node0 {
	mut caller := c.current_token
	c.next_token()

	mut inside_parens := 0
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
			continue
		}
		arg := c.parse_expr()!
		if ident := c.get_left_ident(arg.left()) {
			attrs := arg.get_attributes() or { NodeAttributes{} }
			match ident.token {
				.percent {
					// when is struct or map
					args << Arg{
						ident:             ident
						idents_from_match: c.extract_idents_from_match_expr(arg.right())!
						match_expr:        arg.right()
						type:              attrs.type_id
						type_match:        attrs.type_match
						is_should_match:   attrs.is_should_match
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
		}
		// if c.peak_token.token != .comma {
		// 	// if c.current_token.token != .rpar {
		// 		c.next_token()
		// 	// }
		// 	continue
		// }
		c.next_token()
	}

	if caller_name := c.get_ident_value(caller) {
		// args_bin := args.map(|a| a.clean_str()).join(',')
		hash := c.make_args_match_hash(args, Nil{})
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
	return caller
}
