module lsp

import os
import io

struct StdioStream {
mut:
	stdin  os.File = os.stdin()
	stdout os.File = os.stdout()
}

pub fn (mut stream StdioStream) write(buf []u8) !int {
	defer {
		stream.stdout.flush()
	}
	return stream.stdout.write(buf)
}

pub fn (mut stream StdioStream) read(mut buf []u8) !int {
	mut header_len := 0
	mut conlen := 0
	for {
		len := read_line(stream.stdin, mut buf) or { return err }
		st := buf.len - len
		line := buf[st..].bytestr()

		buf << `\r`
		buf << `\n`
		header_len = len + 2

		if len == 0 {
			// encounter empty line ('\r\n') in header, header end
			break
		} else if line.starts_with(content_length) {
			conlen = line.all_after(content_length).int()
		}
	}

	mut body := []u8{len: conlen}
	read_cnt := stream.stdin.read(mut body) or { return err }
	if read_cnt != conlen {
		return IError(io.Eof{})
	}
	buf << body

	return header_len + conlen
}

fn read_line(file &os.File, mut buf []u8) !int {
	mut len := 0
	mut temp := []u8{len: 256, cap: 256}
	for {
		read_cnt := file.read_bytes_with_newline(mut temp) or { return err }
		len += read_cnt
		buf << temp[0..read_cnt]
		if read_cnt == 0 {
			return if len == 0 {
				IError(io.Eof{})
			} else {
				len
			}
		}
		if buf.len > 0 && buf.last() == `\n` {
			buf.pop()
			len--
			// check is it just '\n' or '\r\n'
			if len > 0 && buf.last() == `\r` {
				buf.pop()
				len--
			}
			break
		}
	}
	return len
}
