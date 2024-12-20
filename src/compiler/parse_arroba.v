module compiler

fn (mut c Compiler) parse_arroba() !Node0 {
	c.match_next(.ident)!
	if attribute := c.get_ident_value(c.current_token) {
		match attribute {
			'moduledoc' {
				token := c.current_token
				c.match_next(.string)!
				if moduledoc := c.get_string_value(c.current_token) {
					c.moduledoc = moduledoc
					return Tuple3.new(TokenRef{ token: .moduledoc }, [
						Node0(token),
						c.current_token,
					])
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
					n_left := node0.left()
					if n_left is TokenRef && n_left.token == .def {
						parse_until_function = false
						n_right := node0.right().as_list()
						if n_right.len == 2 {
							n_right0_left := n_right[0].left()
							if n_right0_left is TokenRef {
								if function := c.get_function_value(n_right0_left) {
									c.function_doc[function.name] = docstr
									return node0
								} else {
									return error('not found function')
								}
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
				return Node0(token)
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
				// 	return Node0(Node{left: TokenRef{token: .moduledoc}, right: [Node0(token), c.current_token]})
				// }
				// return c.parse_error_custom('not defined parse custom attribute for `${c.get_ident_value(c.current_token)}`', c.current_token)
			}
		}
	}
	return c.parse_error('parse_arroba()', c.current_token)
}
