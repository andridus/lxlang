module lsp

import io
import net

struct SocketStream {
	log_label string = 'lxls-server'
	log       bool   = true
mut:
	listener &net.TcpListener = unsafe{ nil}
	streams []io.ReaderWriter
pub mut:
	port  int = 5007
	debug bool
}

struct SocketChildStream {
mut:
	conn   &net.TcpConn       = &net.TcpConn(net.listen_tcp(.ip, '80')!)
	reader &io.BufferedReader = unsafe { nil }
}

fn SocketStream.new(port int) &SocketStream {
	return &SocketStream{
		port:   port
	}
}

pub fn (stream SocketStream) write(buf []u8) !int { return 0}
pub fn (stream SocketStream) read(mut buf []u8) !int {return 0}

fn listen (mut socket SocketStream) !&SocketChildStream {
	if socket.listener == unsafe { nil } {
		mut listener := net.listen_tcp(.ip, ':${socket.port}')!
		socket.listener = listener
	}
	laddr := socket.listener.addr()!
	eprintln('Lx - Elixir Language Server, listen on ${laddr} ...')
	mut conn := socket.listener.accept() or {
		socket.listener.close() or {}
		return err
	}
	client_addr := conn.peer_addr()!
	eprintln('> new client: ${client_addr}')
	mut reader := io.new_buffered_reader(reader: conn, cap: 1024 * 1024)
	conn.set_blocking(true) or {}

	stream := &SocketChildStream{
		conn: conn
		reader: reader
	}
	socket.streams << stream
	return stream
}

pub fn (mut stream SocketChildStream) write(buf []u8) !int {
	return stream.conn.write(buf)
}

const newlines = [u8(`\r`), `\n`]

// @[manualfree]
pub fn (mut stream SocketChildStream) read(mut buf []u8) !int {
	mut conlen := 0
	mut header_len := 0
	for {
		got_header := stream.reader.read_line() or { return IError(io.Eof{}) }
		buf << got_header.bytes()
		buf << newlines
		header_len = got_header.len + 2
		if got_header.len == 0 {
			break
		} else if got_header.starts_with('Content-Length: ') {
			conlen = got_header.all_after('Content-Length: ').int()
		}
	}

	if conlen > 0 {
		mut rbody := []u8{len: conlen}
		defer {
			unsafe { rbody.free() }
		}
		mut total_read := 0
		for total_read < conlen {
			bytes_read := stream.reader.read(mut rbody[total_read..]) or { return IError(io.Eof{}) }
			if bytes_read == 0 {
        return IError(io.Eof{})
    	}
			total_read += bytes_read
		}
		buf << rbody

	}
	return conlen + header_len
}
