module main

import compiler
import cli { Command, Flag }
import lsp
import os

fn main() {
	mut cmd := Command{
		name:        'Lx'
		description: 'A compiler for elixir with steroids.'
		version:     '0.0.1'
	}
	mut language_server := Command{
		name:          'ls'
		description:   'Execute the language server'
		usage:         '<name>'
		required_args: 0
		execute:       start_language_server
	}
	mut comp := Command{
		name:          'compile'
		description:   'Execute the elixir compiler'
		usage:         '<name>'
		required_args: 1
		execute:       start_compiler
	}
	language_server.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        '-stdio'
		description: 'Transport kind via Stdio.'
	})
	cmd.add_command(language_server)
	cmd.add_command(comp)
	cmd.setup()
	cmd.parse(os.args)
}

fn start_language_server(cmd Command) ! {
	stdio := cmd.flags.get_bool('-stdio') or { false }
	if stdio {
		lsp.start(true)
	} else {
		lsp.start(false)
	}
}

fn start_compiler(cmd Command) ! {
	path := cmd.args[0]
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
