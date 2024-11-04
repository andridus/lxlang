module main

import os
import time

fn main() {
	path := os.args[1]

	prepare(path)
}

fn prepare(path string) {
	start := time.now()
	mut source := os.read_bytes(path) or {
		println('File \'${path}\' not found ')
		exit(1)
	}
	if source.len == 0 {
		exit(1)
	}
	mut src := Source{
		src:     source
		total:   source.len
		current: source[0]
		peak:    source[1]
	}
	mut lexer := Lexer{
		source:       &src
		token_before: &TokenRef{}
		types:        default_types()
	}
	for !lexer.source.eof() {
		lexer.parse_next_token() or {
			println(err.msg())
			exit(1)
		}
	}
	elapsed := time.since(start)
	println(lexer)
	println('Tempo de execução: ${elapsed}')
}

fn default_types() []string {
	return [
		'any',
		'nil',
		'atom',
		'boolean',
		'string',
		'integer',
		'float',
		'list',
		'tuple',
	]
}
