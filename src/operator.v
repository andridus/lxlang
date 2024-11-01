enum Operator {
	none
	arroba             // @
	dot                // .
	plus               // +
	minus              // -
	exclamation        // !
	div                // /
	less_than          // <
	greater_than       // >
	equals             // =
	ampersand          // &
	pipe               // |
	caret              // ^
	neg_equals         // !=
	equals_tilde       // =~
	less_greater       // <>
	pipe_right         // |>
	less_tilde         // <~
	tilde_greater      // ~>
	less_or_equals     // <=
	greater_or_equals  // >=
	arrow_left         // ->
	arrow_right        // <-
	d_arrow_right      // =>
	default            // \\
	double_plus        // ++
	double_minus       // --
	double_dot         // ..
	double_equals      // ==
	double_pipe        // ||
	triple_tilde       // ~~~
	triple_plus        // +++
	triple_minus       // ---
	triple_less        // <<<
	triple_greater     // >>>
	triple_equals      // ===
	triple_pipe        // |||
	triple_ampersand   // &&&
	neg_double_equals  // ≃=
	double_less_neg    // <<~
	neg_double_greater // ~>>
	less_tilde_greater // <~>
	less_pipe_greater  // <|>
	in                 // in
	or                 // or
	not                // not
	and                // and
	when               // when
}

fn operator_from_string(s string) Operator {
	return match s {
		'@' { .arroba }
		'.' { .dot }
		'+' { .plus }
		'-' { .minus }
		'!' { .exclamation }
		'/' { .div }
		'<' { .less_than }
		'>' { .greater_than }
		'=' { .equals }
		'&' { .ampersand }
		'|' { .pipe }
		'^' { .caret }
		'!=' { .neg_equals }
		'=~' { .equals_tilde }
		'<>' { .less_greater }
		'|>' { .pipe_right }
		'<~' { .less_tilde }
		'~>' { .tilde_greater }
		'<=' { .less_or_equals }
		'>=' { .greater_or_equals }
		'->' { .arrow_left }
		'<-' { .arrow_right }
		'=>' { .d_arrow_right }
		'\\' { .default }
		'in' { .in }
		'or' { .or }
		'not' { .not }
		'and' { .and }
		'when' { .when }
		'++' { .double_plus }
		'--' { .double_minus }
		'..' { .double_dot }
		'==' { .double_equals }
		'||' { .double_pipe }
		'~~~' { .triple_tilde }
		'+++' { .triple_plus }
		'---' { .triple_minus }
		'<<<' { .triple_less }
		'>>>' { .triple_greater }
		'===' { .triple_equals }
		'|||' { .triple_pipe }
		'&&&' { .triple_ampersand }
		'≃=' { .neg_double_equals }
		'<<~' { .double_less_neg }
		'~>>' { .neg_double_greater }
		'<~>' { .less_tilde_greater }
		'<|>' { .less_pipe_greater }
		else { .none }
	}
}

const keywords = ['defmodule', 'def', 'defp', 'end', 'do', 'defmacro', 'defmacrop']
const operators_1 = [`@`, `.`, `+`, `-`, `!`, `/`, `<`, `>`, `=`, `&`, `|`, `^`]
const operators_2 = [
	[`+`, `+`],
	[`-`, `-`],
	[`.`, `.`],
	[`<`, `>`],
	[`i`, `n`],
	[`|`, `>`],
	[`<`, `~`],
	[`~`, `>`],
	[`<`, `=`],
	[`>`, `=`],
	[`=`, `=`],
	[`!`, `=`],
	[`=`, `~`],
	[`|`, `|`],
	[`=`, `>`],
	[`<`, `-`],
	[`\\`, `\\`],
]
const operators_3 = [
	[`n`, `o`, `t`],
	[`~`, `~`, `~`],
	[`+`, `+`, `+`],
	[`-`, `-`, `-`],
	[`<`, `<`, `<`],
	[`>`, `>`, `>`],
	[`<`, `<`, `~`],
	[`~`, `>`, `>`],
	[`<`, `~`, `>`],
	[`<`, `|`, `>`],
	[`=`, `=`, `=`],
	[`!`, `=`, `=`],
	[`&`, `&`, `&`],
	[`|`, `|`, `|`],
]
const operators_str = ['when', 'and', 'or', 'in', 'not']
