module compiler

fn (c Compiler) get_module_name() !string {
	if name := c.get_ident_value(c.module_name) {
		return name
	}
	return error('no module name defined')
}

fn (c Compiler) get_left_ident(n NodeEl) ?TokenRef {
	match n {
		Node {
			return c.get_left_ident(n.left)
		}
		TokenRef {
			return n
		}
		else {
			return none
		}
	}
}

fn (c Compiler) to_value_str(n NodeEl) ?string {
	match n {
		TokenRef {
			tk := n as TokenRef
			val := match tk.token {
				.string { c.get_string_value(tk) }
				.integer { c.get_integer_value(tk).str() }
				.float { c.get_integer_value(tk).str() }
				else { '' }
			}
			return val
		}
		else {
			return ''
		}
	}
}

pub fn (c Compiler) get_function_value(t TokenRef) ?Function {
	if t.table == .functions {
		if function := c.functions[t.idx] {
			return function
		}
	}
	return none
}

pub fn (c Compiler) get_function_doc(t TokenRef) ?string {
	if t.table == .functions {
		if function := c.functions[t.idx] {
			return c.function_doc[function.name]
		}
	}
	return none
}

fn (c Compiler) get_ident_value(t TokenRef) ?string {
	if t.table == .idents {
		if ident := c.idents[t.idx] {
			return ident
		}
	}
	return none
}

fn (c Compiler) get_string_value(t TokenRef) ?string {
	if t.table == .binary {
		if str := c.binaries[t.idx] {
			return str
		}
	} else if t.table == .ignored_strings {
		if str := c.ignored_strings[t.idx] {
			return str
		}
	}
	return none
}

fn (c Compiler) get_integer_value(t TokenRef) ?int {
	if t.table == .integers {
		if integer := c.integers[t.idx] {
			return integer
		}
	}
	return none
}
