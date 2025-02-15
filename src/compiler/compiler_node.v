module compiler

interface Node0 {
	to_str() string
	get_attributes() ?NodeAttributes
	left() Node0
	right() Node0
	as_list() []Node0
	is_literal() bool
}

fn (n Node0) str() string {
	match n {
		TokenRef {
			return n.str()
		}
		Tuple2 {
			return n.str()
		}
		Tuple3 {
			return n.str()
		}
		List {
			return '[${n.items.map(|v| v.str()).join(',')}]'
		}
		else {
			return '-'
		}
	}
}

struct NodeAttributes {
	pos_line        int
	pos_char        int
	attrs           map[string]Node0
	is_should_match bool
	type_id         int
	type_match      string
}

fn (a NodeAttributes) str() string {
	return '[]'
}

struct List {
	items []Node0
}

fn List.new(nodes []Node0) Node0 {
	return List{
		items: nodes
	}
}

fn (n0 List) to_str() string {
	return 'LIST Node0'
}

fn (n0 List) get_attributes() ?NodeAttributes {
	return NodeAttributes{}
}

fn (n0 List) left() Node0 {
	if n0.items.len > 0 {
		return n0.items[0]
	} else {
		return Nil{}
	}
}

fn (n0 List) right() Node0 {
	return if n0.items.len > 0 {
		List{
			items: n0.items[1..]
		}
	} else {
		List{}
	}
}

fn (n0 List) as_list() []Node0 {
	return n0.items
}

fn (n0 List) is_literal() bool {
	return false
}

struct Nil {}

fn (n Nil) to_str() string {
	return 'nil'
}

fn (n Nil) get_attributes() ?NodeAttributes {
	return none
}

fn (n Nil) left() Node0 {
	return Nil{}
}

fn (n Nil) right() Node0 {
	return Nil{}
}

fn (n Nil) as_list() []Node0 {
	return [n]
}

fn (n Nil) is_literal() bool {
	return true
}

struct Tuple3 {
	left  Node0
	right Node0
	attrs NodeAttributes
}

fn (t Tuple3) str() string {
	return '{${t.left()}, ${t.attrs}, ${t.right()}}'
}

fn Tuple3.new_attrs(left Node0, right Node0, attrs1 NodeAttributes) Node0 {
	if attrs0 := left.get_attributes() {
		return Tuple3{
			left:  left
			right: right
			attrs: NodeAttributes{
				...attrs1
				pos_line: attrs0.pos_line
				pos_char: attrs0.pos_char
			}
		}
	} else {
		return Tuple3{
			left:  left
			right: right
			attrs: attrs1
		}
	}
}

fn Tuple3.new(left Node0, right Node0) Node0 {
	if attrs := left.get_attributes() {
		return Tuple3{
			left:  left
			right: right
			attrs: attrs
		}
	} else {
		return Tuple3{
			left:  left
			right: right
		}
	}
}

fn (t Tuple3) to_str() string {
	return '-'
}

fn (t Tuple3) get_attributes() ?NodeAttributes {
	return t.attrs
}

fn (t Tuple3) left() Node0 {
	return t.left
}

fn (t Tuple3) right() Node0 {
	return t.right
}

fn (t Tuple3) as_list() []Node0 {
	return [t.left, t.right]
}

fn (t Tuple3) is_literal() bool {
	return false
}

struct Tuple2 {
	left  Node0
	right Node0
}

fn (t Tuple2) str() string {
	return '{${t.left()}, ${t.right()}}'
}

fn Tuple2.new(left Node0, right Node0) Node0 {
	return Tuple2{
		left:  Node0(left)
		right: Node0(right)
	}
}

fn (t Tuple2) to_str() string {
	return '-'
}

fn (t Tuple2) get_attributes() ?NodeAttributes {
	return none
}

fn (t Tuple2) left() Node0 {
	return t.left
}

fn (t Tuple2) right() Node0 {
	return t.right
}

fn (t Tuple2) as_list() []Node0 {
	return [t.left, t.right]
}

fn (t Tuple2) is_literal() bool {
	return false
}

pub struct TokenRef {
pub:
	token      Token
	pos_line   int
	pos_char   int
	start_pos  int
	end_pos    int
	bin        string
	is_endline bool
pub mut:
	idx     int
	table   TableEnum
	type_id int
}

fn (tk TokenRef) to_str() string {
	return tk.token.str()
}

fn (tk TokenRef) get_attributes() ?NodeAttributes {
	return NodeAttributes{
		type_id:  tk.type_id
		pos_line: tk.pos_line
		pos_char: tk.pos_char
	}
}

fn (tk TokenRef) left() Node0 {
	return tk
}

fn (tk TokenRef) right() Node0 {
	return Nil{}
}

fn (tk TokenRef) as_list() []Node0 {
	return [tk]
}

fn (tk TokenRef) is_literal() bool {
	return tk.token in [.integer, .float, .string]
}

pub fn (t TokenRef) positions() (int, int) {
	return t.pos_line, t.pos_char
}

pub fn (t TokenRef) positions1() (int, int, int) {
	return t.pos_line, t.start_pos, t.end_pos
}

// fn (t TokenRef) to_node() Node0 {
// 	return match t.token {
// 		.module_name {
// 			NodeEl(Node{
// 				left:  TokenRef{
// 					token: .__aliases__
// 				}
// 				right: [NodeEl(t)]
// 			})
// 		}
// 		.ident, .function_name, .caller_function {
// 			NodeEl(Node{
// 				left: t
// 			})
// 		}
// 		else {
// 			NodeEl(t)
// 		}
// 	}
// }
