module lsp

import log
import io
import strings

const logger_path = './.lxlsp.log'

fn emit_error(err_code string) Response {
	mut eres := Response{}
	eres.send_error(err_code)
	return eres
}

pub fn start(stdio bool) {
	shared state := State.new()
	mut logger := &log.Log{}
	logger.set_level(.info)
	logger.set_full_logpath(logger_path)
	logger.set_always_flush(true)
	mut srv := Server.new(logger, shared state, stdio)

	srv.register('initialize', handle_initialize)
	srv.register('initialized', handle_ignore)
	srv.register('#/setTrace', handle_set_trace)
	srv.register('textDocument/didOpen', handle_text_document_did_open)
	srv.register('textDocument/didChange', handle_text_document_did_change)
	srv.register('textDocument/hover', handle_text_document_hover)
	srv.register('textDocument/definition', handle_text_document_definition)
	srv.register('textDocument/completion', handle_text_document_completion)

	if srv.stream is SocketStream {
		mut stream0 := srv.stream as SocketStream
		for {
			stream := listen(mut stream0) or { panic("ERROR ON LISTEN ${err.msg()}")}
			spawn handle_client(srv, stream, shared state)
		}
	} else {
		handle_client(srv, srv.stream, shared state)
	}
}
fn handle_client(srv Server, stream0 io.ReaderWriter, shared state State) {
	mut stream := stream0
	mut broken := 0
	for {
		if stream0 is SocketChildStream && broken > 10{
			mut socket := stream as SocketChildStream
			client_addr := socket.conn.peer_addr() or { exit(1)}
			eprintln('> broken client: ${client_addr}')
			socket.conn.close() or {}
			break
		}
		mut buffer := strings.new_builder(1024 * 1024)
		stream.read(mut buffer) or {}
		lines := buffer.str()
		if lines.len == 0 {
			broken++
			continue
		} else {
			broken = 0
		}
		result := srv.exec(lines, shared state) or {
			err_code := err.msg()
			generated_error := emit_error(err_code)
			response_json := generated_error.gen_json() or {
				eprintln(err.msg())
				exit(1)
			}
			stream.write('Content-Length: ${response_json.len}\r\n\r\n${response_json}'.bytes()) or {}
			continue
		}
		if result.result != 'no-answer' {
			response_json := result.gen_json() or { continue }
			// srv.log.info('Reply to client')
			stream.write('Content-Length: ${response_json.len}\r\n\r\n${response_json}'.bytes()) or {}
		}
	}
}
