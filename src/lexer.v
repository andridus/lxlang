struct Lexer {
mut:
	source                  Source
	binaries                []string
	integers                []int
	floats                  []f64
	idents                  []string
	types                   []string
	functions               []Function
	functions_caller        []CallerFunction
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

struct CallerFunction {
	name         string
	starts       int
	function_idx int
mut:
	module  string
	returns int
	args    []Arg
}

struct Arg {
	token TokenRef
mut:
	type       int
	match_expr int // pointer to match exprs
}

fn (mut l Lexer) parse_next_token() !TokenRef {
	token := l.parse_next_token_priv()!
	l.token_before = token
	l.tokens << token
	l.source.next()
	return token
}

fn (mut l Lexer) parse_next_token_priv() !TokenRef {
	// $dbg
	match true {
		l.source.current in [` `, `\n`, 9] {
			l.source.next()
			return l.parse_next_token_priv()
		}
		l.source.current == `(` && l.token_before.token == .function_name {
			// add rpar
			lpar := TokenRef{
				token: .lpar
			}
			l.tokens << lpar
			l.token_before = lpar
			l.source.next()

			l.in_function_args = true
			mut args_ident := map[int]TokenRef{}
			mut args_type := map[int]TokenRef{}
			mut i := -1
			// get args token
			for !l.source.eof() {
				before := l.token_before
				token0 := l.parse_next_token()!
				if token0.token == .rpar {
					l.source.next()
					break
				} else if token0.token == .ident && before.token == .typespec {
					args_type[i] = token0
				} else if token0.token == .ident {
					i++
					args_ident[i] = token0
				}
				l.token_before = token0
			}
			l.in_function_args = false

			// prepare function args
			mut args := []Arg{}
			for k, arg_token in args_ident {
				if type_value := args_type[k] {
					if ident := l.idents[type_value.idx] {
						mut type_idx := l.types.len
						type_idx0 := l.types.index(ident)
						if type_idx0 != -1 {
							type_idx = type_idx0
						} else {
							l.types << ident
						}
						args << Arg{
							token: arg_token
							type:  type_idx
						}
					}
				} else {
					args << Arg{
						token: arg_token
						type:  0
					}
				}
			}
			l.functions[l.in_function_id].args = args

			// maybe get the return
			for !l.source.eof() {
				if l.source.current in [` `, `\n`, 9] {
					l.source.next()
				} else {
					break
				}
			}
			token1 := l.parse_next_token()!
			// l.tokens << token1
			if token1.token == .typespec {
				token2 := l.parse_next_token()!
				if token2.token == .ident {
					if ident := l.idents[token2.idx] {
						mut type_idx := l.types.len
						type_idx0 := l.types.index(ident)
						if type_idx0 != -1 {
							type_idx = type_idx0
						} else {
							l.types << ident
						}
						l.functions[l.in_function_id].returns = type_idx
					}
				}
			}

			l.tmp_args.clear()

			return l.parse_next_token_priv()
			// return
		}
		l.source.current == `(` {
			return TokenRef{
				token: .lpar
			}
		}
		l.source.current == `)` {
			return TokenRef{
				token: .rpar
			}
		}
		l.source.current == `{` {
			return TokenRef{
				token: .lcbr
			}
		}
		l.source.current == `}` {
			return TokenRef{
				token: .rcbr
			}
		}
		l.source.current == `[` {
			return TokenRef{
				token: .lsbr
			}
		}
		l.source.current == `]` {
			return TokenRef{
				token: .rsbr
			}
		}
		l.source.current == `,` {
			return TokenRef{
				token: .comma
			}
		}
		l.source.current == `:` {
			l.source.next()
			if l.source.current == `:` {
				return TokenRef{
					token: .typespec
				}
			} else {
				return TokenRef{
					token: .colon
				}
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
				}
			}
			return TokenRef{
				token: .operator
			}
		}
		is_letter(l.source.current) {
			mut idx := 0
			curr := l.source.current
			mut table := TableEnum.none
			ident := l.source.get_next_ident()!
			mut token := Token.ident
			match true {
				is_capital(curr) {
					token = Token.module_name
				}
				l.token_before.token == .def {
					token = Token.function_name
				}
				l.source.peak == `(` {
					token = Token.caller_function
				}
				keywords.index(ident) != -1 {
					token = Token.from(ident)!
				}
				else {}
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
						idx = l.functions_caller.len
						l.functions_caller << &CallerFunction{
							name:         ident
							starts:       l.tokens.len
							function_idx: idx0
						}
					} else {
						println('undefined function')
					}
				}
				.do {
					l.count_do++
					if l.in_function {
						if l.inside_context.len == 0 {
							l.functions[l.in_function_id].starts = l.source.i
						}
						l.inside_context << '${l.in_function_id}:${l.count_context++}'
					}
				}
				.end {
					l.count_do--
					if l.inside_context.len > 0 {
						l.inside_context.pop()
						if l.inside_context.len == 0 {
							l.functions[l.in_function_id].ends = l.source.i
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

			return TokenRef{
				idx:   idx
				table: table
				token: token
			}
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
			return TokenRef{
				idx:   idx
				table: .binary
				token: .string
			}
		}
		is_digit(l.source.current) {
			// Todo float, big and integers
			mut idx := l.integers.len
			value, kind := l.source.get_next_number()!
			if kind == .integer {
				value1 := value.bytestr().int()
				idx0 := l.integers.index(value1)
				if idx0 != -1 {
					idx = idx0
				} else {
					idx = l.integers.len
					l.integers << value1
				}
				return TokenRef{
					idx:   idx
					table: .integers
					token: .integer
				}
			} else if kind == .float {
				value1 := value.bytestr().f64()
				idx0 := l.floats.index(value1)
				if idx0 != -1 {
					idx = idx0
				} else {
					idx = l.floats.len
					l.floats << value1
				}

				return TokenRef{
					idx:   idx
					table: .floats
					token: .float
				}
			}
			return error('TODO implements for bigint and integer64')
		}
		else {
			return error('Unexpected token ${[l.source.current].bytestr()}')
		}
	}
}

fn (mut l Lexer) add_token(t TokenRef) (bool, TokenRef) {
	l.token_before = t
	if !l.ignore_token {
		// l.tokens << t
		return true, t
	}
	return false, TokenRef{}
}
