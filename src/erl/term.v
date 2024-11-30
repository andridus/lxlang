module erl

import math.big
import bitfield

type Term = bool
	| string
	| i8
	| int
	| f64
	| rune
	| big.Integer
	| Atom
	| Tuple
	| List
	| Binary
	| Charlist
	| Nil
	| Map

struct Nil {}

struct Atom {
	val string
}

struct Map {
	val map[string]Term
}

struct Tuple {
	terms []Term
}

struct List {
	terms []Term
}

struct Binary {
	bits  int
	value []u8
}

struct Charlist {
	size  int
	terms []rune
}

pub fn Map.new(val map[string]Term) Term {
	return Term(Map{val})
}

pub fn Atom.new(val string) Term {
	return Term(Atom{val})
}

pub fn Tuple.new(terms []Term) Term {
	return Term(Tuple{terms})
}

pub fn List.new(terms []Term) Term {
	return Term(List{terms})
}

pub fn Nil.new() Term {
	return Term(Nil{})
}

pub fn Binary.new(bin string) Term {
	size := bitfield.from_bytes([bin[bin.len - 1]]).get_size()
	return Term(Binary{
		bits:  u8(size)
		value: bin.bytes()
	})
}
