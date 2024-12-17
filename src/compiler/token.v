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
}

pub enum Token {
	nil
	eof
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
	percent
	moduledoc
	integer
	float
	do
	end
	defmodule
	def
	defp
	defmacro
	defmacrop
	default_arg
	operator
	function_name
	caller_function
	__aliases__
	__block__
	ignore
}

enum Number {
	integer
	integer64
	big
	float
}
