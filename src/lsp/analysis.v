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
	c := s.documents[uri]
	mut before_char_token := 0
	for tk in c.get_tokens() {
		line, character := tk.positions()
		if line == hover_params.position.line {
			if hover_params.position.character == character {
				if tk.token == .function_name {
					if doc := c.get_function_doc(tk) {
						return new_hover_result(doc)
					}
				}
			} else if before_char_token != 0 && hover_params.position.character > before_char_token
				&& hover_params.position.character < character {
				if tk.token == .function_name {
					if doc := c.get_function_doc(tk) {
						return new_hover_result(doc)
					}
				}
			} else {
				before_char_token = character
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
