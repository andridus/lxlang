module lsp

import json

fn handle_initialize(mut srv Server, mut ctx Context) string {
	initialized_params := json.decode(InitializeParams, ctx.req.params) or {
		srv.log.error('failed decode json error ${err}')
		InitializeParams{}
	}
	srv.log.info('Connected with ${initialized_params.client_info.name}[${initialized_params.client_info.version}]')
	result := InitializeResult.new() or {
		srv.log.error('failed decode json error ${err}')
		exit(1)
	}
	return json.encode(result)
}

fn handle_ignore(mut srv Server, mut ctx Context) string {
	return 'no-answer'
}

fn handle_set_trace(mut srv Server, mut ctx Context) string {
	srv.log.info('trace ${ctx.req.params}')
	return 'no-answer'
}

fn handle_text_document_did_open(mut srv Server, mut ctx Context) string {
	text_document_opened := json.decode(DidOpenTextDocumentParams, ctx.req.params) or {
		srv.log.error('failed decode json error ${err}')
		DidOpenTextDocumentParams{}
	}
	srv.state.open_document(text_document_opened.text_document.uri, text_document_opened.text_document.text)
	srv.log.info('Opened ${text_document_opened.text_document.uri}')
	return 'no-answer'
}

fn handle_text_document_did_change(mut srv Server, mut ctx Context) string {
	did_change_params := json.decode(DidChangeTextDocumentParams, ctx.req.params) or {
		srv.log.error('failed decode json error ${err}')
		DidChangeTextDocumentParams{}
	}
	for change in did_change_params.content_changes {
		srv.state.update_document(did_change_params.text_document.uri, change.text)
	}
	srv.log.info('Opened ${did_change_params.text_document.uri}')
	return 'no-answer'
}

fn handle_text_document_hover(mut srv Server, mut ctx Context) string {
	hover_params := json.decode(HoverParams, ctx.req.params) or {
		srv.log.error('failed decode json error ${err}')
		HoverParams{}
	}
	srv.log.info('Opened ${hover_params.text_document.uri}')
	return srv.state.hover(hover_params).str()
}

fn handle_text_document_definition(mut srv Server, mut ctx Context) string {
	definition_params := json.decode(DefinitionParams, ctx.req.params) or {
		srv.log.error('failed decode json error ${err}')
		DefinitionParams{}
	}
	srv.log.info('Go to Definition ${definition_params.text_document.uri}')
	return srv.state.go_to_definition(definition_params).str()
}

fn handle_text_document_completion(mut srv Server, mut ctx Context) string {
	completion_params := json.decode(CompletionParams, ctx.req.params) or {
		srv.log.error('failed decode json error ${err}')
		CompletionParams{}
	}
	srv.log.info('Completion ${ctx.req.params} ////${completion_params}')
	return srv.state.completion(completion_params)
}
