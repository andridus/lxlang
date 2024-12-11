module lsp

struct ClientInfo {
	name    string
	version string
}

struct InitializeParams {
	process_id             int        @[json: 'processId']
	client_info            ClientInfo @[json: 'clientInfo']
	locale                 string
	root_path              string                @[json: 'rootPath']
	root_uri               string                @[json: 'rootUri']
	initialization_options InitializationOptions @[json: 'initializationOptions']
	capabilities           ClientCapabilities    @[json: 'capabilities']
	trace                  string
	workspace_folders      []WorkspaceFolder @[json: 'workspaceFolders']
}

struct InitializationOptions {
	experimental struct {
		completions struct {
			enabled bool
		}
	}
}

struct WorkspaceFolder {
	uri  string
	name string
}

struct ClientCapabilities {
	workspace         Workspace                          @[json: 'workspace']
	text_document     TextDocumentClientCapabilities     @[json: 'textDocument']
	notebook_document NotebookDocumentClientCapabilities @[json: 'notebookDocument']
	window            Window  @[json: 'window']
	general           General @[json: 'general']
	experimental      string
}

struct Workspace {
	apply_edit               bool @[json: 'applyEdit']
	workspace_edit           WorkspaceEditClientCapabilities          @[json: 'workspaceEdit']
	did_change_configuration DidChangeConfigurationClientCapabilities @[json: 'didChangeConfiguration']
	did_change_watched_files DidChangeWatchedFilesClientCapabilities  @[json: 'didChangeWatchedFiles']
	symbol                   WorkspaceSymbolClientCapabilities        @[json: 'symbol']
	execute_command          ExecuteCommandClientCapabilities         @[json: 'executeCommand']
	workspace_folders        bool @[json: 'workspaceFolders']
	configuration            bool
	semantic_tokens          SemanticTokensWorkspaceClientCapabilities @[json: 'semanticTokens']
	code_lens                CodeLensWorkspaceClientCapabilities       @[json: 'codeLens']
	file_operations          FileOperations                         @[json: 'fileOperations']
	inline_value             InlineValueWorkspaceClientCapabilities @[json: 'inlineValue']
	inlay_hint               InlayHintWorkspaceClientCapabilities   @[json: 'inlayHint']
	diagnostics              DiagnosticWorkspaceClientCapabilities  @[json: 'diagnostics']
}

enum ResourceOperationKind {
	create
	rename
	delete
}

enum FailureHandlingKind {
	abort
	transactional
	undo
	text_only_transactional
}

struct WorkspaceEditClientCapabilities {
	document_changes          bool                    @[json: 'documentChanges']
	resource_operations       []ResourceOperationKind @[json: 'resourceOperations']
	failure_handling          FailureHandlingKind     @[json: 'failureHandling']
	normalizes_line_endings   bool                    @[json: 'normalizesLineEndings']
	change_annotation_support ChangeAnnotationSupport @[json: 'changeAnnotationSupport']
}

struct ChangeAnnotationSupport {
	groups_on_label bool @[json: 'groupsOnLabel']
}

struct DidChangeConfigurationClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct DidChangeWatchedFilesClientCapabilities {
	dynamic_registration     bool @[json: 'dynamicRegistration']
	relative_pattern_support bool @[json: 'relativePatternSupport']
}

struct ExecuteCommandClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct SemanticTokensWorkspaceClientCapabilities {
	refresh_support bool @[json: 'refreshSupport']
}

struct CodeLensWorkspaceClientCapabilities {
	refresh_support bool @[json: 'refreshSupport']
}

struct InlineValueWorkspaceClientCapabilities {
	refresh_support bool @[json: 'refreshSupport']
}

struct InlayHintWorkspaceClientCapabilities {
	refresh_support bool @[json: 'refreshSupport']
}

struct DiagnosticWorkspaceClientCapabilities {
	refresh_support bool @[json: 'refreshSupport']
}

struct NotebookDocumentClientCapabilities {
	synchronization NotebookDocumentSyncClientCapabilities @[json: 'synchronization']
}

struct NotebookDocumentSyncClientCapabilities {
	dynamic_registration      bool @[json: 'dynamicRegistration']
	execution_summary_support bool @[json: 'executionSummarySupport']
}

struct RelativePattern {
	base_uri string
	pattern  string
}

struct TextDocumentSyncClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
	will_save            bool @[json: 'willSave']
	will_save_wait_until bool @[json: 'willSaveWaitUntil']
	did_save             bool @[json: 'didSave']
}

struct WorkspaceSymbolClientCapabilities {
	dynamic_registration bool             @[json: 'dynamicRegistration']
	symbol_kind          SymbolKindStruct @[json: 'symbolKind']
	tag_support          TagSupport       @[json: 'tagSupport']
	resolve_support      ResolveSupport   @[json: 'resolveSupport']
}

struct SymbolKindStruct {
	value_set []SymbolKind @[json: 'valueSet']
}

struct TagSupport {
	value_set []SymbolTag @[json: 'valueSet']
}

struct ResolveSupport {
	properties []string @[json: 'properties']
}

struct FileOperations {
	dynamic_registration bool @[json: 'dynamicRegistration']
	did_create           bool @[json: 'didCreate']
	will_create          bool @[json: 'willCreate']
	did_rename           bool @[json: 'didRename']
	will_rename          bool @[json: 'willRename']
	did_delete           bool @[json: 'didDelete']
	will_delete          bool @[json: 'willDelete']
}

enum SymbolKind {
	file
	module
	namespace
	package
	class
	method
	property
	field
	constructor
	enum
	interface
	function
	variable
	constant
	string
	number
	boolean
	array
	object
	key
	null
	enum_member
	struct
	event
	operator
	type_parameter
}

enum SymbolTag {
	deprecated
}

struct TextDocumentClientCapabilities {
	synchronization      TextDocumentSyncClientCapabilities         @[json: 'synchronization']
	completion           CompletionClientCapabilities               @[json: 'completion']
	hover                HoverClientCapabilities                    @[json: 'hover']
	signature_help       SignatureHelpClientCapabilities            @[json: 'signatureHelp']
	declaration          DeclarationClientCapabilities              @[json: 'declaration']
	definition           DefinitionClientCapabilities               @[json: 'definition']
	type_definition      TypeDefinitionClientCapabilities           @[json: 'typeDefinition']
	implementation       ImplementationClientCapabilities           @[json: 'implementation']
	references           ReferenceClientCapabilities                @[json: 'references']
	document_highlight   DocumentHighlightClientCapabilities        @[json: 'documentHighlight']
	document_symbol      DocumentSymbolClientCapabilities           @[json: 'documentSymbol']
	code_action          CodeActionClientCapabilities               @[json: 'codeAction']
	code_lens            CodeLensClientCapabilities                 @[json: 'codeLens']
	document_link        DocumentLinkClientCapabilities             @[json: 'documentLink']
	color_provider       DocumentColorClientCapabilities            @[json: 'colorProvider']
	formatting           DocumentFormattingClientCapabilities       @[json: 'formatting']
	range_formatting     DocumentRangeFormattingClientCapabilities  @[json: 'rangeFormatting']
	on_type_formatting   DocumentOnTypeFormattingClientCapabilities @[json: 'onTypeFormatting']
	rename               RenameClientCapabilities                   @[json: 'rename']
	publish_diagnostics  PublishDiagnosticsClientCapabilities       @[json: 'publishDiagnostics']
	folding_range        FoldingRangeClientCapabilities             @[json: 'foldingRange']
	selection_range      SelectionRangeClientCapabilities           @[json: 'selectionRange']
	linked_editing_range LinkedEditingRangeClientCapabilities       @[json: 'linkedEditingRange']
	call_hierarchy       CallHierarchyClientCapabilities            @[json: 'callHierarchy']
	semantic_tokens      SemanticTokensClientCapabilities           @[json: 'semanticTokens']
	moniker              MonikerClientCapabilities                  @[json: 'moniker']
	type_hierarchy       TypeHierarchyClientCapabilities            @[json: 'typeHierarchy']
	inline_value         InlineValueClientCapabilities              @[json: 'inlineValue']
	inlay_hint           InlayHintClientCapabilities                @[json: 'inlayHint']
	diagnostic           DiagnosticClientCapabilities               @[json: 'diagnostic']
}

struct Window {
	work_done_progress bool @[json: 'workDoneProgress']
	show_message       ShowMessageRequestClientCapabilities @[json: 'showMessage']
	show_document      ShowDocumentClientCapabilities       @[json: 'showDocument']
}

struct General {
	stale_request_support StaleRequestSupport                  @[json: 'staleRequestSupport']
	regular_expressions   RegularExpressionsClientCapabilities @[json: 'regularExpressions']
	markdown              MarkdownClientCapabilities           @[json: 'markdown']
	position_encodings    []PositionEncodingKind               @[json: 'positionEncodings']
}

struct MarkdownClientCapabilities {
	parser       string
	version      string
	allowed_tags []string @[json: 'allowedTags']
}

enum PositionEncodingKind {
	utf8
	utf16
	utf32
}

struct RegularExpressionsClientCapabilities {
	engine  string
	version string
}

struct StaleRequestSupport {
	cancel                    bool     @[json: 'cancel']
	retry_on_content_modified []string @[json: 'retryOnContentModified']
}

enum CompletionItemKind {
	text = 1
	method
	function
	constructor
	field
	variable
	class
	interface
	module
	property
	unit
	value
	enum
	keyword
	snippet
	color
	file
	reference
	folder
	enum_member
	constant
	struct
	event
	operator
	type_parameter
}

struct CompletionClientCapabilities {
	dynamic_registration bool          @[json: 'dynamicRegistratiosn']
	completion_item      struct {
		snippet_support           bool          @[json: 'snippetSupport']
		commit_characters_support bool          @[json: 'commitCharactersSupport']
		documentation_format      []string      @[json: 'documentationFormat'] // plaintext | markdown
		deprecated_support        bool          @[json: 'deprecatedSupport']
		preselect_support         bool          @[json: 'preselectSupport']
		tag_support               struct {
			value_set []u8 @[json: 'valueSet']
		} @[json: 'tagSupport']
		insert_replace_support    bool          @[json: 'insertReplaceSupport']
		resolve_support           struct {
			properties []string
		} @[json: 'resolveSupport']
		insert_text_mode_support  struct {
			value_set []u8 @[json: 'valueSet']
		} @[json: 'insertTextModeSupport']
		label_details_support     bool @[json: 'labelDetailsSupport']
	} @[json: 'completionItem']
	completion_item_kind struct {
		value_set []CompletionItemKind @[json: 'valueSet']
	} @[json: 'completionItemKind']
	context_support      bool          @[json: 'contextSupport']
	insert_text_mode     u8            @[json: 'insertTextMode']
	completion_list      struct {
		item_defaults []string @[json: 'itemDefaults']
	} @[json: 'completionList']
}

struct HoverClientCapabilities {
	dynamic_registration bool   @[json: 'dynamicRegistration']
	content_format       string @[json: 'contentFormat']
}

struct DeclarationClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
	link_support         bool @[json: 'linkSupport']
}

struct DefinitionClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
	link_support         bool @[json: 'linkSupport']
}

struct TypeDefinitionClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
	link_support         bool @[json: 'linkSupport']
}

struct ImplementationClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
	link_support         bool @[json: 'linkSupport']
}

struct ReferenceClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct DocumentHighlightClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct CodeLensClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct DocumentLinkClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
	tooltip_support      bool @[json: 'tooltipSupport']
}

struct DocumentColorClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct DocumentFormattingClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct DocumentRangeFormattingClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct DocumentOnTypeFormattingClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct SelectionRangeClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct LinkedEditingRangeClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct CallHierarchyClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct MonikerClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct TypeHierarchyClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct InlineValueClientCapabilities {
	dynamic_registration bool @[json: 'dynamicRegistration']
}

struct InlayHintClientCapabilities {
	dynamic_registration bool          @[json: 'dynamicRegistration']
	resolve_support      struct {
		properties []string @[json: 'properties']
	} @[json: 'resolveSupport']
}

struct DiagnosticClientCapabilities {
	dynamic_registration     bool @[json: 'dynamicRegistration']
	related_document_support bool @[json: 'relatedDocumentSupport']
}

struct ShowDocumentClientCapabilities {
	support bool @[json: 'support']
}

struct ShowMessageRequestClientCapabilities {
	message_action_item struct {
		additional_properties_support bool @[json: 'additionalPropertiesSupport']
	} @[json: 'messageActionItem']
}

struct SemanticTokensClientCapabilities {
	dynamic_registration      bool           @[json: 'dynamicRegistration']
	requests                  struct {
		range bool @[json: 'range'] // NOTE
		full  bool @[json: 'full']
	} @[json: 'requests']
	token_types               []string @[json: 'tokenTypes']
	token_modifiers           []string @[json: 'tokenModifiers']
	formats                   []string @[json: 'formats']
	overlapping_token_support bool     @[json: 'overlappingTokenSupport']
	multiline_token_support   bool     @[json: 'multilineTokenSupport']
	server_cancel_support     bool     @[json: 'serverCancelSupport']
	augments_syntax_tokens    bool     @[json: 'augmentsSyntaxTokens']
}

struct RenameClientCapabilities {
	dynamic_registration             bool @[json: 'dynamicRegistration']
	prepare_support                  bool @[json: 'prepareSupport']
	prepare_support_default_behavior u8   @[json: 'prepareSupportDefaultBehavior']
	honors_change_annotations        bool @[json: 'honorsChangeAnnotations']
}

struct PublishDiagnosticsClientCapabilities {
	related_information      bool           @[json: 'relatedInformation']
	tag_support              struct {
		value_set []u8 @[json: 'valueSet']
	} @[json: 'tagSupport']
	version_support          bool @[json: 'versionSupport']
	code_description_support bool @[json: 'codeDescriptionSupport']
	data_support             bool @[json: 'dataSupport']
}

struct DocumentSymbolClientCapabilities {
	dynamic_registration                 bool           @[json: 'dynamicRegistration']
	symbol_kind                          struct {
		value_set SymbolKind @[json: 'valueSet']
	} @[json: 'symbolKind']
	hierarchical_document_symbol_support bool           @[json: 'hierarchicalDocumentSymbolSupport']
	tag_support                          struct {
		value_set SymbolTag @[json: 'valueSet']
	} @[json: 'tagSupport']
	label_support                        bool @[json: 'labelSupport']
}

struct CodeActionClientCapabilities {
	dynamic_registration        bool           @[json: 'dynamicRegistration']
	code_action_literal_support struct {
		code_action_kind struct {
			value_set SymbolKind @[json: 'valueSet']
		} @[json: 'codeActionKind']
	} @[json: 'codeActionLiteralSupport']
	is_preferred_support        bool           @[json: 'isPreferredSupport']
	disabled_support            bool           @[json: 'disabledSupport']
	data_support                bool           @[json: 'dataSupport']
	resolve_support             struct {
		properties []string
	} @[json: 'resolveSupport']
	honors_change_annotations   bool @[json: 'honorsChangeAnnotations']
}

struct SignatureHelpClientCapabilities {
	dynamic_registration  bool           @[json: 'dynamicRegistration']
	signature_information struct {
		documentation_format     []string       @[json: 'documentationFormat']
		parameter_information    struct {
			label_offset_support bool @[json: 'labelOffsetSupport']
		} @[json: 'parameterInformation']
		active_parameter_support bool @[json: 'activeParameterSupport']
	} @[json: 'signatureInformation']
}

struct FoldingRangeClientCapabilities {
	dynamic_registration bool           @[json: 'dynamicRegistration']
	range_limit          u8             @[json: 'rangeLimit']
	line_folding_only    bool           @[json: 'lineFoldingOnly']
	folding_range_kind   struct {
		value_set []string @[json: 'valueSet']
	} @[json: 'foldingRangeKind']
	folding_range        struct {
		collapsed_text bool @[json: 'collapsedText']
	} @[json: 'foldingRange']
}
