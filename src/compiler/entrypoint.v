module compiler

import os
import time

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

pub fn Compiler.new(options CompilerOptions, path string) !Compiler {
	mut src := os.read_bytes(path)!
	if src.len == 0 {
		error('file isempty')
	}
	source := Source.new(src)
	return Compiler{
		options:      options
		source:       &source
		filesource:   path
		token_before: &TokenRef{}
		types:        default_types.clone()
	}
}

pub fn Compiler.new_from_bytes(options CompilerOptions, path string, bytes []u8) !Compiler {
	if bytes.len == 0 {
		error('file isempty')
	}
	source := Source.new(bytes)
	return Compiler{
		options:      options
		source:       &source
		filesource:   path
		token_before: &TokenRef{}
		types:        default_types.clone()
	}
}

type Return = []u8 | map[string]Chunk | string

fn (r Return) str() string {
	return match r {
		map[string]Chunk {
			r0 := r as map[string]Chunk
			r0.str()
		}
		[]u8 {
			r0 := r as []u8
			r0.str()
		}
		string {
			r0 := r as string
			r0.str()
		}
	}
}

pub fn (mut c Compiler) generate_beam() !Return {
	start := time.now()
	for !c.source.eof() {
		c.parse_next_token()!
	}
	tokenize_time := time.since(start)
	c.times['tokenize'] = tokenize_time
	if c.tokens.len > 0 {
		node := c.parse_stmt()!
		c.nodes = node
	}
	c.times['parser'] = time.since(start) - tokenize_time

	result := match c.options.returns {
		.beam_bytes {
			Return(c.beam_to_bytes()!)
		}
		.beam_chunks {
			Return(c.beam_to_chunks()!)
		}
		.beam_file {
			Return(c.beam_to_file(start)!)
		}
		.ast {
			Return(c.nodes.to_str(0))
		}
	}
	return result
}

fn (mut c0 Compiler) beam_to_file(start time.Time) !string {
	old_time := time.since(start)
	module_name := c0.get_module_name()! + '.beam'
	beam_bytes := c0.to_beam()!
	os.write_file_array('${module_name}', beam_bytes)!
	total_time := time.since(start)
	c0.times['generate_beam'] = total_time - old_time
	mut ret := '${c(.white, .default, 'generated')}: ${c(.green, .default, module_name)} in ${c(.white,
		.default, total_time.str())}\n'
	for key, value in c0.times {
		ret += '\n${key}: ${c(.white, .default, value.str())}'
	}
	return ret
}

fn (mut c Compiler) beam_to_bytes() ![]u8 {
	return c.to_beam()!
}

fn (mut c Compiler) beam_to_chunks() !map[string]Chunk {
	return c.to_chunks()!
}
