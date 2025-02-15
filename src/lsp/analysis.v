module lsp

import compiler

struct State {
mut:
	documents map[string]compiler.Compiler
}

fn State.new() State {
	return State{}
}

fn (mut s State) open_document(path string, text string) {
	options := compiler.CompilerOptions{
		returns: .ast
	}
	mut c := compiler.Compiler.new_from_bytes(options, path, text.bytes()) or {
		eprintln('Do not read file ${err}')
		exit(1)
	}
	_ := c.generate_beam() or {
		eprintln('Do not compile file ${err.msg()}')
		exit(1)
	}
	s.documents[path] = c
	eprintln(s.documents.len)
}

fn (mut s State) update_document(document string, text string) {
	// s.documents[document] = text
}

fn (mut s State) hover(hover_params HoverParams) string {
	uri := hover_params.text_document.uri
	if c := s.documents[uri] {
		hover_line := hover_params.position.line + 1
		hover_pos := hover_params.position.character
		for tk in c.get_tokens() {
			line, start_pos, end_pos := tk.positions1()
			if line == hover_line {
				if hover_pos >= start_pos && hover_pos <= end_pos {
					match tk.token {
						.function_name {
							if doc := c.get_function_doc(tk) {
								if doc.len != 0 {
									return new_hover_result(doc)
								}
							}
						}
						.caller_function {
							if doc := c.get_function_doc(tk) {
								if doc.len != 0 {
									return new_hover_result(doc)
								}
							}
						}
						else {}
					}

					return new_hover_result(tk.token.str())
				}
			}
		}
	}
	return new_hover_result('')
}

fn (mut s State) go_to_definition(definition_params DefinitionParams) DefinitionResult {
	uri := definition_params.text_document.uri
	start := Position{
		line:      1
		character: 0
	}
	end := Position{
		line:      1
		character: 5
	}
	return DefinitionResult.new(uri, start, end)
}

fn (mut s State) completion(completion_params CompletionParams) string {
	items := [
		CompletionItem{
			label:         'Label Func'
			detail:        'none'
			documentation: 'One Documentation'
		},
	]
	mut result := []string{}
	for item in items {
		result << item.str()
	}
	return '[' + result.join(',') + ']'
}
