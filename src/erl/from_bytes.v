module erl

import strconv

pub fn from_bytes(data []u8) !Term {
	size := data.len
	if size <= 1 {
		return error('Null Input')
	}
	mut reader := new_reader(data)
	version := reader.read_byte() or { return err }
	if version != tag_version {
		return error('invalid version')
	}
	i, term := do_binary_to_term(1, mut reader) or { return err }
	if i != size {
		return error('unparsed data')
	}
	return term
}

fn do_binary_to_term(i int, mut reader Reader) !(int, Term) {
	tag := reader.read_byte() or { return err }
	mut i0 := i + 1

	match tag {
		tag_nil_ext {
			return i0, Nil.new()
		}
		tag_atom_ext, tag_atom_utf8_ext {
			return atom_from_bytes()
		}
		tag_small_atom_ext, tag_small_atom_utf8_ext {
			return small_atom_from_bytes()
		}
		tag_small_integer_ext {
			val := reader.read_byte() or { return err }
			i0 += 1
			return i0, Term(i8(val))
		}
		tag_integer_ext {
			val := reader.read_i32()!
			i0 += 4
			return i0, Term(int(val))
		}
		tag_small_big_ext, tag_large_big_ext {
			return big_from_bytes()!
		}
		tag_new_float_ext {
			val := reader.read_f64()!
			return i0 + 8, Term(f64(val))
		}
		tag_float_ext {
			value := reader.read_bytes(31)!
			fvalue := strconv.atof64(value.bytestr())!
			return i0 + 31, Term(f64(fvalue))
		}
		tag_string_ext {
			return string_from_bytes()!
		}
		tag_binary_ext {
			return binary_from_bytes()!
		}
		tag_bit_binary_ext {
			return bit_binary_from_bytes()!
		}
		else {
			return error('Invalid TAG')
		}
	}
}

fn small_atom_from_bytes() !(int, Term) {
	return 0, Nil.new()
	// val := binary.read_u8(mut reader, binary.big_endian)!
	// j := int(val)
	// i0 += 1
	// mut value := []u8{len: j}

	// if j > 0 {
	// 	value = reader.read_bytes(j)!
	// }
	// pos := i0 + int(j)
	// str := value.bytestr()
	// match str {
	// 	'true' {
	// 		return pos, Term(true)
	// 	}
	// 	'false' {
	// 		return pos, ErlBoolean(false)
	// 	}
	// 	'undefined' {
	// 		return pos, ErlNil{}
	// 	}
	// 	else {
	// 		match tag {
	// 			tag_atom_ext {
	// 				return pos, ErlAtomUTF8(str)
	// 			}
	// 			tag_atom_utf8_ext {
	// 				return pos, ErlAtom(str)
	// 			}
	// 			else {
	// 				return error('Invalid tag clause')
	// 			}
	// 		}
	// 	}
	// }
}

fn atom_from_bytes() !(int, Term) {
	return 0, Nil.new()
	// val := read_u16(mut reader, binary.big_endian)!
	// j := int(val)
	// i0 += 2

	// mut value := []u8{cap: j}

	// if j > 0 {
	// 	value = reader.read_bytes(j)!
	// }

	// pos := i0 + int(j)
	// str := value.bytestr()
	// match str {
	// 	'true' {
	// 		return pos, Term(true)
	// 	}
	// 	'false' {
	// 		return pos, Term(false)
	// 	}
	// 	'undefined' {
	// 		return pos, Nil.new()
	// 	}
	// 	else {
	// 		match tag {
	// 			tag_atom_ext {
	// 				return pos, Atom.new(str)
	// 			}
	// 			tag_atom_utf8_ext {
	// 				return pos, Atom.new(str) //need put options
	// 			}
	// 			else {
	// 				return error('Invalid tag clause')
	// 			}
	// 		}
	// 	}
	// }
}

fn big_from_bytes() !(int, Term) {
	return 0, Nil.new()
	// mut j0 := 0

	// 		match tag {
	// 			tag_small_big_ext {
	// 				val := reader.read_byte()!
	// 				i0 += 1
	// 				j0 = int(val)
	// 			}
	// 			tag_large_big_ext {
	// 				val := binary.read_u32(mut reader, binary.big_endian)!
	// 				i0 += 4
	// 				j0 = int(val)
	// 			}
	// 			else {
	// 				// error('invalid tag case')
	// 			}
	// 		}
	// 		// i0 += j0
	// 		sign := reader.read_byte()!
	// 		i0 += 1
	// 		mut digits := reader.read_until_offset(i64(i0 + j0))!
	// 		{
	// 			half := digits.len >> 1
	// 			i_last := digits.len - 1
	// 			for i1 := 0; i1 < half; i1++ {
	// 				j1 := i_last - i1
	// 				digits[i1], digits[j1] = digits[j1], digits[i1]
	// 			}
	// 		}
	// 		bignum := big.integer_from_bytes(digits)
	// 		if sign == 1 {
	// 			bignum.neg()
	// 		}
	// 		return i0 + j0, ErlIntegerBig(bignum)
}

fn string_from_bytes() !(int, Term) {
	return 0, Nil.new()
	// val := binary.read_u16(mut reader, binary.big_endian)!
	// 		j := int(val)
	// 		i0 += 2
	// 		mut value := []u8{len: j}

	// 		if j > 0 {
	// 			value = reader.read_bytes(j)!
	// 		}
	// 		pos := i0 + int(j)
	// 		str := value.bytestr()
	// 		return pos, ErlString(str)
}

fn binary_from_bytes() !(int, Term) {
	return 0, Nil.new()
	// val := binary.read_u32(mut reader, binary.big_endian)!
	// 		j := int(val)
	// 		i0 += 4
	// 		mut value := []u8{len: j}
	// 		if j > 0 {
	// 			value = reader.read_bytes(j)!
	// 		}
	// 		pos := i0 + int(j)
	// 		return pos, ErlBinary{
	// 			value: value
	// 			bits: 8
	// 		}
}

fn bit_binary_from_bytes() !(int, Term) {
	return 0, Nil.new()
	// val := binary.read_u32(mut reader, binary.big_endian)!
	// 		j := int(val)
	// 		i0 += 4
	// 		bits := reader.read_byte()!
	// 		mut value := []u8{len: j}
	// 		if j > 0 {
	// 			value = reader.read_bytes(j)!
	// 		}
	// 		pos := i0 + int(j)
	// 		return pos, ErlBinary{
	// 			value: value
	// 			bits: bits
	// 		}
}
