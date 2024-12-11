module lsp

import json
import log
import io
import strings

@[heap]
pub struct Server {
mut:
	req_buf strings.Builder     = strings.new_builder(4096)
	res_buf strings.Builder     = strings.new_builder(4096)
	procs   map[string]ProcFunc = map[string]ProcFunc{}
	log     log.Log
	state   &State
pub mut:
	stream io.ReaderWriter
}

pub fn Server.new(l log.Log, state &State, stdio bool) Server {
	stream := if stdio {
		io.ReaderWriter(&StdioStream{})
	} else {
		io.ReaderWriter(SocketStream.new(3625) or {
			eprintln('can´t initialize socket')
			exit(1)
		})
	}

	return Server{
		procs:  map[string]ProcFunc{}
		log:    l
		state:  state
		stream: stream
	}
}

pub fn (mut srv Server) exec(incoming string) !Response {
	vals := incoming.split_into_lines()
	if vals.len < 3 {
		return error('nothing')
	}
	content := vals[vals.len - 1]

	if incoming.len == 0 {
		internal_err := internal_error
		return error(internal_err.str())
	}
	if content in ['{}', ''] || vals.len < 2 {
		invalid_req := invalid_request
		return error(invalid_req.str())
	}
	mut req := process_request(content)
	mut res := Response{
		id: req.id
	}

	mut ctx := Context{res, req}

	if req.method in srv.procs.keys() {
		proc := srv.procs[req.method]
		res.result = proc(mut srv, mut ctx)
	} else {
		method_nf := method_not_found
		srv.log.error('method `${req.method}` not found')
		return error(method_nf.str())
	}
	return res
}

pub fn (mut srv Server) register(name string, func ProcFunc) {
	srv.procs[name] = func
}

fn process_request(js_str string) Request {
	if js_str == '{}' {
		return Request{}
	}
	req := json.decode(Request, js_str) or { return Request{} }
	return req
}

pub fn as_array(p string) []string {
	return p.find_between('[', ']').split(',')
}

pub fn as_string(p string) string {
	return p.find_between('"', '"')
}
