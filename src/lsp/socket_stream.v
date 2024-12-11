module lsp

import io
import net

struct SocketStream {
	log_label string = 'lxls-server'
	log       bool   = true
mut:
	conn   &net.TcpConn       = &net.TcpConn(net.listen_tcp(.ip, '80')!)
	reader &io.BufferedReader = unsafe { nil }
pub mut:
	port  int = 5007
	debug bool
}

fn SocketStream.new(port int) !&SocketStream {
	mut listener := net.listen_tcp(.ip, ':${port}')!
	laddr := listener.addr()!
	eprintln('Lx - Elixir Language Server, listen on ${laddr} ...')
	mut conn := listener.accept() or {
		listener.close() or {}
		return err
	}

	mut reader := io.new_buffered_reader(reader: conn, cap: 1024 * 1024)
	conn.set_blocking(true) or {}

	return &SocketStream{
		port:   port
		conn:   conn
		reader: reader
	}
}

pub fn (mut stream SocketStream) write(buf []u8) !int {
	return stream.conn.write(buf)
}

const newlines = [u8(`\r`), `\n`]

@[manualfree]
pub fn (mut stream SocketStream) read(mut buf []u8) !int {
	mut conlen := 0
	mut header_len := 0

	for {
		// read header line
		got_header := stream.reader.read_line() or { return IError(io.Eof{}) }
		buf << got_header.bytes()
		buf << newlines
		header_len = got_header.len + 2

		if got_header.len == 0 {
			// encounter empty line ('\r\n') in header, header end
			break
		} else if got_header.starts_with(content_length) {
			conlen = got_header.all_after(content_length).int()
		}
	}

	if conlen > 0 {
		mut rbody := []u8{len: conlen}
		defer {
			unsafe { rbody.free() }
		}

		for read_data_len := 0; read_data_len != conlen; {
			read_data_len = stream.reader.read(mut rbody) or { return IError(io.Eof{}) }
		}

		buf << rbody
	}
	return conlen + header_len
}
