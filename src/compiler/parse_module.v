module compiler

fn (mut c Compiler) parse_module() !Node0 {
	left_node0 := TokenRef{
		...c.current_token
	}
	c.match_next(.module_name)!
	c.module_name = c.current_token
	right0_node0 := Node0(c.current_token)
	c.match_next(.do)!
	mut elems := []Node0{}
	for !c.eof() {
		if c.peak_token.token == .end {
			break
		}
		elems << c.parse_stmt()!
	}
	right1 := into_block(elems)
	c.match_next(.end)!
	return Tuple3.new(left_node0, List.new([right0_node0, List.new([
		Tuple2.new(TokenRef{ token: .do }, right1),
	])]))
}
