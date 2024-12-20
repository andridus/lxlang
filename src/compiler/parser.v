module compiler

fn (mut c Compiler) parse_stmt() !Node0 {
	c.next_token()
	match c.current_token.token {
		.defmodule {
			return c.parse_module()!
		}
		.import {
			return c.parse_import()!
		}
		.alias {
			return c.parse_alias()!
		}
		.def, .defp {
			return c.parse_function()!
		}
		else {
			return c.parse_expr()!
		}
	}
	return error('unhandled this error')
}

fn (mut c Compiler) parse_expr() !Node0 {
	mut term := c.parse_term()!
	mut is_should_match := false
	mut type_id := 0
	mut type_match := ''
	if c.in_function_args {
		if attrs := c.mount_match(term) {
			if attrs.type_match.len > 0 {
				is_should_match = true
				type_id = attrs.type_id
				type_match = attrs.type_match
			}
		}
	}
	if is_should_match {
		attrs := NodeAttributes{
			is_should_match: is_should_match
			type_id:         type_id
			type_match:      type_match
		}
		left_term := term.left()
		right_term := term.right()
		match_term := Tuple2.new(TokenRef{ token: .match }, right_term)
		term = Tuple3.new_attrs(left_term, match_term, attrs)
	}
	if c.peak_token.token == .operator {
		c.next_token()
		match c.current_token.bin {
			'=>' {
				c.next_token()
				return Tuple3.new(term, c.parse_expr()!)
			}
			'=' {
				// need to be check if is a matchble expression
				c.next_token()
				right := c.parse_expr()!
				attrs := NodeAttributes{
					is_should_match: is_should_match
					type_id:         type_id
					type_match:      type_match
				}
				return Tuple3.new_attrs(TokenRef{ token: .match }, [term, right], attrs)
			}
			'==' {
				// need to be check if is a equals expressions
				c.next_token()
				right := c.parse_expr()!
				attrs := NodeAttributes{
					is_should_match: is_should_match
					type_id:         type_id
					type_match:      type_match
				}
				return Tuple3.new_attrs(TokenRef{ token: .eq }, [term, right], attrs)
			}
			'in' {
				in_tok := TokenRef{
					...c.current_token
				}
				c.next_token()
				right := c.parse_expr()!
				return Tuple3.new(in_tok, [term, right])
			}
			'|>' {
				c.next_token()
				right := c.parse_expr()!
				return Tuple3.new(TokenRef{ token: .pipe }, [term, right])
			}
			'->' {
				// bypass to handle inside defined functions
				return term
			}
			else {
				return error('To do something with this operator `${c.current_token.bin}`')
			}
		}
	}
	return term
}

fn (mut c Compiler) parse_term() !Node0 {
	match c.current_token.token {
		.module_name {
			return c.current_token
		}
		.not {
			not_token := TokenRef{
				...c.current_token
			}
			c.next_token()
			return Tuple3.new(not_token, c.parse_expr()!)
		}
		.cond {
			c.match_next(.do)!
			mut clauses := []Node0{}
			mut clauses_header := map[int]Node0{}
			mut clauses_body := map[int][]Node0{}
			mut i := 0
			for c.peak_token.token != .end {
				c.next_token()
				clause := c.parse_expr()!

				if c.current_token.token == .operator && c.current_token.bin == '->' {
					i++
					clauses_header[i] = clause
				} else {
					clauses_body[i] << clause
				}
			}
			c.match_next(.end)!
			for i0, clause in clauses_header {
				clauses << Tuple3.new(clause, clauses_body[i0])
			}
			return Tuple3.new(TokenRef{ token: .cond }, clauses)
		}
		.percent {
			// only for maps
			// c.next_token()
			mut has_struct := false
			mut struct_name := TokenRef{}
			if c.opt_match_next(.module_name) {
				has_struct = true
				struct_name = c.current_token
			}
			c.match_next(.lcbr)!
			mut keyword_list := []Node0{}
			// c.next_token()
			for c.peak_token.token != .rcbr {
				c.next_token()
				key_value := c.parse_expr()!
				keyword_list << key_value
				if c.peak_token.token == .comma {
					c.next_token()
				}
			}
			c.match_next(.rcbr)!
			right := if has_struct { [Node0(struct_name), keyword_list] } else { keyword_list }
			return Tuple3.new(TokenRef{ token: .percent }, right)
		}
		.lsbr {
			// lists
			// TODO fix lists
			mut items := []Node0{}
			for c.peak_token.token != .rsbr {
				c.next_token()
				items << c.parse_expr()!
				if c.peak_token.token == .comma {
					c.next_token()
				}
			}
			c.match_next(.rsbr)!
			return items
		}
		.lcbr {
			// tuples
			// TODO fix tuples
			mut items := []Node0{}
			for c.peak_token.token != .rcbr {
				c.next_token()
				items << c.parse_expr()!
				if c.peak_token.token == .comma {
					c.next_token()
				}
			}
			c.match_next(.rcbr)!
			return items
		}
		.arroba {
			return c.parse_arroba()!
		}
		.caller_function {
			return c.parse_caller_function()!
		}
		.colon {
			return c.parse_atom()!
		}
		.ident {
			return c.parse_ident()!
		}
		.atom_key {
			mut keyword_list := []Node0{}
			atom := TokenRef{
				...c.current_token
			}
			for {
				c.next_token()
				value := c.parse_expr()!
				keyword_list << Tuple2.new(atom, value)
				if c.peak_token.token != .comma {
					break
				}
				if c.current_token.token != .atom_key {
					break
				}
			}
			return Node0(keyword_list)
		}
		.operator {
			match c.current_token.bin {
				'^' {
					eprintln('The ^ should be get the binded value')
				}
				else {
					eprintln('Unhandled the operator `${c.current_token.bin}` and bypass')
				}
			}
			c.next_token()
			return c.parse_term()!
		}
		.float {
			mut ident := TokenRef{
				...c.current_token
			}
			ident.type_id = c.types.index('float')
			return ident
		}
		.integer {
			mut ident := TokenRef{
				...c.current_token
			}
			ident.type_id = c.types.index('integer')
			return ident
		}
		.string {
			mut ident := TokenRef{
				...c.current_token
			}
			ident.type_id = c.types.index('string')
			return ident
		}
		else {}
	}
	return c.parse_error('parse_term()', c.current_token)
}

fn into_block(elems []Node0) Node0 {
	if elems.len == 1 {
		return elems[0]
	} else {
		return Tuple3{
			left:  TokenRef{
				token: .__block__
			}
			right: elems
		}
	}
}

fn (mut c Compiler) put_returns_into_function(function_idx int) ! {
	if atom := c.get_ident_value(c.current_token) {
		mut type_idx := c.types.len
		type_idx0 := c.types.index(atom)
		if type_idx0 != -1 {
			type_idx = type_idx0
		} else {
			c.types << atom
		}
		c.functions[function_idx].returns = type_idx
	}
}

fn (c Compiler) parse_error(func string, token TokenRef) IError {
	return error('[${c.filesource}:${token.pos_line}:${token.pos_char}] `${func}` not defined for ${token}')
}

fn (c Compiler) parse_error_custom(str string, token TokenRef) IError {
	return error('[${c.filesource}:${token.pos_line}:${token.pos_char}] ${str}')
}
