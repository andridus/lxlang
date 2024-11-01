struct TokenRef {
	token Token
	idx   int
	table TableEnum
}

fn (t TokenRef) str() string {
	return t.token.str()
}

enum TableEnum {
	none
	atoms
	binary
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
	ident
	string
	lcbr
	rcbr
	lpar
	rpar
	lsbr
	rsbr
	arroba
	typespec
	module_name
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
}

enum Number {
	integer
	integer64
	big
	float
}
