module main

import os
import compiler

fn compile_in_path(path string) map[string]compiler.Chunk {
	options := compiler.CompilerOptions{
		returns: .beam_chunks
	}
	mut c := compiler.Compiler.new(options, path) or {
		println(err.msg())
		assert false
		exit(1)
	}
	response := c.generate_beam() or {
		println(err.msg())
		assert false
		exit(1)
	}
	return response as map[string]compiler.Chunk
}

fn test_simple_function_in_module() {
	chunks := compile_in_path('${@VMODROOT}/src/tests/files/simple_function_in_module.lx')
	assert chunks['Code'].size == 70
	assert chunks['AtU8'].size == 50
	assert chunks['ImpT'].size == 28
	assert chunks['ExpT'].size == 40
	assert chunks['LocT'].size == 4
	assert chunks['StrT'].size == 0
	assert chunks['Line'].size == 21
	assert chunks['Type'].size == 10
	assert chunks['Meta'].size == 45
	assert chunks['FunT'].size == 0
	assert chunks['LitT'].size == 0
	assert chunks['Dbgi'].size == 472
	assert chunks['Docs'].size == 176
}

fn test_simple_doc_function() {
	chunks := compile_in_path('${@VMODROOT}/src/tests/files/simple_doc_function.lx')
	assert chunks['Code'].size == 70
	assert chunks['AtU8'].size == 54
	assert chunks['ImpT'].size == 28
	assert chunks['ExpT'].size == 40
	assert chunks['LocT'].size == 4
	assert chunks['StrT'].size == 0
	assert chunks['Line'].size == 21
	assert chunks['Type'].size == 10
	assert chunks['Meta'].size == 45
	assert chunks['FunT'].size == 0
	assert chunks['LitT'].size == 0
	assert chunks['Dbgi'].size == 472
	assert chunks['Docs'].size == 294
}

fn test_simple_moduledoc() {
	chunks := compile_in_path('${@VMODROOT}/src/tests/files/simple_moduledoc.lx')
	assert chunks['Code'].size == 70
	assert chunks['AtU8'].size == 60
	assert chunks['ImpT'].size == 28
	assert chunks['ExpT'].size == 40
	assert chunks['LocT'].size == 4
	assert chunks['StrT'].size == 0
	assert chunks['Line'].size == 21
	assert chunks['Type'].size == 10
	assert chunks['Meta'].size == 45
	assert chunks['FunT'].size == 0
	assert chunks['LitT'].size == 0
	assert chunks['Dbgi'].size == 472
	assert chunks['Docs'].size == 198
}

fn test_simple_spec() {
	chunks := compile_in_path('${@VMODROOT}/src/tests/files/simple_spec.lx')
	assert chunks['Code'].size == 70
	assert chunks['AtU8'].size == 63
	assert chunks['ImpT'].size == 28
	assert chunks['ExpT'].size == 40
	assert chunks['LocT'].size == 4
	assert chunks['StrT'].size == 0
	assert chunks['Line'].size == 21
	assert chunks['Type'].size == 10
	assert chunks['Meta'].size == 45
	assert chunks['FunT'].size == 0
	assert chunks['LitT'].size == 0
	assert chunks['Dbgi'].size == 476
	assert chunks['Docs'].size == 176
}

fn test_simple_doc_spec_function() {
	chunks := compile_in_path('${@VMODROOT}/src/tests/files/simple_doc_spec_function.lx')
	assert chunks['Code'].size == 70
	assert chunks['AtU8'].size == 67
	assert chunks['ImpT'].size == 28
	assert chunks['ExpT'].size == 40
	assert chunks['LocT'].size == 4
	assert chunks['StrT'].size == 0
	assert chunks['Line'].size == 21
	assert chunks['Type'].size == 10
	assert chunks['Meta'].size == 45
	assert chunks['FunT'].size == 0
	assert chunks['LitT'].size == 0
	assert chunks['Dbgi'].size == 476
	assert chunks['Docs'].size == 294
}
