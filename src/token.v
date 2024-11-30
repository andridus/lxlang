struct TokenRef {
	token Token
	idx   int
	table TableEnum
}

fn (t TokenRef) to_node() NodeEl {
	return match t.token {
		.module_name {
			NodeEl(Node{
				left:  TokenRef{
					token: .__aliases__
				}
				right: [NodeEl(t)]
			})
		}
		.ident, .function_name, .caller_function {
			NodeEl(Node{
				left: t
			})
		}
		else {
			NodeEl(t)
		}
	}
}

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
