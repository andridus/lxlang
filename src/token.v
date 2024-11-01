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
}

enum Number {
	integer
	integer64
	big
	float
}
