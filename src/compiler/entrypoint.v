module compiler

import os

const default_types = [
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

pub fn Compiler.new(path string, src []u8) Compiler {
	source := Source.new(src)
	return Compiler{
		source:       &source
		filesource:   path
		token_before: &TokenRef{}
		types:        default_types
	}
}

pub fn (mut c Compiler) generate_beam() ! {
	for !c.source.eof() {
		c.parse_next_token()!
	}
	if c.tokens.len > 0 {
		node := c.parse_stmt()!
		c.nodes = node
	}
	println(c.nodes.to_str(0))
	c.beam_to_file()!
}

fn (mut c Compiler) beam_to_file() ! {
	module_name := c.get_module_name()!
	beam_bytes := c.to_beam()!
	os.write_file_array('${module_name}.beam', beam_bytes)!
}
