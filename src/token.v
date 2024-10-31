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
	keyword
	module_name
	integer
}

const keywords = ['defmodule', 'def', 'defp', 'end', 'do', 'defmacro', 'defmacrop']
