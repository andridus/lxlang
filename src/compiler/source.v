module compiler

struct Source {
	src []u8
mut:
	i       int
	total   int
	current u8
	peak    u8
}

pub fn Source.new(src []u8) Source {
	return Source{
		src:     src
		total:   src.len
		current: src[0]
		peak:    src[1]
	}
}

fn (mut s Source) next() {
	if s.i < s.total - 1 {
		s.i++
		s.current = s.src[s.i]
		if s.i + 1 < s.total {
			s.peak = s.src[s.i + 1]
		} else {
			s.peak = 0
		}
	}
}

fn (s Source) eof() bool {
	return s.i >= s.total - 1
}

fn (s Source) peak_eof() bool {
	return s.i + 1 >= s.total - 1
}

fn (mut s Source) advance_multi() bool {
	len1 := s.total - s.i
	if len1 > 3 && s.src[s.i..(s.i + 3)] == [u8(34), 34, 34] {
		s.i += 2
		return true
	}
	return false
}

fn (mut s Source) get_next_string() !string {
	if is_string_delimiter(s.current) {
		is_mult := s.advance_multi()

		mut bin := []u8{}
		for !s.eof() {
			s.next()
			if is_string_delimiter(s.current) {
				s.advance_multi()
				s.next()
				break
			} else {
				bin << s.current
			}
		}
		if is_mult {
			return bin.bytestr().trim_space()
		} else {
			return bin.bytestr()
		}
	}
	return error('not a string')
}

fn (mut s Source) get_next_ident() !string {
	mut bin := [s.current]
	for !s.peak_eof() {
		peak := s.src[s.i + 1]
		if is_broken_ident(peak) || is_symbol(peak) {
			break
		} else {
			s.next()
		}
		bin << s.current
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
	for !s.eof() {
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