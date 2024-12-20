module compiler

fn (c Compiler) get_module_name() !string {
	if name := c.get_ident_value(c.module_name) {
		return name
	}
	return error('no module name defined')
}

fn (c Compiler) get_left_ident(n Node0) ?&TokenRef {
	match n {
		[]Node0 {
			return c.get_left_ident(n.left())
		}
		TokenRef {
			return n
		}
		else {
			return none
		}
	}
}

fn (c Compiler) extract_idents_from_match_expr(expr Node0) ![]string {
	mut idents := []string{}
	match expr {
		[]Node0 {
			for node in expr {
				idents << c.extract_idents_from_match_expr(node)!
			}
		}
		Tuple3 {
			for node in expr.as_list() {
				idents << c.extract_idents_from_match_expr(node)!
			}
		}
		Tuple2 {
			mut key := ''
			if key0 := c.extract_value_str_from_node_el(expr.left()) {
				key = '[${key0}]'
			}
			for value in c.extract_idents_from_match_expr(expr.right())! {
				idents << '${key}${value}'
			}
		}
		TokenRef {
			match expr.token {
				.ident {
					if value := c.get_ident_value(expr) {
						idents << '=${value}'
					}
				}
				.string {
					if value := c.get_string_value(expr) {
						idents << '="${value}"'
					}
				}
				else {}
			}
		}
		else {}
	}
	idents.sort()
	return idents
}

fn (c Compiler) extract_value_str_from_node_el(expr Node0) ?string {
	match expr {
		TokenRef {
			if expr.token == .string {
				if v := c.get_string_value(expr) {
					return "\"${v}\""
				}
			}
			if expr.token == .ident {
				if v := c.get_ident_value(expr) {
					return ':${v}'
				}
			}
		}
		else {
			return c.extract_value_str_from_node_el(expr.left())
		}
	}
	return none
}

fn (c Compiler) make_hash_from_node_el(guard Node0) string {
	match guard {
		TokenRef {
			match guard.token {
				.caller_function {
					if fun := c.get_function_caller_value(guard) {
						return fun.hash
					}
					if fun := c.get_function_caller_undefined_value(guard) {
						return fun.hash
					}
				}
				else {
					return guard.token.str()
				}
			}
		}
		Nil {
			return ''
		}
		else {
			left_hash := c.make_hash_from_node_el(guard.left())
			right_hash := c.make_hash_from_node_el(guard.right())
			return '${left_hash}_${right_hash}'
		}
	}

	return ''
}

fn (c Compiler) make_args_match_hash(args []Arg, guard Node0) string {
	guard_hash := c.make_hash_from_node_el(guard)
	mut args_str := []string{}
	for a in args {
		if a.idents_from_match.len > 0 {
			args_hashed := a.idents_from_match.join(',')
			str := match true {
				args_hashed.starts_with('[') {
					'map{${args_hashed}}'
				}
				else {
					args_hashed
				}
			}
			args_str << str
		} else if a.type_match.len > 0 {
			args_str << a.type_match
		} else if type_ := c.types[a.type] {
			args_str << type_
		}
	}
	hashed := args_str.join('|')
	if guard_hash.len == 0 {
		return '${hashed}'
	}
	return '${hashed}\$(${guard_hash})'
}

fn (c Compiler) mount_match(tk Node0) ?NodeAttributes {
	if attrs := tk.get_attributes() {
		if value := c.to_value_str(tk) {
			return NodeAttributes{
				...attrs
				type_match:      value
				is_should_match: true
				type_id:         attrs.type_id
			}
		} else {
			return attrs
		}
	}
	return none
}

fn (c Compiler) to_value_str(n Node0) ?string {
	match n {
		TokenRef {
			match n.token {
				.string {
					c.get_string_value(n)
				}
				.integer {
					if v := c.get_integer_value(n) {
						return v.str()
					}
				}
				.float {
					if v := c.get_integer_value(n) {
						return v.str()
					}
				}
				else {}
			}
		}
		else {}
	}
	return none
}

pub fn (c Compiler) get_function_value(t TokenRef) ?Function {
	if t.table == .functions {
		if function := c.functions[t.idx] {
			return function
		}
	}
	return none
}

pub fn (c Compiler) get_function_caller_value(t TokenRef) ?CallerFunction {
	if t.table == .functions_caller {
		if caller_function := c.functions_caller[t.idx] {
			return caller_function
		}
	}
	return none
}

pub fn (c Compiler) get_function_caller_undefined_value(t TokenRef) ?CallerFunction {
	if t.table == .functions_caller_undefined {
		if caller_function := c.functions_caller_undefined[t.idx] {
			return caller_function
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
