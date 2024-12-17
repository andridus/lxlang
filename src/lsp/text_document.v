module lsp

struct DidOpenTextDocumentParams {
	text_document TextDocument @[json: 'textDocument']
}

struct DidChangeTextDocumentParams {
	text_document   struct {
		uri     string
		version int
	} @[json: 'textDocument']
	content_changes []TextDocumentContentChangeEvent @[json: 'contentChanges']
}

struct TextDocument {
	uri         string
	language_id string @[json: 'languageId']
	version     int
	text        string
}

struct TextDocumentContentChangeEvent {
	range        Range
	range_length int @[json: 'rangeLength']
	text         string
}

struct Range {
	start Position
	end   Position
}

fn (r Range) str() string {
	return '{"start":${r.start.str()}, "end": ${r.end.str()}}'
}

struct Position {
	line      int
	character int
}

fn (p Position) str() string {
	return '{"line":${p.line}, "character": ${p.character}}'
}

struct Location {
	uri   string
	range Range
}

fn (l Location) str() string {
	return '{"uri":"${l.uri}", "range": ${l.range.str()}}'
}

struct HoverParams {
	text_document TextDocument @[json: 'textDocument']
	position      Position
}

fn new_hover_result(contents string) string {
	if contents == '' {
		return '{"contents": null}'
	} else {
		return '{"contents":{"language":"markdown","value":"${replace_chars(contents)}"}}'
	}
}

fn replace_chars(str string) string {
	return str.replace('\n', '\\n')
}

struct DefinitionParams {
	position      Position
	text_document TextDocument @[json: 'textDocument']
}

struct DefinitionResult {
	location Location
}

fn DefinitionResult.new(file string, start Position, end Position) DefinitionResult {
	location := Location{
		uri:   file
		range: Range{
			start: start
			end:   end
		}
	}
	return DefinitionResult{location}
}

fn (d DefinitionResult) str() string {
	return d.location.str()
}

struct CompletionParams {
	context       struct {
		trigger_kind      int    @[json: 'triggerKind']
		trigger_character string @[json: 'triggerCharacter']
	}
	position      Position
	text_document TextDocument @[json: 'textDocument']
}

struct CompletionItem {
	label         string
	detail        string
	documentation string
}

fn (c CompletionItem) str() string {
	return '{"label": "${c.label}","detail": "${c.detail}", "documentation": "${c.documentation}"}'
}
