struct Source {
	src []u8
mut:
	i       int
	total   int
	current u8
}

fn (mut s Source) next() {
	s.i++
	if s.i < s.total {
		s.current = s.src[s.i]
	}
}

fn (s Source) eof() bool {
	return s.i >= s.total
}

fn (mut s Source) get_next_string() !string {
	if is_string_delimiter(s.current) {
		mut bin := []u8{}
		for s.eof() == false {
			s.next()
			if is_string_delimiter(s.current) {
				s.next()
				break
			} else {
				bin << s.current
			}
		}
		return bin.bytestr()
	}
	return error('not a string')
}

fn (mut s Source) get_next_ident() !string {
	mut bin := []u8{}
	for s.eof() == false {
		if is_broken_ident(s.current) || is_symbol(s.current) {
			break
		} else {
			bin << s.current
		}
		s.next()
	}
	if bin.len == 0 {
		return error('not a ident')
	} else {
		return bin.bytestr()
	}
}

fn (mut s Source) get_next_number() !([]u8, Number) {
	mut kind := Number.integer
	mut numbers := []u8{}
	for s.eof() == false {
		match true {
			is_digit(s.current) {
				numbers << s.current
			}
			s.current == `_` {
				s.next()
				continue
			}
			s.current == `.` && kind != .float {
				numbers << s.current
				kind = .float
			}
			s.current == `.` && kind == .float {
				return error('invalid number')
			}
			else {
				break
			}
		}
		s.next()
	}
	if numbers.len == 0 {
		return error('not a number')
	} else {
		return numbers, kind
	}
}
