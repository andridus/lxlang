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

enum Token {
	nil
	eof
	ident
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
