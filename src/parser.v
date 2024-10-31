struct Parser {
mut:
	source   Source
	binaries []string
	idents   []string
	tokens   []TokenRef
}

fn (mut p Parser) parse_tokens() ![]TokenRef {
	for p.source.eof() == false {
		match true {
			p.source.current == `(` {
				p.tokens << TokenRef{
					token: Token.lpar
				}
			}
			p.source.current == `)` {
				p.tokens << TokenRef{
					token: Token.rpar
				}
			}
			p.source.current == `{` {
				p.tokens << TokenRef{
					token: Token.lcbr
				}
			}
			p.source.current == `}` {
				p.tokens << TokenRef{
					token: Token.rcbr
				}
			}
			p.source.current == `[` {
				p.tokens << TokenRef{
					token: Token.lsbr
				}
			}
			p.source.current == `]` {
				p.tokens << TokenRef{
					token: Token.rsbr
				}
			}
			p.source.current == `@` {
				p.tokens << TokenRef{
					token: Token.arroba
				}
			}
			p.source.current == `:` {
				p.source.next()
				if p.source.current == `:` {
					p.tokens << TokenRef{
						token: Token.typespec
					}
				} else {
					continue
				}
			}
			is_space_delimiter(p.source.current) {
				p.source.next()
				continue
			}
			is_letter(p.source.current) {
				curr := p.source.current
				mut token := Token.ident
				ident := p.source.get_next_ident()!
				if keywords.index(ident) != -1 {
					token = Token.keyword
				} else if is_capital(curr) {
					token = Token.module_name
				}
				mut idx := 0
				idx_v := p.idents.index(ident)
				if idx_v != -1 {
					idx = idx_v
				} else {
					idx = p.idents.len
					p.idents << ident
				}
				p.tokens << TokenRef{
					idx:   idx
					table: TableEnum.idents
					token: token
				}
				continue
			}
			is_string_delimiter(p.source.current) {
				str := p.source.get_next_string()!
				idx := p.binaries.len
				p.binaries << str
				p.tokens << TokenRef{
					idx:   idx
					table: TableEnum.binary
					token: Token.string
				}
				continue
			}
			is_digit(p.source.current) {
				// Todo float, big and integers
				p.source.get_next_number()!
				p.tokens << TokenRef{
					token: Token.integer
				}
				continue
			}
			else {}
		}
		p.source.next()
	}
	return []
}
