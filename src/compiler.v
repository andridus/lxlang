const c_nil = NodeEl(TokenRef{
	token: .nil
})

struct Compiler {
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
	current_position        int = -1
	current_token           TokenRef
	peak_token              TokenRef
	nodes                   NodeEl = c_nil
}

type NodeEl = TokenRef | Node | []NodeEl | Keyword

struct Keyword {
	key   NodeEl
	value NodeEl
}

fn (n NodeEl) str() string {
	return match n {
		TokenRef { n.str() }
		Node { n.str() }
		Keyword { '${n.key.str()}: ${n.value.str()}' }
		[]NodeEl { n.str() }
	}
}

struct Node {
	left       NodeEl = c_nil
	right      NodeEl = c_nil
	attributes []string
}

fn (n Node) str() string {
	return '{${n.left}, ${n.attributes}, ${n.right}}'
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
			c.source.next()
			return c.parse_next_token_priv()
		}
		c.source.current == `(` && c.token_before.token == .function_name {
			// add rpar
			lpar := TokenRef{
				token: .lpar
			}
			c.tokens << lpar
			c.token_before = lpar
			c.source.next()

			c.in_function_args = true
			mut args_ident := map[int]TokenRef{}
			mut args_type := map[int]TokenRef{}
			mut i := -1
			// get args token
			for !c.source.eof() {
				before := c.token_before
				token0 := c.parse_next_token()!
				if token0.token == .rpar {
					c.source.next()
					break
				} else if token0.token == .ident && before.token == .typespec {
					args_type[i] = token0
				} else if token0.token == .ident {
					i++
					args_ident[i] = token0
				}
				c.token_before = token0
			}
			c.in_function_args = false

			// prepare function args
			mut args := []Arg{}
			for k, arg_token in args_ident {
				if type_value := args_type[k] {
					if ident := c.idents[type_value.idx] {
						mut type_idx := c.types.len
						type_idx0 := c.types.index(ident)
						if type_idx0 != -1 {
							type_idx = type_idx0
						} else {
							c.types << ident
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
			c.functions[c.in_function_id].args = args

			// maybe get the return
			for !c.source.eof() {
				if c.source.current in [` `, `\n`, 9] {
					c.source.next()
				} else {
					break
				}
			}
			token1 := c.parse_next_token()!
			// c.tokens << token1
			if token1.token == .typespec {
				token2 := c.parse_next_token()!
				if token2.token == .ident {
					if ident := c.idents[token2.idx] {
						mut type_idx := c.types.len
						type_idx0 := c.types.index(ident)
						if type_idx0 != -1 {
							type_idx = type_idx0
						} else {
							c.types << ident
						}
						c.functions[c.in_function_id].returns = type_idx
					}
				}
			}

			c.tmp_args.clear()

			return c.parse_next_token_priv()
			// return
		}
		c.source.current == `(` {
			return TokenRef{
				token: .lpar
			}
		}
		c.source.current == `)` {
			return TokenRef{
				token: .rpar
			}
		}
		c.source.current == `{` {
			return TokenRef{
				token: .lcbr
			}
		}
		c.source.current == `}` {
			return TokenRef{
				token: .rcbr
			}
		}
		c.source.current == `[` {
			return TokenRef{
				token: .lsbr
			}
		}
		c.source.current == `]` {
			return TokenRef{
				token: .rsbr
			}
		}
		c.source.current == `,` {
			return TokenRef{
				token: .comma
			}
		}
		c.source.current == `:` {
			c.source.next()
			if c.source.current == `:` {
				return TokenRef{
					token: .typespec
				}
			} else {
				return TokenRef{
					token: .colon
				}
			}
		}
		operators_1.index(c.source.current) != -1 {
			mut ops := [c.source.current]
			c.source.next()
			if operators_1.index(c.source.current) != -1 {
				ops << c.source.current
				c.source.next()
				if operators_1.index(c.source.current) != -1 {
					ops << c.source.current
				}
			}
			return TokenRef{
				token: .operator
			}
		}
		is_letter(c.source.current) {
			mut idx := 0
			curr := c.source.current
			mut table := TableEnum.none
			ident := c.source.get_next_ident()!
			mut token := Token.ident
			match true {
				is_capital(curr) {
					token = Token.module_name
				}
				c.token_before.token == .def {
					token = Token.function_name
				}
				c.source.peak == `(` {
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
					idx0 := c.idents.index(ident)
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = c.idents.len
						c.idents << ident
					}
				}
				.ident {
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
								name:    ident
								starts:  0
								ends:    0
								returns: 0
								args:    []
							}
						}
						c.in_function = true
						c.in_function_id = idx
						c.count_context = 0
					}
				}
				.caller_function {
					table = .functions
					if idx0 := c.functions_idx[ident] {
						idx = c.functions_caller.len
						c.functions_caller << &CallerFunction{
							name:         ident
							starts:       c.tokens.len
							function_idx: idx0
						}
					} else {
						println('undefined function')
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

			return TokenRef{
				idx:   idx
				table: table
				token: token
			}
		}
		is_string_delimiter(c.source.current) {
			str := c.source.get_next_string()!
			mut idx := c.binaries.len
			idx0 := c.binaries.index(str)
			if idx0 != -1 {
				idx = idx0
			} else {
				idx = c.integers.len
				c.binaries << str
			}
			return TokenRef{
				idx:   idx
				table: .binary
				token: .string
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
					idx:   idx
					table: .integers
					token: .integer
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
					idx:   idx
					table: .floats
					token: .float
				}
			}
			return error('TODO implements for bigint and integer64')
		}
		else {
			return error('Unexpected token ${[c.source.current].bytestr()}')
		}
	}
}

fn (mut c Compiler) add_token(t TokenRef) (bool, TokenRef) {
	c.token_before = t
	if !c.ignore_token {
		// c.tokens << t
		return true, t
	}
	return false, TokenRef{}
}
