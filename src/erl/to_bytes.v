module erl

import math
import math.big
import encoding.binary

pub fn (t Term) bytes(deep bool) ![]u8 {
	term := match t {
		bool {
			bool_to_bytes(t as bool)
		}
		string {
			string_to_bytes(t as string)!
		}
		i8 {
			integer8_to_bytes(t as i8)
		}
		int {
			integer32_to_bytes(t as int)
		}
		f64 {
			float_to_bytes(t as f64)
		}
		// rune {}
		big.Integer {
			big_to_bytes(t as big.Integer)!
		}
		Atom {
			atom_to_bytes(t as Atom)!
		}
		Tuple {
			tuple_to_bytes(t as Tuple)!
		}
		List {
			list_to_bytes(t as List)!
		}
		Binary {
			binary_to_bytes(t as Binary)!
		}
		// Charlist {}
		Nil {
			nil_to_bytes()
		}
		else {
			return error('unhandled ${t}')
		}
	}
	if !deep {
		term.prepend(tag_version)
	}
	return term
}

fn bool_to_bytes(b bool) []u8 {
	mut buf := []u8{}
	if b {
		buf.prepend('true'.bytes())
		buf.prepend(4)
	} else {
		buf.prepend('false'.bytes())
		buf.prepend(5)
	}
	buf.prepend(tag_small_atom_utf8_ext)
	return buf
}

fn atom_to_bytes(a Atom) ![]u8 {
	size := a.val.len
	mut buf := []u8{}
	if size <= max_u8 {
		buf << u8(tag_small_atom_utf8_ext)
		buf << u8(size)
		buf << a.val.bytes()
	} else if size <= max_u16 {
		buf << u8(tag_atom_utf8_ext)
		buf << binary.big_endian_get_u16(u16(size))
		buf << a.val.bytes()
	} else {
		return error('atom is too big ${size}')
	}
	return buf
}

fn big_to_bytes(term big.Integer) ![]u8 {
	mut sign := u8(0)
	if term.signum < 0 {
		sign = 1
	}
	mut value, _ := term.bytes()
	length := value.len
	mut buf := []u8{}
	if length < u64(1) << 8 - 1 {
		n0 := u8(length)
		buf.prepend(sign)
		buf.prepend(n0)
		buf.prepend(tag_small_big_ext)
	} else if i64(length) < u64(1) << 32 - 1 {
		n0 := binary.big_endian_get_u32(u32(length))
		buf.prepend(sign)
		buf.prepend(n0)
		buf.prepend(tag_large_big_ext)
	} else {
		return error('u32 overflow')
	}
	half := length >> 1
	i_last := length - 1
	for i0 := 0; i0 < half; i0++ {
		j0 := i_last - i0
		value[i0], value[j0] = value[j0], value[i0]
	}
	buf.insert(buf.len, value)
	return buf
}

fn string_to_bytes(term string) ![]u8 {
	size := term.len

	if size == 0 {
		return nil_to_bytes()
	} else if size < max_u16 {
		mut buf := []u8{}
		buf << tag_string_ext
		buf << binary.big_endian_get_u16(u16(size))
		buf << term.bytes()
		return buf
		// } else if u64(size) < u64(1) << 32 - 1 {
		// 	mut buf := []u8{}
		// 	for i0 := 0; i0 < size; i0++ {
		// 		buf << tag_small_integer_ext
		// 		buf << u8(term[i0])
		// 	}
		// 	buf << tag_list_ext
		// 	buf << binary.big_endian_get_u32(u32(size))
		// 	buf << tag_nil_ext
		// 	return buf
	} else {
		return error('u32 overflow')
	}
}

fn float_to_bytes(value f64) []u8 {
	mut buf := binary.big_endian_get_u64(u64(math.f64_bits(f64(value))))
	buf.prepend(tag_new_float_ext)
	return buf
}

// fn old_float_to_bytes(value f64) []u8 {
// 	fstr := strconv.f64_to_str_l(value).bytes()
// 	mut buf := []u8{len: 31 - fstr.len}
// 	buf.prepend(fstr)
// 	buf.prepend(tag_float_ext)
// 	buf.prepend(tag_version)
// 	return buf
// }

fn integer8_to_bytes(term i8) []u8 {
	return [u8(tag_small_integer_ext), u8(term)]
}

fn integer32_to_bytes(term int) []u8 {
	mut buf := binary.big_endian_get_u32(u32(term))
	buf.prepend(tag_integer_ext)
	return buf
}

fn nil_to_bytes() []u8 {
	return [u8(tag_nil_ext)]
}

fn binary_to_bytes(term Binary) ![]u8 {
	size := term.value.len
	if size <= max_i32 {
		mut buf := []u8{}
		buf << u8(tag_binary_ext)
		buf << binary.big_endian_get_u32(u32(size))
		buf << (term.value)
		return buf
	}
	return error('u32 overflow')
}

fn binary_object_to_bytes(term Binary) ![]u8 {
	length := term.value.len
	if term.bits < 1 || term.bits > 8 {
		return error('invalid Binary bits')
	}
	if u64(length) < u64(1) << 32 - 1 {
		mut buf := []u8{}
		if term.bits != 8 {
			buf.prepend(term.value)
			buf.prepend(u8(term.bits))
			buf.prepend(binary.big_endian_get_u32(u32(length)))
			buf.prepend(u8(tag_bit_binary_ext))
		} else {
			buf.prepend(term.value)
			buf.prepend(binary.big_endian_get_u32(u32(length)))
			buf.prepend(u8(tag_binary_ext))
		}
		return buf
	}
	return error('u32 overflow')
}

fn tuple_to_bytes(tuple Tuple) ![]u8 {
	size := tuple.terms.len
	mut buf := []u8{}
	if size <= max_u8 {
		buf << u8(tag_small_tuple_ext)
		buf << u8(size)
	} else {
		buf << u8(tag_large_tuple_ext)
		buf << binary.big_endian_get_u32(u32(size))
	}
	for term in tuple.terms {
		buf << term.bytes(true)!
	}
	return buf
}

fn list_to_bytes(list List) ![]u8 {
	size := list.terms.len
	mut buf := []u8{}
	if size > 0 {
		buf << u8(tag_list_ext)
		buf << binary.big_endian_get_u32(u32(size))
		for term in list.terms {
			buf << term.bytes(true)!
		}
	}
	buf << nil_to_bytes()
	return buf
}
