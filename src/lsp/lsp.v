module lsp

import log

const logger_path = './.lxlsp.log'

fn emit_error(err_code string) Response {
	mut eres := Response{}
	eres.send_error(err_code)
	return eres
}

pub fn start(stdio bool) {
	mut state := State.new()
	mut logger := &log.Log{}
	logger.set_level(.info)
	logger.set_full_logpath(logger_path)
	logger.set_always_flush(true)
	mut srv := Server.new(logger, &state, stdio)

	srv.register('initialize', handle_initialize)
	srv.register('initialized', handle_ignore)
	srv.register('#/setTrace', handle_set_trace)
	srv.register('textDocument/didOpen', handle_text_document_did_open)
	srv.register('textDocument/didChange', handle_text_document_did_change)
	srv.register('textDocument/hover', handle_text_document_hover)
	srv.register('textDocument/definition', handle_text_document_definition)
	srv.register('textDocument/completion', handle_text_document_completion)

	for {
		srv.res_buf.go_back_to(0)
		srv.stream.read(mut srv.res_buf) or { continue }
		lines := srv.res_buf.str()
		if lines.len == 0 {
			continue
		}
		result := srv.exec(lines) or {
			err_code := err.msg()
			generated_error := emit_error(err_code)
			response_json := generated_error.gen_json() or {
				srv.log.error(err.msg())
				exit(1)
			}
			srv.stream.write('Content-Length: ${response_json.len}\r\n\r\n${response_json}'.bytes()) or {}
			continue
		}
		if result.result != 'no-answer' {
			response_json := result.gen_json() or { continue }
			srv.log.info('Reply to client')
			srv.stream.write('Content-Length: ${response_json.len}\r\n\r\n${response_json}'.bytes()) or {}
		}
	}
}
