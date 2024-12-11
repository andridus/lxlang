module lsp

struct InitializeResult {
	capabilities ServerCapabilities
	server_info  struct {
		name    string
		version string
	} @[js: 'serverInfo']
}

struct ServerCapabilities {
	text_document_sync  int               @[json: 'textDocumentSync']
	hover_provider      bool              @[json: 'hoverProvider']
	definition_provider bool              @[json: 'definitionProvider']
	completion_provider CompletionOptions @[json: 'completionProvider']
	workspace_folders   struct {
		supported bool
	}     @[json: 'workspaceFolders']
}

struct CompletionOptions {
	// trigger_characters []string @[json: 'triggerCharacters']
	// all_commit_characters []string @[json: 'allCommitCharacters']
	resolve_provider bool @[json: 'resolveProvider']
	// completion_item struct {
	// 	label_details_support bool @[json: 'labelDetailsSupport']
	// } @[json: 'completionItem']
}

fn (c CompletionOptions) str() string {
	return '{"resolveProvider": ${c.resolve_provider}}'
}

fn InitializeResult.new() !InitializeResult {
	return InitializeResult{
		capabilities: ServerCapabilities{
			text_document_sync:  2
			hover_provider:      true
			definition_provider: true
			workspace_folders:   struct {
				supported: true
			}
			completion_provider: CompletionOptions{
				resolve_provider: true
			}
		}
		server_info:  struct {
			name:    'lx-lsp'
			version: '0.0.1'
		}
	}
}
