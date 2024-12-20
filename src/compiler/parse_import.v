module compiler

fn (mut c Compiler) parse_import() !Node0 {
	c.match_next(.module_name)!
	token := c.current_token
	mut args := []Node0{}
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
