module compiler

fn (mut c Compiler) parse_alias() !Node0 {
	c.match_next(.module_name)!
	token := TokenRef{
		...c.current_token
	}
	mut args := []Node0{}
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
