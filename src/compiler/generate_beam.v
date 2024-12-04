// import compress.zlib
module compiler

import crypto.md5
import math.big
import encoding.binary
import erl

const compile_version = '8.5.2'

struct Beam {
mut:
	highest_opcode u8
	module_name    string
	current_label  int
	labels         []int
	lines          [][]int
	lines_str      map[int]string
	num_lines      int
	attributes     []int
	exports        [][]int
	locals         [][]int
	functions      []BeamFunction
	imports        [][]int
	types          []u8
	code           []u8
}

struct Chunk {
	tag     string
	size    u32
	data    []u8
	padding []u8
}

struct BeamFunction {
	arity int
	name  string
mut:
	labels int
	body   map[int][]BeamInstruction
}

type Term = int | string | []Term | Tuple | TupleId | TokenRef

fn (t Term) to_bytes(mut b Beam) []u8 {
	match t {
		TokenRef {
			a := encode_int(Tag.tag_a, t.idx)
			return a
		}
		TupleId {
			match t.id {
				.atom {
					return t.terms[0].to_bytes(mut b)
				}
				.x {
					return encode_int(Tag.tag_x, t.terms[0] as int)
				}
				.integer {
					return encode_int(Tag.tag_i, t.terms[0] as int)
				}
				.extfunc {
					idx := b.put_import(t.terms)
					return encode_int(Tag.tag_u, idx)
				}
				else {}
			}
		}
		Tuple {}
		[]Term {}
		string {}
		int {
			return encode_int(Tag.tag_u, t)
		}
	}
	println('missing: ${t}')
	return []u8{}
}

fn (mut c Compiler) atom(str string) Term {
	mut idx := c.idents.len
	idx0 := c.idents.index(str)
	if idx0 != -1 {
		idx = idx0
	} else {
		idx = c.idents.len
		c.idents << str
	}
	tk := TokenRef{
		idx:   idx + 1
		table: .idents
		token: .ident
	}
	return Term(tk)
}

fn tid(id Identifier, terms []Term) Term {
	return TupleId{
		id:    id
		terms: terms
	}
}

struct TupleId {
	id    Identifier
	terms []Term
}

struct Tuple {
	terms []Term
}

struct BeamInstruction {
	inst Opcode
mut:
	terms []Term
}

fn (mut c Compiler) to_generate() !Beam {
	mut beam := Beam{}
	beam.put_type('any')
	beam.put_module(mut c)
	beam.put_functions(mut c)
	beam.put_exports(mut c)
	beam.put_code(mut c)!
	beam.put_end_code()!
	return beam
}

fn (mut b Beam) put_type(typ string) {
	b.types << u8(15)
	b.types << u8(255)
}

// fn mapping_types() map[string]u32 {
// 	a := map[string]u32{}
// 	return a
// }
fn (mut b Beam) put_import(terms []Term) int {
	idx := b.imports.len
	mut imp := []int{}
	a1 := terms[0] as TokenRef
	b1 := terms[1] as TokenRef
	c1 := terms[2] as int
	imp << int(a1.idx)
	imp << int(b1.idx)
	imp << c1
	b.imports << [imp]
	return idx
}

fn (mut b Beam) put_line(terms []Term) int {
	if terms.len > 0 {
		idx := b.lines.len
		if terms[0] is Tuple {
			t := terms[0] as Tuple
			if t.terms[0] == Term('location') {
				file := t.terms[1] as string
				lin := t.terms[2] as int
				b.lines << [idx, lin]
				b.lines_str[idx] = file
			}
		}
		b.num_lines = idx + 1
		return b.num_lines
	} else {
		b.num_lines += 1
		return 0
	}
}

fn (mut b Beam) put_module(mut c Compiler) {
	if module_name := c.get_ident_value(c.module_name) {
		b.module_name = module_name
	}
}

fn (mut b Beam) put_exports(mut c Compiler) {
	for f in b.functions.reverse() {
		mut exp := []int{}
		exp << c.idents.index(f.name) + 1
		exp << f.arity
		exp << f.labels
		b.exports << [exp]
	}
}

fn (mut b Beam) put_code(mut c Compiler) ! {
	for f in b.functions {
		for label, ins in f.body {
			b.code << 1 // OPCODE: label
			b.code << encode_int(Tag.tag_u, label)
			for instr in ins {
				mut args := []Term{}
				match instr.inst {
					.line {
						idx := b.put_line(instr.terms)
						args = [Term(idx)]
					}
					else {
						args = instr.terms.clone()
					}
				}
				current_opcode := u8(instr.inst)
				if b.highest_opcode < current_opcode {
					b.highest_opcode = current_opcode
				}
				b.code << b.encode_op(current_opcode, args)
			}
		}
	}
}

fn (mut b Beam) put_end_code() ! {
	b.code << 3 // OPCODE: int_code_end
}

fn (mut b Beam) encode_op(op u8, args []Term) []u8 {
	mut a := []u8{}
	a << op
	for term in args {
		a << term.to_bytes(mut b)
	}
	return a
}

fn encode_int(tag Tag, val int) []u8 {
	if val < 0 {
		// encode negative bytes
		return []
	} else if val < 16 {
		return [u8(u32(val) << 4 | int(tag))]
	} else if val < 2048 {
		mut c := []u8{}
		c << [u8(((val >> 3) & 0b11100000) | int(tag) | 0b00001000)]
		c << u8(val & 0xff)
		return c
	} else {
		return binary.big_endian_get_u32(u32(val))
	}
}

fn (mut b Beam) put_functions(mut c Compiler) {
	for idx, function in c.functions {
		mut beam_function := BeamFunction{
			arity: function.args.len
			name:  function.name
		}
		if body := c.functions_body[idx] {
			b.current_label++
			beam_function.body[b.current_label] = c.function_info(b, function)
			b.current_label++
			beam_function.body[b.current_label] = c.function_body(body)
		}
		beam_function.labels = b.current_label
		b.functions << beam_function
	}
	b.current_label++
	mut module_info_0 := BeamFunction{
		arity: 0
		name:  'module_info'
	}
	module_info_0.body = c.add_module_info_0(mut b)
	module_info_0.labels = b.current_label
	b.functions << module_info_0
	b.current_label++
	mut module_info_1 := BeamFunction{
		arity: 1
		name:  'module_info'
	}
	module_info_1.body = c.add_module_info_1(mut b)
	module_info_1.labels = b.current_label
	b.functions << module_info_1
	b.current_label++
}

fn (mut c Compiler) add_module_info_0(mut b Beam) map[int][]BeamInstruction {
	mut beam_instructions := map[int][]BeamInstruction{}
	line := BeamInstruction{
		inst:  .line
		terms: []
	}
	mut module_info := BeamInstruction{
		inst: .func_info
	}
	module_info.terms << tid(.atom, [c.atom(b.module_name)])
	module_info.terms << tid(.atom, [c.atom('module_info')])
	module_info.terms << Term(0)
	beam_instructions[b.current_label] = [line, module_info]

	b.current_label++

	mut move := BeamInstruction{
		inst: .move
	}
	move.terms << tid(.atom, [c.atom(b.module_name)])
	move.terms << tid(.x, [Term(0)])

	mut call_ext_only := BeamInstruction{
		inst: .call_ext_only
	}
	call_ext_only.terms << Term(1)
	call_ext_only.terms << tid(.extfunc, [c.atom('erlang'), c.atom('get_module_info'),
		Term(1)])

	beam_instructions[b.current_label] = [move, call_ext_only]
	return beam_instructions
}

fn (mut c Compiler) add_module_info_1(mut b Beam) map[int][]BeamInstruction {
	mut beam_instructions := map[int][]BeamInstruction{}
	line := BeamInstruction{
		inst:  .line
		terms: []
	}
	mut module_info := BeamInstruction{
		inst: .func_info
	}
	module_info.terms << tid(.atom, [c.atom(b.module_name)])
	module_info.terms << tid(.atom, [c.atom('module_info')])
	module_info.terms << Term(1)
	beam_instructions[b.current_label] = [line, module_info]

	b.current_label++

	mut move0 := BeamInstruction{
		inst: .move
	}
	move0.terms << tid(.x, [Term(0)])
	move0.terms << tid(.x, [Term(1)])

	mut move1 := BeamInstruction{
		inst: .move
	}
	move1.terms << tid(.atom, [c.atom(b.module_name)])
	move1.terms << tid(.x, [Term(0)])

	mut call_ext_only := BeamInstruction{
		inst: .call_ext_only
	}
	call_ext_only.terms << Term(2)
	call_ext_only.terms << tid(.extfunc, [c.atom('erlang'), c.atom('get_module_info'),
		Term(2)])

	beam_instructions[b.current_label] = [move0, move1, call_ext_only]
	return beam_instructions
}

fn (mut c Compiler) function_info(b &Beam, func Function) []BeamInstruction {
	location := Tuple{[Term('location'), Term(c.filesource), Term(4)]}
	line := BeamInstruction{
		inst:  .line
		terms: [location]
	}

	mut func_info := BeamInstruction{
		inst: .func_info
	}
	func_info.terms << tid(.atom, [c.atom(b.module_name)])
	func_info.terms << tid(.atom, [c.atom(func.name)])
	func_info.terms << Term(func.args.len)

	return [line, func_info]
}

fn (mut c Compiler) function_body(func_node NodeEl) []BeamInstruction {
	mut instructions := []BeamInstruction{}
	match func_node {
		[]NodeEl {
			for node in func_node {
				instructions << c.function_body(node)
			}
		}
		TokenRef {
			match func_node.table {
				.none {}
				.atoms {}
				.binary {}
				.idents {}
				.ignored_strings {}
				.integers {
					if integer_value := c.get_integer_value(func_node) {
						mut move := BeamInstruction{
							inst: .move
						}
						move.terms << tid(.integer, [Term(integer_value)])
						move.terms << tid(.x, [Term(0)])
						return [move]
					}
				}
				.bigints {}
				.floats {}
				.consts {}
				.modules {}
				.functions {}
			}
		}
		Keyword {}
		Node {}
	}
	instructions << BeamInstruction{
		inst: .return
	}
	return instructions
}

struct CompileInfo {
	source     string
	options    []string
	attributes []string
}

fn (mut c Compiler) to_beam() ![]u8 {
	compile_info := CompileInfo{
		source: 'test.lx'
	}
	beam := c.to_generate()!
	// base otp 22
	mut chunks := map[string]Chunk{}
	chunks['Code'] = beam.build_code_chunk() // Code
	chunks['AtU8'] = beam.build_atom_chunk(c) // AtU8
	chunks['ImpT'] = beam.build_imp_chunk() // ImpT
	chunks['ExpT'] = beam.build_exp_chunk() // ExpT
	chunks['LocT'] = beam.build_loc_chunk() // LocT
	chunks['StrT'] = beam.build_str_chunk(c) // StrT
	chunks['Line'] = beam.build_line_chunk() // Line
	chunks['Type'] = beam.build_type_chunk() // Type
	chunks['Meta'] = beam.build_meta_chunk()! // Meta
	chunks['FunT'] = beam.build_lambda_chunk() // FunT
	chunks['LitT'] = beam.build_literal_chunk() // LitT
	chunks['Dbgi'] = beam.build_dbgi_chunk(c)! // Dbgi
	chunks['Docs'] = beam.build_docs_chunk(c)! // Docs
	// chunks['ExCk'] = beam.build_dbgi_chunk()! // Dbgi
	mut essentials := []u8{}
	mut chunks0 := []u8{}
	essential_tags := ['AtU8', 'Code', 'StrT', 'ImpT', 'ExpT', 'FunT', 'LitT', 'Meta']
	for tag in essential_tags {
		if chunk := chunks[tag] {
			if chunk.size == 0 && tag in ['FunT', 'LitT', 'Meta'] {
				continue
			}
			chunks0 << chunk.tag.bytes()
			chunks0 << binary.big_endian_get_u32(chunk.size)
			chunks0 << chunk.data
			chunks0 << chunk.padding
			essentials << chunk.data
		}
	}
	digest := md5.sum(essentials)
	// finalize fun_table -- empty now
	chunks['Attr'] = beam.build_attr_chunk(digest)! // Attr
	chunks['CInf'] = beam.build_compile_info_chunk(compile_info)! // CInf

	plus_tags := ['LocT', 'Attr', 'CInf', 'Dbgi', 'Docs', 'Line', 'Type']
	for tag in plus_tags {
		if chunk := chunks[tag] {
			chunks0 << chunk.tag.bytes()
			chunks0 << binary.big_endian_get_u32(chunk.size)
			chunks0 << chunk.data
			chunks0 << chunk.padding
		}
	}
	if chunks0.len % 4 == 0 {
		mut chunks1 := []u8{}
		chunks1 << 'FOR1'.bytes()
		chunks1 << binary.big_endian_get_u32(u32(chunks0.len + 4))
		chunks1 << 'BEAM'.bytes()
		chunks1 << chunks0
		return chunks1
	} else {
		return error('incorrect padding')
	}
}

fn pad(num int) []u8 {
	value := num % 4
	return if value == 0 {
		[]u8{}
	} else {
		[u8(0)].repeat(4 - value)
	}
}

fn (b Beam) build_code_chunk() Chunk {
	format_number := u32(0)
	highest_opcode := u32(171)
	num_labels := u32(b.current_label)
	num_functions := u32(b.functions.len)
	mut content := []u8{}
	content << binary.big_endian_get_u32(u32(16))
	content << binary.big_endian_get_u32(format_number)
	content << binary.big_endian_get_u32(highest_opcode)
	content << binary.big_endian_get_u32(num_labels)
	content << binary.big_endian_get_u32(num_functions)
	content << b.code
	return Chunk{
		tag:     'Code'
		size:    u32(content.len)
		data:    content
		padding: pad(content.len)
	}
}

fn (b Beam) build_atom_chunk(c &Compiler) Chunk {
	num_atoms := binary.big_endian_get_u32(u32(c.idents.len))
	mut atom_table := []u8{}
	for i in c.idents {
		// max length for atom is 255
		atom_table << u8(i.len)
		atom_table << i.bytes()
	}
	size := num_atoms.len + atom_table.len
	mut content := []u8{}
	content << num_atoms
	content << atom_table
	return Chunk{
		tag:     'AtU8'
		size:    u32(size)
		data:    content
		padding: pad(size)
	}
}

fn (b Beam) build_imp_chunk() Chunk {
	num_imports := binary.big_endian_get_u32(u32(b.imports.len))
	mut imports_table := []u8{}
	for imp_fun in b.imports {
		for x in imp_fun {
			imports_table << binary.big_endian_get_u32(u32(x))
		}
	}
	size := num_imports.len + imports_table.len
	mut content := []u8{}
	content << num_imports
	content << imports_table
	return Chunk{
		tag:     'ImpT'
		size:    u32(size)
		data:    content
		padding: pad(size)
	}
}

fn (b Beam) build_exp_chunk() Chunk {
	num_exports := binary.big_endian_get_u32(u32(b.exports.len))
	mut exports_table := []u8{}
	for exp_fun in b.exports {
		for x in exp_fun {
			exports_table << binary.big_endian_get_u32(u32(x))
		}
	}
	size := num_exports.len + exports_table.len
	mut content := []u8{}
	content << num_exports
	content << exports_table
	return Chunk{
		tag:     'ExpT'
		size:    u32(size)
		data:    content
		padding: pad(size)
	}
}

fn (b Beam) build_loc_chunk() Chunk {
	num_locals := binary.big_endian_get_u32(u32(b.locals.len))
	mut locals_table := []u8{}
	for loc_fun in b.locals {
		for x in loc_fun {
			locals_table << binary.big_endian_get_u32(u32(x))
		}
	}
	size := num_locals.len + locals_table.len
	mut content := []u8{}
	content << num_locals
	content << locals_table
	return Chunk{
		tag:     'LocT'
		size:    u32(size)
		data:    content
		padding: pad(size)
	}
}

fn (b Beam) build_str_chunk(c &Compiler) Chunk {
	num_string := u32(c.binaries.len)
	mut str_table := []u8{}
	for i in c.binaries {
		str_table << u8(i.len)
		str_table << i.bytes()
	}
	size := num_string + str_table.len
	mut content := []u8{}
	if size > 0 {
		content << binary.big_endian_get_u32(num_string)
		content << str_table
	}
	return Chunk{
		tag:     'StrT'
		size:    u32(size)
		data:    content
		padding: pad(size)
	}
}

fn (b Beam) build_lambda_chunk() Chunk {
	return Chunk{
		tag:     'FunT'
		size:    u32(0)
		data:    []
		padding: pad(0)
	}
}

fn (b Beam) build_literal_chunk() Chunk {
	return Chunk{
		tag:     'LitT'
		size:    u32(0)
		data:    []
		padding: pad(0)
	}
}

fn (b Beam) build_line_chunk() Chunk {
	ver := u32(0)
	mut lines := []u8{}
	for i, l in b.lines {
		if i == 0 {
			lines << encode_int(Tag.tag_i, l[1])
		} else {
			lines << encode_int(Tag.tag_a, l[0])
			lines << encode_int(Tag.tag_i, l[1])
		}
	}
	fnames := []u8{}
	num_lines_instr := u32(b.num_lines)
	num_lines := u32(b.lines.len)
	num_fnames := u32(fnames.len)
	mut content := []u8{}
	content << binary.big_endian_get_u32(ver)
	content << binary.big_endian_get_u32(line_bits(false))
	content << binary.big_endian_get_u32(num_lines_instr)
	content << binary.big_endian_get_u32(num_lines)
	content << binary.big_endian_get_u32(num_fnames)
	content << lines
	content << fnames
	return Chunk{
		tag:     'Line'
		size:    u32(content.len)
		data:    content
		padding: pad(content.len)
	}
}

fn line_bits(exec_line bool) u32 {
	return u32(0)
}

fn (b Beam) build_type_chunk() Chunk {
	version := u32(3)
	mut content := []u8{}
	content << binary.big_endian_get_u32(version)
	content << binary.big_endian_get_u32(u32(b.types.len / 2))
	content << b.types
	return Chunk{
		tag:     'Type'
		size:    u32(content.len)
		data:    content
		padding: pad(content.len)
	}
}

enum Features {
	maybe_expr
}

fn (b Beam) build_meta_chunk() !Chunk {
	content := erl.List.new([
		erl.Tuple.new([
			erl.Atom.new('enabled_features'),
			erl.List.new([
				erl.Atom.new('maybe_expr'),
			]),
		]),
	]).bytes(false)!

	return Chunk{
		tag:     'Meta'
		size:    u32(content.len)
		data:    content
		padding: pad(content.len)
	}
}

fn (b Beam) build_attr_chunk(digest []u8) !Chunk {
	version := big.integer_from_bytes(digest)
	content := erl.List.new([
		erl.Tuple.new([
			erl.Atom.new('vsn'),
			erl.List.new([
				erl.Term(version),
			]),
		]),
	]).bytes(false)!

	return Chunk{
		tag:     'Attr'
		size:    u32(content.len)
		data:    content
		padding: pad(content.len)
	}
}

fn (b Beam) build_compile_info_chunk(compile_info CompileInfo) !Chunk {
	content := erl.List.new([
		erl.Tuple.new([
			erl.Atom.new('version'),
			erl.Term(compile_version),
		]),
		erl.Tuple.new([
			erl.Atom.new('options'),
			erl.List.new([]),
		]),
		erl.Tuple.new([
			erl.Atom.new('source'),
			erl.Term('/home/helder/otp/A.erl'),
		]),
	]).bytes(false)!

	return Chunk{
		tag:     'CInf'
		size:    u32(content.len)
		data:    content
		padding: pad(content.len)
	}
}

fn (b Beam) build_dbgi_chunk(c Compiler) !Chunk {
	mut functions_type := []erl.Term{}
	for func in c.functions {
		if type0 := c.types[func.returns] {
			functions_type << erl.Tuple.new([
				erl.Atom.new('attribute'),
				erl.Term(7),
				erl.Atom.new('spec'),
				erl.Tuple.new([
					erl.Tuple.new([erl.Atom.new(func.name), erl.Term(0)]),
					erl.List.new([
						erl.Tuple.new([
							erl.Atom.new('type'),
							erl.Tuple.new([erl.Term(7), erl.Term(9)]),
							erl.Atom.new('fun'),
							erl.List.new([
								erl.Tuple.new([
									erl.Atom.new('type'),
									erl.Tuple.new([erl.Term(7), erl.Term(9)]),
									erl.Atom.new('product'),
									erl.List.new([]),
								]),
								erl.Tuple.new([
									erl.Atom.new('type'),
									erl.Tuple.new([erl.Term(7), erl.Term(16)]),
									erl.Atom.new(type0),
									erl.List.new([]),
								]),
							]),
						]),
					]),
				]),
			])
		}
	}
	content := erl.Tuple.new([
		erl.Atom.new('debug_info_v1'),
		erl.Atom.new('elixir_erl'),
		erl.Tuple.new([
			erl.Atom.new('elixir_v1'),
			erl.Map.new({
				'attributes':        erl.List.new([])
				'module':            erl.Binary.new('A')
				'file':              erl.Binary.new('/home/helder/data/data/projs/elixir/a.ex')
				'deprecated':        erl.List.new([])
				'unreachable':       erl.List.new([])
				'anno':              erl.Tuple.new([erl.Term(1), erl.Term(1)])
				'struct':            erl.Nil.new()
				'after_verify':      erl.List.new([])
				'definitions':       erl.List.new([])
				'compile_opts':      erl.List.new([])
				'defines_behaviour': erl.Atom.new('false')
				'signatures':        erl.Nil.new() // to fix
				'impls':             erl.List.new([])
				'relative_file':     erl.Binary.new('a.ex') // to fix
			}),
			erl.List.new(functions_type),
		]),
	]).bytes(false)!

	return Chunk{
		tag:     'Dbgi'
		size:    u32(content.len)
		data:    content
		padding: pad(content.len)
	}
}

fn (b Beam) build_docs_chunk(c Compiler) !Chunk {
	line := 2
	module_doc := erl.Map.new({
		'en': erl.Binary.new(c.moduledoc)
	})

	module_meta := erl.Map.new({
		'behaviours':   erl.List.new([])
		'source_annos': erl.List.new([erl.Tuple.new([erl.Term(1), erl.Term(1)])])
		'source_path':  erl.Term('/home/helder/data/data/projs/elixir/a.ex')
	})

	mut functions_doc := []erl.Term{}
	for name, doc in c.function_doc {
		functions_doc << erl.Tuple.new([
			erl.Tuple.new([
				erl.Atom.new('function'),
				erl.Atom.new(name),
				erl.Term(0),
			]),
			erl.Term(4),
			erl.List.new([
				erl.Binary.new('${name}()'),
			]),
			erl.Map.new({
				'en': erl.Binary.new(doc)
			}),
			erl.Map.new({
				'source_annos': erl.List.new([
					erl.Tuple.new([erl.Term(8), erl.Term(7)]),
				])
			}),
		])
	}
	content := erl.Tuple.new([
		erl.Atom.new('docs_v1'),
		erl.Term(line),
		erl.Atom.new('elixir'),
		erl.Binary.new('text/markdown'),
		module_doc,
		module_meta,
		erl.List.new(functions_doc),
	]).bytes(false)!

	return Chunk{
		tag:     'Docs'
		size:    u32(content.len)
		data:    content
		padding: pad(content.len)
	}
}

fn (b Beam) compact_term_encoding() []u8 {
	//           	| 0 0 0 - Literal
	//           	| 0 0 1 - Integer
	//           	| 0 1 0 - Atom
	// 			 			| 0 1 1 - X Register
	// 			 			| 1 0 0 - Y Register
	// 			 			| 1 0 1 - label
	// 			 			| 1 1 0 - Character
	// 	0 0 0 1 0 | 1 1 1 — Extended — Float
	// 	0 0 1 0 0 | 1 1 1 — Extended — List
	// 	0 0 1 1 0 | 1 1 1 — Extended — Floating point register
	// 	0 1 0 0 0 | 1 1 1 — Extended — Allocation list
	// 	0 1 0 1 0 | 1 1 1 — Extended — Literal

	return []u8{}
}
