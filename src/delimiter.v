module main

pub fn is_string_delimiter(ch u8) bool {
	return ch == `\"`
}

pub fn is_space_delimiter(ch u8) bool {
	return ch in [` `, `\n`]
}

pub fn is_digit(a u8) bool {
	return a >= `0` && a <= `9`
}

pub fn is_letter(a u8) bool {
	return (a >= `a` && a <= `z`) || (a >= `A` && a <= `Z`) || a == `_`
}

pub fn is_alpha(a u8) bool {
	return is_digit(a) || is_letter(a)
}
