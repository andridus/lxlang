struct TokenRef {
	token Token
	idx   int
	table TableEnum
}

enum TableEnum {
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
}
