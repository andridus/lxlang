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
	mut parser := Parser{
		source: &src
	}
	parser.parse_tokens() or {
		println(err.msg())
		exit(1)
	}
	elapsed := time.since(start)
	println(parser)
	println('Tempo de execução: ${elapsed}')
}
