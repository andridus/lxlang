import os

const c_nil = NodeEl(TokenRef{
	token: .nil
})

struct Compiler {
mut:
	source                  Source
	filesource              string
	module_name             TokenRef
	moduledoc               string
	function_doc            map[string]string
	function_attrs          map[string][]NodeEl
	binaries                []string
	ignored_strings         []string
	integers                []int
	floats                  []f64
	idents                  []string
	types                   []string
	types0                  map[string]NodeEl
	exports                 []string
	attributes              []string
	functions               []Function
	functions_body          map[int]NodeEl
	functions_caller        []CallerFunction
	functions_idx           map[string]int
	tokens                  []TokenRef
	tmp_args                []Arg
	token_before            TokenRef
	in_function             bool
	in_function_id          int
	in_function_args        bool
	inside_context          []string
	labels                  []string
	count_context           int
	count_do                int
	ignore_token            bool
	is_next_function_return bool
	current_position        int = -1
	current_line            int = 1
	current_token           TokenRef
	peak_token              TokenRef
	nodes                   NodeEl = c_nil
}

type NodeEl = TokenRef | Node | []NodeEl | Keyword

struct Keyword {
	key   NodeEl
	value NodeEl
}

struct Node {
	left       NodeEl = c_nil
	right      NodeEl = c_nil
	attributes []string
}

struct Function {
	name string
mut:
	starts   int
	line     int
	ends     int
	returns  int
	location string
	args     []Arg
}

struct CallerFunction {
	name         string
	line         int
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

fn (mut c Compiler) beam_to_file() ! {
	module_name := c.get_module_name()!
	beam_bytes := c.to_beam()!
	os.write_file_array('${module_name}.beam', beam_bytes)!
}

fn (c Compiler) get_module_name() !string {
	if name := c.get_ident_value(c.module_name) {
		return name
	}
	return error('no module name defined')
}

fn (c Compiler) get_function_value(t TokenRef) ?Function {
	if t.table == .functions {
		if function := c.functions[t.idx] {
			return function
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
					if c.source.current == `\n` {
						c.current_line++
					}
					c.source.next()
				} else {
					break
				}
			}
			token1 := c.parse_next_token()!

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
		c.source.current == `@` {
			return TokenRef{
				token: .arroba
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
					idx0 := c.idents.index('\'${ident}\'')
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
								name:     ident
								location: c.filesource
								line:     c.current_line
								starts:   0
								ends:     0
								returns:  0
								args:     []
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
							line:         c.current_line
							starts:       c.tokens.len
							function_idx: idx0
						}
					} else {
						println('undefined function ${ident}')
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
					idx:   idx
					table: .binary
					token: .string
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
					idx:   idx
					table: .ignored_strings
					token: .string
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
