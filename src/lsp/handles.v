module lsp

import json

fn handle_initialize(srv Server, mut ctx Context, shared state State) string {
	initialized_params := json.decode(InitializeParams, ctx.req.params) or {
		// srv.log.error('failed decode json error ${err}')
		InitializeParams{}
	}
	eprintln('Connected with ${initialized_params.client_info.name}[${initialized_params.client_info.version}]')
	result := InitializeResult.new() or {
		// srv.log.error('failed decode json error ${err}')
		exit(1)
	}
	return json.encode(result)
}

fn handle_ignore(srv Server, mut ctx Context, shared state State) string {
	return 'no-answer'
}

fn handle_set_trace(srv Server, mut ctx Context, shared state State) string {
	// srv.log.info('trace ${ctx.req.params}')
	return 'no-answer'
}

fn handle_text_document_did_open(srv Server, mut ctx Context, shared state State) string {
	text_document_opened := json.decode(DidOpenTextDocumentParams, ctx.req.params) or {
		// srv.log.error('failed decode json error ${err}')
		DidOpenTextDocumentParams{}
	}
	lock state {
		state.open_document(text_document_opened.text_document.uri, text_document_opened.text_document.text)
	}
	eprintln('Opened ${text_document_opened.text_document.uri}')
	return 'no-answer'
}

fn handle_text_document_did_change(srv Server, mut ctx Context, shared state State) string {
	did_change_params := json.decode(DidChangeTextDocumentParams, ctx.req.params) or {
		// srv.log.error('failed decode json error ${err}')
		DidChangeTextDocumentParams{}
	}
	for change in did_change_params.content_changes {
		lock state {
			state.update_document(did_change_params.text_document.uri, change.text)
		}
	}
	// srv.log.info('Opened ${did_change_params.text_document.uri}')
	return 'no-answer'
}

fn handle_text_document_hover(srv Server, mut ctx Context, shared state State) string {
	hover_params := json.decode(HoverParams, ctx.req.params) or {
		// srv.log.error('failed decode json error ${err}')
		HoverParams{}
	}
	// srv.log.info('Opened ${hover_params.text_document.uri}')
	result := lock state {
		state.hover(hover_params).str()
	}
	return result
}

fn handle_text_document_definition(srv Server, mut ctx Context, shared state State) string {
	definition_params := json.decode(DefinitionParams, ctx.req.params) or {
		// srv.log.error('failed decode json error ${err}')
		DefinitionParams{}
	}
	// srv.log.info('Go to Definition ${definition_params.text_document.uri}')
	result := lock state {
		state.go_to_definition(definition_params).str()
	}
	return result
}

fn handle_text_document_completion(srv Server, mut ctx Context, shared state State) string {
	completion_params := json.decode(CompletionParams, ctx.req.params) or {
		// srv.log.error('failed decode json error ${err}')
		CompletionParams{}
	}
	// srv.log.info('Completion ${ctx.req.params} ////${completion_params}')
	result := lock state {
		state.completion(completion_params)
	}
	return result
}
