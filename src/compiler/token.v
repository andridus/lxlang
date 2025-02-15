module compiler

enum TableEnum {
	none
	atoms
	binary
	ignored_strings
	idents
	integers
	bigints
	floats
	consts
	modules
	functions
	functions_caller
	functions_caller_undefined
}

pub enum Token {
	nil
	eof
	linebreak
	ident
	import
	alias
	string
	lcbr
	rcbr
	lpar
	rpar
	lsbr
	rsbr
	comma
	arroba
	typespec
	attrib
	colon
	module_name
	atom_key
	struct
	percent
	moduledoc
	integer
	float
	do
	end
	eq
	defmodule
	def
	defp
	defmacro
	defmacrop
	cond
	not
	when
	case
	default_arg
	operator
	function_name
	caller_function
	__aliases__
	__block__
	pipe
	match
	ignore
}

enum Number {
	integer
	integer64
	big
	float
}
