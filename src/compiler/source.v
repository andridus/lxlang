module compiler

struct Source {
	src []u8
mut:
	i       int
	total   int
	line    int = 1
	char    int
	current u8
	peak    u8
}

pub fn Source.new(src []u8) Source {
	mut src0 := src.clone()
	src0 << u8(0)
	return Source{
		src:     src0
		total:   src0.len
		current: src0[0]
		peak:    src0[1]
	}
}

fn (mut s Source) next() {
	if s.i < s.total - 1 {
		s.i++
		s.current = s.src[s.i]
		if s.current == `\n` {
			s.line++
			s.char = 0
		} else {
			s.char++
		}
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

fn (s Source) match_peak_at_more(pos int, m u8) bool {
	if s.i + pos < s.total {
		return s.src[s.i + pos] == m
	}
	return false
}

fn (mut s Source) advance_multi() bool {
	len1 := s.total - s.i
	if len1 > 3 && s.src[s.i..(s.i + 3)] == [u8(34), 34, 34] {
		s.i += 2
		s.char += 2
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
				if is_mult && s.advance_multi() {
					s.next()
					break
				} else if is_mult {
					// bin << s.current
				} else {
					break
				}
			} else {
				bin << s.current
			}
		}
		if is_mult {
			return bin.bytestr().trim('\n')
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
	mut numbers := [s.current]
	for !s.eof() {
		match true {
			is_digit(s.peak) {
				numbers << s.peak
			}
			s.peak == `_` {
				s.next()
				continue
			}
			s.peak == `.` && kind != .float {
				numbers << s.peak
				kind = .float
			}
			s.peak == `.` && kind == .float {
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
