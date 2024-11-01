struct Parser {
mut:
	source   Source
	binaries []string
	integers []int
	floats   []f64
	idents   []string
	tokens   []TokenRef
}

fn (mut p Parser) parse_tokens() ![]TokenRef {
	for p.source.eof() == false {
		match true {
			p.source.current in [` `, `\n`] {
				p.source.next()
				continue
			}
			p.source.current == `(` {
				p.tokens << TokenRef{
					token: .lpar
				}
			}
			p.source.current == `)` {
				p.tokens << TokenRef{
					token: .rpar
				}
			}
			p.source.current == `{` {
				p.tokens << TokenRef{
					token: .lcbr
				}
			}
			p.source.current == `}` {
				p.tokens << TokenRef{
					token: .rcbr
				}
			}
			p.source.current == `[` {
				p.tokens << TokenRef{
					token: .lsbr
				}
			}
			p.source.current == `]` {
				p.tokens << TokenRef{
					token: .rsbr
				}
			}
			p.source.current == `:` {
				p.source.next()
				if p.source.current == `:` {
					p.tokens << TokenRef{
						token: .typespec
					}
				} else {
					continue
				}
			}
			operators_1.index(p.source.current) != -1 {
				mut ops := [p.source.current]
				p.source.next()
				if operators_1.index(p.source.current) != -1 {
					ops << p.source.current
					p.source.next()
					if operators_1.index(p.source.current) != -1 {
						ops << p.source.current
						p.source.next()
					}
				}
				p.tokens << TokenRef{
					token: .operator
				}
				continue
			}
			is_letter(p.source.current) {
				mut idx := 0
				curr := p.source.current
				ident := p.source.get_next_ident()!

				token := match true {
					keywords.index(ident) != -1 { Token.from(ident)! }
					is_capital(curr) { Token.module_name }
					else { Token.ident }
				}

				if token in [.module_name, .ident] {
					idx0 := p.idents.index(ident)
					if idx0 != -1 {
						idx = idx0
					} else {
						idx = p.idents.len
						p.idents << ident
					}
				}

				p.tokens << TokenRef{
					idx:   idx
					table: .idents
					token: token
				}
				continue
			}
			is_string_delimiter(p.source.current) {
				str := p.source.get_next_string()!
				mut idx := p.binaries.len
				idx0 := p.binaries.index(str)
				if idx0 != -1 {
					idx = idx0
				} else {
					idx = p.integers.len
					p.binaries << str
				}
				p.tokens << TokenRef{
					idx:   idx
					table: .binary
					token: .string
				}
				continue
			}
			is_digit(p.source.current) {
				// Todo float, big and integers
				mut idx := p.integers.len
				value, kind := p.source.get_next_number()!
				match kind {
					.integer {
						value1 := value.bytestr().int()
						idx0 := p.integers.index(value1)
						if idx0 != -1 {
							idx = idx0
						} else {
							idx = p.integers.len
							p.integers << value1
						}
						p.tokens << TokenRef{
							idx:   idx
							table: .integers
							token: .integer
						}
					}
					.float {
						value1 := value.bytestr().f64()
						idx0 := p.floats.index(value1)
						if idx0 != -1 {
							idx = idx0
						} else {
							idx = p.floats.len
							p.floats << value1
						}
						p.tokens << TokenRef{
							idx:   idx
							table: .floats
							token: .float
						}
					}
					else {
						return error('TODO implements for bigint and integer64')
					}
				}

				continue
			}
			else {}
		}
		p.source.next()
	}
	return []
}
