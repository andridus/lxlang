fn (t TokenRef) str() string {
	if t.table != .none {
		return '${t.token.str()}:${c(.white, .default, t.idx.str())}'
	} else {
		return '${t.token.str()}'
	}
}

fn (t Token) str() string {
	return match t {
		.nil { '${c(.dark_gray, .default, 'nil')}' }
		.eof { 'EOF' }
		.ident { '${c(.white, .default, 'ident')}' }
		.string { '${c(.green, .default, 'string')}' }
		.lcbr { '${c(.white, .default, 'lcbr')}' }
		.rcbr { '${c(.white, .default, 'rcbr')}' }
		.lpar { '${c(.white, .default, 'lpar')}' }
		.rpar { '${c(.white, .default, 'rpar')}' }
		.lsbr { '${c(.white, .default, 'lsbr')}' }
		.rsbr { '${c(.white, .default, 'rsbr')}' }
		.comma { '${c(.white, .default, 'comma')}' }
		.arroba { '${c(.red, .default, '@')}' }
		.typespec { '${c(.red, .default, 'typespec')}' }
		.colon { '${c(.red, .default, 'colon')}' }
		.module_name { '${c(.red, .default, 'module_name')}' }
		.integer { '${c(.orange, .default, 'integer')}' }
		.float { '${c(.orange, .default, 'float')}' }
		.do { '${c(.cyan, .default, 'do')}' }
		.end { '${c(.cyan, .default, 'end')}' }
		.defmodule { '${c(.cyan, .default, 'defmodule')}' }
		.def { '${c(.cyan, .default, 'def')}' }
		.defp { '${c(.cyan, .default, 'defp')}' }
		.defmacro { '${c(.cyan, .default, 'defmacro')}' }
		.defmacrop { '${c(.cyan, .default, 'defmacrop')}' }
		.operator { '${c(.cyan, .default, 'operator')}' }
		.function_name { '${c(.cyan, .default, 'function_name')}' }
		.caller_function { '${c(.cyan, .default, 'caller_function')}' }
		.__aliases__ { '${c(.cyan, .default, '__aliases__')}' }
		.__block__ { '${c(.cyan, .default, '__block__')}' }
	}
}

pub enum Color {
	black      = 30
	dark_red
	dark_green
	dark_yellow
	dark_blue
	dark_magenta
	dark_cyan
	default    = 39
	light_gray = 37
	dark_gray  = 90
	red
	green
	orange
	blue
	magenta
	cyan
	white
}

pub enum Decoration {
	default   = 0
	bold
	light
	underline = 4
	blinking
}

pub const prefix = '\033['
pub const suffix = 'm'
pub const reset = '\033[0m'

pub fn c(c Color, decor Decoration, text string) string {
	return '${prefix}${int(decor)}${suffix}${prefix}${int(c)}${suffix}${text}${reset}'
}

fn (n NodeEl) to_str(idx int) string {
	mut idx1 := idx + 1
	return match n {
		TokenRef {
			n.to_str(idx1)
		}
		Node {
			n.to_str(idx1)
		}
		Keyword {
			'${n.key.to_str(idx1)}: ${n.value.to_str(idx1)}'
		}
		[]NodeEl {
			'[${n.map(it.to_str(idx)).join(', ')}]'
		}
	}
}

fn (n Node) to_str(idx int) string {
	space := ' '.repeat(idx)
	mut broken := ''
	if n.right !is TokenRef {
		broken = '\n${space}'
	}
	right := n.right.to_str(idx).replace('}]', '}\n ${space}]')
	return '${broken}{${n.left.to_str(idx)}, ${n.attributes}, ${right}}}'
}

fn (t TokenRef) to_str(idx int) string {
	return t.str()
}
