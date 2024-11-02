struct Lexer {
mut:
	source                  Source
	binaries                []string
	integers                []int
	floats                  []f64
	idents                  []string
	types                   []string
	functions               []Function
	functions_idx           map[string]int
	tokens                  []TokenRef
	tmp_args                []Arg
	token_before            TokenRef
	in_function             bool
	in_function_id          int
	in_function_args        bool
	inside_context          []string
	count_context           int
	count_do                int
	ignore_token            bool
	is_next_function_return bool
}

struct Function {
	name string
mut:
	starts  int
	ends    int
	returns int
	args    []Arg
}

struct Arg {
	token TokenRef
mut:
	type       int
	match_expr int // pointer to match exprs
}

fn (mut l Lexer) parse_tokens() ! {
	match true {
		l.source.current in [` `, `\n`] {
			l.source.next()
			return
		}
		l.source.current == `(` && l.token_before.token == .function_name {
			// parse function args
			l.source.next()
			l.in_function_args = true
			l.ignore_token = true
			for l.source.eof() == false {
				if l.source.current == `)` {
					l.source.next()
					break
				}
				l.parse_tokens()!
			}
			l.in_function_args = false
			l.ignore_token = false
			l.token_before = l.tokens.last()
			l.functions[l.in_function_id].args = l.tmp_args.clone()
			l.tmp_args.clear()
			return
		}
		l.source.current == `(` {
			l.add_token(TokenRef{
				token: .lpar
			})
		}
		l.source.current == `)` {
			l.add_token(TokenRef{
				token: .rpar
			})
		}
		l.source.current == `{` {
			l.add_token(TokenRef{
				token: .lcbr
			})
		}
		l.source.current == `}` {
			l.add_token(TokenRef{
				token: .rcbr
			})
		}
		l.source.current == `[` {
			l.add_token(TokenRef{
				token: .lsbr
			})
		}
		l.source.current == `]` {
			l.add_token(TokenRef{
				token: .rsbr
			})
		}
		l.source.current == `,` {
			l.add_token(TokenRef{
				token: .comma
			})
		}
		l.source.current == `:` {
			l.source.next()
			if l.source.current == `:` {
				token := &TokenRef{
					token: .typespec
				}
				if l.in_function_args && l.token_before.token == .ident {
					l.tmp_args << &Arg{
						token: l.token_before
					}
				} else if l.in_function && l.token_before.token == .function_name {
					l.is_next_function_return = true
					l.ignore_token = true
				}
				l.add_token(token)
			} else {
				return
			}
		}
		operators_1.index(l.source.current) != -1 {
			mut ops := [l.source.current]
			l.source.next()
			if operators_1.index(l.source.current) != -1 {
				ops << l.source.current
				l.source.next()
				if operators_1.index(l.source.current) != -1 {
					ops << l.source.current
					l.source.next()
				}
			}
			l.add_token(TokenRef{
				token: .operator
			})
			return
		}
		is_letter(l.source.current) {
			mut ignore_token := false
			mut idx := 0
			curr := l.source.current
			mut table := TableEnum.none
			ident := l.source.get_next_ident()!

			token := match true {
				keywords.index(ident) != -1 { Token.from(ident)! }
				is_capital(curr) { Token.module_name }
				l.token_before.token == .def { Token.function_name }
				l.source.current == `(` { Token.caller_function }
				else { Token.ident }
			}

			match token {
				.module_name {
					table = .idents
					idx0 := l.idents.index(ident)
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = l.idents.len
						l.idents << ident
					}
				}
				.ident {
					table = .idents
					idx0 := l.idents.index(ident)
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = l.idents.len
						l.idents << ident
					}

					if l.token_before.token == .typespec {
						mut type_idx := l.types.len
						type_idx0 := l.types.index(ident)
						if type_idx0 != -1 {
							type_idx = type_idx0
						} else {
							l.types << ident
						}
						if l.in_function_args && l.tmp_args.len > 0 {
							l.tmp_args[l.tmp_args.len - 1].type = type_idx
						} else if l.is_next_function_return {
							l.functions[l.in_function_id].returns = type_idx
							l.ignore_token = false
							ignore_token = true
							l.is_next_function_return = false
						}
					} else if l.in_function_args && l.token_before.token in [.function_name, .comma]{
							// l.tmp_args << &Arg{
							// 	token: curr
							// }
					}
				}
				.function_name {
					table = .functions
					if l.token_before.token == .def {
						if idx0 := l.functions_idx[ident] {
							idx = idx0
						} else {
							idx = l.functions.len
							l.functions_idx[ident] = idx
							l.functions << &Function{
								name:    ident
								starts:  0
								ends:    0
								returns: 0
								args:    []
							}
						}
						l.in_function = true
						l.in_function_id = idx
						l.count_context = 0
					}
				}
				.caller_function {
					table = .functions
					if idx0 := l.functions_idx[ident] {
						idx = idx0
					} else {
						println('undefined function')
					}
				}
				.do {
					l.count_do++
					if l.in_function {
						if l.inside_context.len == 0 {
							l.functions[l.in_function_id].starts = l.tokens.len + 1
						}
						l.inside_context << '${l.in_function_id}:${l.count_context++}'
					}
				}
				.end {
					l.count_do--
					if l.inside_context.len > 0 {
						l.inside_context.pop()
						if l.inside_context.len == 0 {
							l.functions[l.in_function_id].ends = l.tokens.len - 1
						}
					}

					if l.count_do == -1 {
						println('unexpected end')
					}
					if l.in_function && l.inside_context.len == 0 {
						l.in_function = false
						l.in_function_id = 0
						l.count_context = 0
					}
				}
				else {}
			}

			if !ignore_token {
				l.add_token(TokenRef{
					idx:   idx
					table: table
					token: token
				})
			}
			return
		}
		is_string_delimiter(l.source.current) {
			str := l.source.get_next_string()!
			mut idx := l.binaries.len
			idx0 := l.binaries.index(str)
			if idx0 != -1 {
				idx = idx0
			} else {
				idx = l.integers.len
				l.binaries << str
			}
			l.add_token(TokenRef{
				idx:   idx
				table: .binary
				token: .string
			})
			return
		}
		is_digit(l.source.current) {
			// Todo float, big and integers
			mut idx := l.integers.len
			value, kind := l.source.get_next_number()!
			match kind {
				.integer {
					value1 := value.bytestr().int()
					idx0 := l.integers.index(value1)
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = l.integers.len
						l.integers << value1
					}
					l.add_token(TokenRef{
						idx:   idx
						table: .integers
						token: .integer
					})
				}
				.float {
					value1 := value.bytestr().f64()
					idx0 := l.floats.index(value1)
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = l.floats.len
						l.floats << value1
					}
					l.add_token(TokenRef{
						idx:   idx
						table: .floats
						token: .float
					})
				}
				else {
					return error('TODO implements for bigint and integer64')
				}
			}

			return
		}
		else {}
	}
	l.source.next()
}

fn (mut l Lexer) add_token(t &TokenRef) {
	l.token_before = t
	if !l.ignore_token {
		l.tokens << t
	}
}
