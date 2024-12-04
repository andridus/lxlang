module main

import compiler
import os
import time

fn main() {
	path := os.args[1]

	start := time.now()
	mut source := os.read_bytes(path) or {
		println('File \'${path}\' not found ')
		exit(1)
	}
	if source.len == 0 {
		exit(1)
	}
	mut c := compiler.Compiler.new(path, source)
	elapsed := time.since(start)
	c.generate_beam() or {
		println(err.msg())
		println('error on generate beam')
		exit(1)
	}
	println('Tempo de execução: ${elapsed}')
}
