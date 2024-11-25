module erl

import os
import encoding.binary
import math

// Unlike a Buffer, a Reader is a read-only and supports seeking.
// The zero value for Reader operates like a Reader of an empty slice.
pub struct Reader {
	s []u8
mut:
	i         i64
	prev_rune int
}

// Len returns the number of bytes of the unread portion of the slice
pub fn (r &Reader) length() int {
	if r.i >= i64(r.s.len) {
		return 0
	}
	return int(i64(r.s.len) - r.i)
}

pub fn (mut r Reader) seek(offset i64, whence os.SeekMode) !i64 {
	r.prev_rune = -1
	mut abs := i64(0)
	match whence {
		.start {
			abs = offset
		}
		.current {
			abs = r.i + offset
		}
		.end {
			abs = i64(r.s.len) + offset
		}
	}
	if abs < 0 {
		error('bytes.seek: negative position')
	}
	r.i = abs
	return abs
}

pub fn (mut r Reader) read_until_offset(offset i64) ![]u8 {
	if offset < 0 {
		return error('bytes.read_at: negative offset')
	}
	if offset > i64(r.s.len) {
		return error('EOF')
	}
	return r.s[r.i..offset]
}

pub fn (mut r Reader) read_from_offset_to(from i64, to i64) ![]u8 {
	if to < 0 {
		return error('bytes.read_at: negative offset')
	}
	if to > i64(r.s.len) {
		return error('EOF')
	}

	return r.s[from..to]
}

pub fn (mut r Reader) read_from_offset(offset i64) ![]u8 {
	if offset < 0 {
		return error('bytes.read_at: negative offset')
	}
	if offset > i64(r.s.len) {
		return error('EOF')
	}
	return r.s[offset..]
}

pub fn (mut r Reader) read_byte() !u8 {
	r.prev_rune = -1
	if r.i >= i64(r.s.len) {
		return error('EOF')
	}
	b := r.s[r.i]
	r.i++
	return b
}

pub fn (mut r Reader) read_bytes(len int) ![]u8 {
	mut bin := []u8{}
	for _ in 0 .. len {
		bin << r.read_byte()!
	}
	return bin
}

pub fn new_reader(b []u8) Reader {
	return Reader{b, 0, -1}
}

fn (mut r Reader) read_from(data_size int) ![]u8 {
	mut buf := []u8{cap: data_size}

	for _ in 0 .. data_size {
		buf << r.read_byte()!
	}
	return buf
}

pub fn (mut r Reader) read_bool() !bool {
	data_size := 1
	bs := r.read_from(data_size)!
	return bs[0] != 0
}

pub fn (mut r Reader) read_f32() !f32 {
	data_size := 4
	bs := r.read_from(data_size)!
	return math.f32_from_bits(binary.big_endian_u32(bs))
}

pub fn (mut r Reader) read_f64() !f64 {
	data_size := 8
	bs := r.read_from(data_size)!
	return math.f64_from_bits(binary.big_endian_u64(bs))
}

// pub fn (mut r Reader) read_i8() i8 {
// 	data_size := 1

// }
// pub fn (mut r Reader) read_i16() i16 {
// 	data_size := 2
// }
pub fn (mut r Reader) read_i32() !int {
	data_size := 4
	bs := r.read_from(data_size)!
	return int(binary.big_endian_u32(bs))
}

// pub fn (mut r Reader) read_i64() i64 {
// 	data_size := 8
// }
pub fn (mut r Reader) read_u8() !u8 {
	data_size := 1
	bs := r.read_from(data_size)!
	return bs[0]
}

pub fn (mut r Reader) read_u16() !u16 {
	data_size := 2
	bs := r.read_from(data_size)!
	return binary.big_endian_u16(bs)
}

pub fn (mut r Reader) read_u32() !u32 {
	data_size := 4
	bs := r.read_from(data_size)!
	return binary.big_endian_u32(bs)
}

// pub fn (mut r Reader) read_u64() u64 {
// 	data_size := 8
// }

// pub fn (mut r Reader) read_f64() f64 {
// 	data_size := 4
// }
