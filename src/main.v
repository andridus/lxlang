module main

import compiler
import os

fn main() {
	path := os.args[1]

	options := compiler.CompilerOptions{
		returns: .beam_file
	}
	mut c := compiler.Compiler.new(options, path)!

	response := c.generate_beam() or {
		println(err.msg())
		println('error on generate beam')
		exit(1)
	}

	println(response)
}
