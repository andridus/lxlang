module compiler

type NodeEl = TokenRef | Node | []NodeEl | Keyword


fn (n NodeEl) str() string {
	return match n {
		TokenRef {
			n.token.str()
		}
		Node {
			return '{${n.left.str()}, ${n.right.str()}}'
		}
		[]NodeEl {
			'[${n.map(|a| a.str()).join(', ')}]'
		}
		Keyword {
			'${n.key}: ${n.value}'
		}
	}

}
struct Keyword {
	key   NodeEl
	value NodeEl
}

struct Node {
	left       NodeEl = c_nil
	right      NodeEl = c_nil
	attributes []string
}

struct TokenRef {
	token    Token
	idx      int
	table    TableEnum
	pos_line int
	pos_char int
}

fn (t TokenRef) to_node() NodeEl {
	return match t.token {
		.module_name {
			NodeEl(Node{
				left:  TokenRef{
					token: .__aliases__
				}
				right: [NodeEl(t)]
			})
		}
		.ident, .function_name, .caller_function {
			NodeEl(Node{
				left: t
			})
		}
		else {
			NodeEl(t)
		}
	}
}
