struct TokenRef {
	token Token
	idx   int
	table TableEnum
}

fn (t TokenRef) str() string {
	if t.table != .none {
		return '${t.token.str()}:${t.idx}'
	} else {
		return '${t.token.str()}'
	}
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
	comma
	arroba
	typespec
	colon
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
	caller_function
}

enum Number {
	integer
	integer64
	big
	float
}
