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
			is_space_delimiter(p.source.current) {
				p.source.next()
				continue
			}
			is_letter(p.source.current) {
				ident := p.source.get_next_ident()!
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
					token: Token.ident
				}
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
			}
			else {}
		}
		p.source.next()
	}
	return []
}
