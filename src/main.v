module main

import os
import time

fn main() {
	path := os.args[1]

	prepare(path)
}

fn prepare(path string) {
	start := time.now()
	source := os.read_bytes(path) or {
		println('File \'${path}\' not found ')
		exit(1)
	}
	mut src := Source{
		src:     source
		total:   source.len
		current: source[0]
	}
	mut lexer := Lexer{
		source:       &src
		token_before: &TokenRef{}
		types:        default_types()
	}
	for lexer.source.eof() == false {
		lexer.parse_tokens() or {
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
