module compiler

fn (mut c Compiler) parse_atom() !Node0 {
	if c.peak_token.token == .ident {
		c.next_token()
		return Node0(c.current_token)
	}
	return c.parse_error('parse_atom()', c.current_token)
}
