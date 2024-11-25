import encoding.binary

fn u32_to_byte(value u32) []u8 {
	return binary.big_endian_get_u32(value)
	// return [
	// 	u8((value >> 24) & 0xFF),
	// 	u8((value >> 16) & 0xFF),
	// 	u8((value >> 8) & 0xFF),
	// 	u8(value & 0xFF),
	// ]
}
