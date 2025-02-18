module compiler

fn (c Compiler) get_module_name() !string {
	if name := c.get_ident_value(c.module_name) {
		return name
	}
	return error('no module name defined')
}

fn (c Compiler) get_left_ident(n Node0) ?&TokenRef {
	match n {
		List {
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

struct IdentMatch {
mut:
	key     string
	value   []IdentMatch
	literal string
	bind    string
}

fn (im IdentMatch) str() string {
	has_key := im.key.len > 0
	has_literal := im.literal.len > 0
	has_value := im.value.len > 0
	mut strings := ''

	if has_literal && !has_key && !has_value {
		return '${im.literal}'
	}
	if has_key {
		strings += '${im.key}=>'
	}
	if has_literal {
		strings += '${im.literal}'
	}
	if im.value.len == 1 {
		strings += '${im.value[0].str()}'
		return strings
	} else if has_value {
		strings += '%{${im.value.map(|v| v.str()).join(',')}}'
	}
	return '{' + strings + '}'
}

fn (im IdentMatch) hash() string {
	has_key := im.key.len > 0
	has_literal := im.literal.len > 0
	has_bind := im.bind.len > 0
	has_value := im.value.len > 0
	mut strings := ''
	if has_literal && !has_bind && !has_key && !has_value {
		return '${im.literal}'
	} else if has_bind && !has_literal && !has_key && !has_value {
		return '$'
	}
	if (has_literal || has_bind) && has_value {
		mut strings0 := ''
		if has_bind {
			strings0 += '$='
		}
		if has_literal {
			strings0 += '${im.literal}='
		}
		strings0 += '%{${im.value[0].hash()}}'
		return strings0
	}
	if has_bind {
		strings += '${im.bind}='
	}
	if has_key {
		strings += '${im.key}=>'
	}
	if has_literal && im.literal.starts_with('.') {
		strings += '$'
	} else {
		strings += '${im.literal}'
	}
	if im.value.len == 1 {
		strings += '${im.value[0].hash()}'
		return strings
	} else if has_value {
		strings += '%{${im.value.map(|v| v.hash()).join(',')}}'
	}
	return '%{' + strings + '}'
}

fn (im IdentMatch) get_vars() []string {
	mut literals := []string{}
	if im.bind.len > 0 {
		literals << im.bind.replace('.', '')
	}
	if im.value.len > 0 {
		for value in im.value {
			literals << value.get_vars()
		}
	}
	return literals
}

fn (c Compiler) extract_idents_from_match_expr(expr Node0) !IdentMatch {
	idnts := c.do_extract_idents_from_match_exp(expr)!
	mut ident_match := IdentMatch{}
	for idnt in idnts {
		if idnt.key == '' && idnt.literal.len > 0 {
			ident_match.literal = idnt.literal
		} else if idnt.key == '' && idnt.bind.len > 0 {
			ident_match.bind = idnt.bind
		} else {
			ident_match.value << idnt
		}
	}
	return ident_match
}

fn (c Compiler) do_extract_idents_from_match_exp(expr Node0) ![]IdentMatch {
	mut idents := []IdentMatch{}
	match expr {
		List {
			for node in expr.items {
				idents << c.do_extract_idents_from_match_exp(node)!
			}
		}
		Tuple3, Tuple2 {
			mut nodes := []Node0{}
			node_left := expr.left()
			if node_left is TokenRef {
				match node_left.token {
					.match {
						nodes_right := expr.right().as_list()

						for node_right in nodes_right {
							if key0 := c.extract_value_str_from_node_el(node_right.left()) {
								value := c.do_extract_idents_from_match_exp(node_right.right())!
								idents << IdentMatch{
									key:   key0
									value: value
								}
							}
						}
					}
					.percent {
						return c.do_extract_idents_from_match_exp(expr.right())!
					}
					else {}
				}
			} else {
				nodes << expr.as_list()
			}
		}
		TokenRef {
			if value := c.extract_value_str_from_node_el(expr) {
				if value.starts_with('.') {
					idents << IdentMatch{
						bind: value
					}
				} else {
					idents << IdentMatch{
						literal: value
					}
				}
			}
		}
		else {}
	}
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
			if expr.token == .atom_key {
				if v := c.get_ident_value(expr) {
					return ':${v}'
				}
			}
			if expr.token == .ident {
				if v := c.get_ident_value(expr) {
					return '.${v}'
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
		if ident_match := a.idents_from_match {
			args_str << ident_match.hash()
		} else if a.ident != token_nil {
			v := c.get_ident_value(a.ident) or { 'nil' }
			if v == 'nil' {
				args_str << 'nil'
			} else {
				args_str << '$'
			}
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
	return '${hashed}WHEN(${guard_hash})'
}

fn (c Compiler) mount_match(tk Node0) ?NodeAttributes {
	if attrs := tk.get_attributes() {
		left := tk.left()
		if left is TokenRef {
			if left.token == .percent {
				return NodeAttributes{
					...attrs
					type_match:      '_'
					is_should_match: true
					type_id:         attrs.type_id
				}
			}
		}
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

fn (c Compiler) eof() bool {
	return c.current_position >= c.tokens.len
}

fn (c Compiler) eof_next() bool {
	return (c.current_position + 1) >= c.tokens.len
}

fn (mut c Compiler) next_token() {
	c.current_position++
	if !c.eof() {
		c.current_token = c.tokens[c.current_position]
		if !c.eof_next() {
			c.peak_token = c.tokens[c.current_position + 1]
		} else {
			c.peak_token = TokenRef{
				token: .eof
			}
		}
	}
}

fn (mut c Compiler) match_next(token Token) ! {
	c.next_token()
	if c.current_token.token != token {
		return c.parse_error_custom('unexpected term ${c.current_token.token}, should be ${token}',
			c.current_token)
	}
}

fn (mut c Compiler) opt_match_next(token Token) bool {
	if c.peak_token.token == token {
		c.next_token()
		return true
	}
	return false
}

fn (mut c Compiler) maybe_match_next(tokens []Token) !Token {
	c.next_token()
	if c.current_token.token in tokens {
		return c.current_token.token
	} else {
		return c.parse_error_custom('unexpected term ${c.current_token.token}, should be in ${tokens}',
			c.current_token)
	}
}
