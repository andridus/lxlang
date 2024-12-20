module compiler

fn (mut c Compiler) parse_ident() !Node0 {
	mut ident := c.current_token
	mut type_id := 0

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
		attrs := NodeAttributes{
			type_id: type_id
		}
		return Tuple3.new_attrs(ident, value, attrs)
	}
	mut idvalue := ''
	if id := c.get_ident_value(ident) {
		idvalue = id
		if id == 'nil' {
			type_id = c.types.index('nil')
		}
	}
	if type_id != c.types.index('nil') && c.current_function_idx >= 0 && c.peak_token.bin != '='
		&& !c.in_caller_function {
		if fun := c.functions[c.current_function_idx] {
			if idvalue !in fun.scoped_vars {
				c.in_caller_function = true
				defer {
					c.in_caller_function = false
				}
				return c.parse_caller_function()!
			}
		}
	}
	ident.type_id = type_id
	return ident
}
