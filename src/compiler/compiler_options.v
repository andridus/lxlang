module compiler

pub enum CompilerReturns {
	beam_chunks
	beam_bytes
	beam_file
	ast
}

pub struct CompilerOptions {
pub:
	returns CompilerReturns
}
