module compiler

fn (mut c Compiler) parse_next_token() !TokenRef {
	token := c.parse_next_token_priv()!
	c.token_before = token
	c.tokens << token
	c.source.next()
	return token
}

fn (mut c Compiler) parse_next_token_priv() !TokenRef {
	// $dbg
	match true {
		c.source.current in [` `, `\n`, 9] {
			if c.source.current == `\n` {
				c.current_line++
			}
			c.source.next()
			return c.parse_next_token_priv()
		}
		c.source.current == `#` {
			mut i := c.source.i
			for i < c.source.src.len && c.source.src[i] != `\n` {
				i++
			}
			c.source.i = i - 1
			c.source.next()
			return c.parse_next_token_priv()
		}
		c.source.current == `(` {
			return TokenRef{
				token:    .lpar
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `)` {
			return TokenRef{
				token:    .rpar
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `@` {
			return TokenRef{
				token:    .arroba
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `%` {
			return TokenRef{
				token:    .percent
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `{` {
			return TokenRef{
				token:    .lcbr
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `}` {
			return TokenRef{
				token:    .rcbr
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `[` {
			return TokenRef{
				token:    .lsbr
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `]` {
			return TokenRef{
				token:    .rsbr
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `,` {
			return TokenRef{
				token:    .comma
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		c.source.current == `:` {
			c.source.next()
			if c.source.current == `:` {
				return TokenRef{
					token:    .typespec
					pos_line: c.source.line
					pos_char: c.source.char
				}
			} else {
				return TokenRef{
					token:    .colon
					pos_line: c.source.line
					pos_char: c.source.char
				}
			}
		}
		c.source.current == `\\` && c.source.peak == `\\` {
			c.source.next()
			return TokenRef{
				token:    .default_arg
				pos_line: c.source.line
				pos_char: c.source.char
			}
		}
		operators_1.index(c.source.current) != -1 {
			mut ops := c.source.src[c.source.i..(c.source.i + 3)]
			mut has_op := false
			for op in operators_3 {
				if op == ops {
					c.source.next()
					c.source.next()
					has_op = true
					break
				}
			}
			if has_op == false {
				for op in operators_2 {
					if op == ops[..2] {
						ops = ops[..2].clone()
						c.source.next()
						has_op = true
						break
					}
				}
			}
			if has_op == false {
				ops = [ops[0]]
			}
			return TokenRef{
				token:    .operator
				pos_line: c.source.line
				pos_char: c.source.char
				bin:      ops.bytestr()
			}
		}
		is_letter(c.source.current) {
			mut idx := 0
			curr := c.source.current
			current_pos := c.source.char
			mut table := TableEnum.none
			ident := c.source.get_next_ident()!
			mut token := Token.ident
			mut bin := ''
			match true {
				c.token_before.token in [.def, .defp] {
					token = Token.function_name
				}
				c.source.peak == `(` {
					token = Token.caller_function
				}
				is_capital(curr) {
					token = Token.module_name
				}
				ident in operators_str {
					// custom string operators
					token = Token.operator
					bin = ident
				}
				ident in keywords {
					token = Token.from(ident)!
				}
				else {
					if c.source.match_peak_at_more(1, `:`) && c.source.match_peak_at_more(2, ` `) {
						c.source.next()
						c.source.next()
						token = Token.atom_key
					}
				}
			}

			match token {
				.module_name {
					table = .idents
					idx0 := c.idents.index('\'${ident}\'')
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = c.idents.len
						c.idents << ident
					}
				}
				.ident, .atom_key {
					table = .idents
					idx0 := c.idents.index(ident)
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = c.idents.len
						c.idents << ident
					}
				}
				.function_name {
					table = .functions
					if c.token_before.token == .def {
						if idx0 := c.functions_idx[ident] {
							idx = idx0
						} else {
							idx = c.functions.len
							c.functions_idx[ident] = idx
							c.functions << &Function{
								name:     ident
								guard:    Nil{}
								location: c.filesource
								pos_line: c.source.line
								pos_char: c.source.char - ident.len
								starts:   0
								ends:     0
								returns:  0
								args:     []
								idx:      idx
							}
						}
						c.in_function = true
						c.in_function_id = idx
						c.count_context = 0
					}
				}
				.caller_function {
					table = .idents
					idx0 := c.idents.index(ident)
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = c.idents.len
						c.idents << ident
					}
				}
				.do {
					c.count_do++
					if c.in_function {
						if c.inside_context.len == 0 {
							c.functions[c.in_function_id].starts = c.source.i
						}
						c.inside_context << '${c.in_function_id}:${c.count_context++}'
					}
				}
				.end {
					c.count_do--
					if c.inside_context.len > 0 {
						c.inside_context.pop()
						if c.inside_context.len == 0 {
							c.functions[c.in_function_id].ends = c.source.i
						}
					}

					if c.count_do == -1 {
						println('unexpected end')
					}
					if c.in_function && c.inside_context.len == 0 {
						c.in_function = false
						c.in_function_id = 0
						c.count_context = 0
					}
				}
				else {}
			}
			mut is_endline := false
			if token == .ident && c.source.peak == `\n` {
				is_endline = true
			}
			return TokenRef{
				idx:        idx
				table:      table
				token:      token
				bin:        bin
				is_endline: is_endline
				pos_line:   c.source.line
				start_pos:  current_pos
				end_pos:    current_pos + ident.len - 1
				pos_char:   c.source.char
			}
		}
		is_string_delimiter(c.source.current) {
			mut table := TableEnum.binary
			if c.token_before.token == .ident {
				if c.tokens.len > 1 && c.tokens[c.tokens.len - 2].token == .arroba {
					table = .ignored_strings
				}
			}
			str := c.source.get_next_string()!
			if table == TableEnum.binary {
				mut idx := c.binaries.len
				idx0 := c.binaries.index(str)
				if idx0 != -1 {
					idx = idx0
				} else {
					idx = c.binaries.len
					c.binaries << str
				}
				return TokenRef{
					idx:      idx
					table:    .binary
					token:    .string
					pos_line: c.source.line
					pos_char: c.source.char
				}
			} else if table == TableEnum.ignored_strings {
				mut idx := c.ignored_strings.len
				idx0 := c.ignored_strings.index(str)
				if idx0 != -1 {
					idx = idx0
				} else {
					idx = c.ignored_strings.len
					c.ignored_strings << str
				}
				return TokenRef{
					idx:      idx
					table:    .ignored_strings
					token:    .string
					pos_line: c.source.line
					pos_char: c.source.char
				}
			}
		}
		is_digit(c.source.current) {
			// Todo float, big and integers
			mut idx := c.integers.len
			value, kind := c.source.get_next_number()!
			if kind == .integer {
				value1 := value.bytestr().int()
				idx0 := c.integers.index(value1)
				if idx0 != -1 {
					idx = idx0
				} else {
					idx = c.integers.len
					c.integers << value1
				}
				return TokenRef{
					idx:      idx
					table:    .integers
					token:    .integer
					pos_line: c.source.line
				}
			} else if kind == .float {
				value1 := value.bytestr().f64()
				idx0 := c.floats.index(value1)
				if idx0 != -1 {
					idx = idx0
				} else {
					idx = c.floats.len
					c.floats << value1
				}

				return TokenRef{
					idx:      idx
					table:    .floats
					token:    .float
					pos_char: c.source.char
				}
			}
			return c.error('TODO implements for bigint and integer64')
		}
		else {
			return c.error('Unexpected token ${[c.source.current]} [${[c.source.current].bytestr()}]')
		}
	}
}

fn (mut c Compiler) add_token(t TokenRef) (bool, TokenRef) {
	c.token_before = t
	if !c.ignore_token {
		return true, t
	}
	return false, TokenRef{}
}

fn (c Compiler) error(msg string) IError {
	return error('[${c.filesource}:${c.source.line}:${c.source.char}] ${msg}')
}
