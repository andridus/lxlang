module compiler

import time

const c_nil = NodeEl(TokenRef{
	token: .nil
})

pub struct Compiler {
mut:
	options                    CompilerOptions
	source                     Source
	filesource                 string
	module_name                TokenRef
	moduledoc                  string
	function_doc               map[string]string
	function_attrs             map[string][]NodeEl
	binaries                   []string
	ignored_strings            []string
	integers                   []int
	floats                     []f64
	idents                     []string
	types                      []string
	types0                     map[string]NodeEl
	exports                    []string
	imports                    []Import
	aliases                    []Alias
	constants                  []Const
	attributes                 []string
	functions                  []Function
	functions_body             map[int]NodeEl
	functions_caller           []CallerFunction
	functions_caller_undefined []CallerFunction
	functions_idx              map[string]int
	tokens                     []TokenRef
	tmp_args                   []Arg
	token_before               TokenRef
	in_function                bool
	in_function_id             int
	in_function_args           bool
	inside_context             []string
	labels                     []string
	count_context              int
	count_do                   int
	ignore_token               bool
	is_next_function_return    bool
	current_position           int = -1
	current_line               int = 1
	current_token              TokenRef
	peak_token                 TokenRef
	nodes                      NodeEl = c_nil
	times                      map[string]time.Duration
}

struct Function {
	name string
mut:
	starts   int
	line     int
	ends     int
	returns  int
	location string
	args     []Arg
}

struct CallerFunction {
	name         string
	line         int
	char         int
	starts       int
	function_idx int
mut:
	module  string
	returns int
	args    []Arg
}

fn (cf CallerFunction) str() string {
	return '${cf.name}/${cf.args.len} (LOC: ${cf.line}:${cf.char})'
}

struct Import {
	token TokenRef
	args  []NodeEl
}

struct Const {
	token TokenRef
	value NodeEl
}

struct Alias {
	token TokenRef
	args  []NodeEl
}

struct Arg {
	token TokenRef
mut:
	type       int
	match_expr int // pointer to match exprs
}
