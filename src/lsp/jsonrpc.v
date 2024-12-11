module lsp

import strings
import net.http

const content_length = 'Content-Length: '
const jrpc_version = '2.0'
const parse_error = -32700
const invalid_request = -32600
const method_not_found = -32601
const invalid_params = -32602
const internal_error = -32693
const server_error_start = -32099
const server_error_end = -32600
const server_not_initialized = -32002
const unknown_error = -32001

type ProcFunc = fn (mut srv Server, mut ctx Context) string

pub struct Context {
pub mut:
	res Response
	req Request
}

struct Request {
mut:
	jsonrpc string = jrpc_version
	id      int
	method  string
	headers http.Header @[skip]
	params  string      @[raw]
}

pub struct Response {
	jsonrpc string = jrpc_version
mut:
	id     int
	error  ResponseError
	result string
}

struct ResponseError {
mut:
	code    int
	message string
	data    string
}

pub fn (mut res Response) send_error(err_code string) {
	res.error = ResponseError{
		code:    err_code.int()
		data:    ''
		message: err_message(err_code.int())
	}
}

pub fn err_message(err_code int) string {
	msg := match err_code {
		parse_error { 'Invalid JSON' }
		invalid_params { 'Invalid params.' }
		invalid_request { 'Invalid request.' }
		method_not_found { 'Method not found.' }
		server_error_end { 'Error while stopping the server.' }
		server_not_initialized { 'Server not yet initialized.' }
		server_error_start { 'Error while starting the server.' }
		else { 'Unknown error.' }
	}

	return msg
}

pub fn (res &Response) gen_json() !string {
	mut js := strings.new_builder(5000)
	js.write('{"jsonrpc":"${res.jsonrpc}"'.bytes())!
	js.write(',"id":${res.id}'.bytes())!
	if res.error.message.len != 0 {
		js.write(',"error":${res.error.gen_json()}'.bytes())!
	} else {
		js.write(',"result":'.bytes())!
		if res.result[0].is_digit() || res.result[0] in [`{`, `[`] {
			js.write(res.result.bytes())!
		} else {
			js.write('"${res.result}"'.bytes())!
		}
	}

	js.write('}'.bytes())!
	return js.str()
}

pub fn (err &ResponseError) gen_json() string {
	return '{"code":${err.code},"message":"${err.message}","data":"${err.data}"}'
}

pub fn (res &Response) gen_resp_text() !string {
	js := res.gen_json()!
	return 'Content-Length: ${js.len}\r\n\n${js}'
}
