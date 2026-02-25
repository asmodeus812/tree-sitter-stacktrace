; stacktrace highlights (file/location first, symbol optional)

(java_frame) @stacktrace.frame
(csharp_frame) @stacktrace.frame
(python_frame) @stacktrace.frame
(node_frame_func) @stacktrace.frame
(node_frame_bare) @stacktrace.frame
(at_signature_frame) @stacktrace.frame
(php_frame) @stacktrace.frame
(php_main_frame) @stacktrace.frame
(ruby_frame) @stacktrace.frame
(go_location_frame) @stacktrace.frame
(rust_frame) @stacktrace.frame
(rust_backtrace_entry) @stacktrace.frame
(swift_runtime_frame) @stacktrace.frame
(swift_prefixed_location) @stacktrace.frame
(elixir_frame) @stacktrace.frame
(fallback_file_colon) @stacktrace.frame
(fallback_file_paren) @stacktrace.frame
(fallback_file_line) @stacktrace.frame

(exception_header) @keyword
(exception_header message: (rest) @comment)
(java_more count: (number) @stacktrace.line)

(java_frame file: (_) @stacktrace.file)
(csharp_frame file: (_) @stacktrace.file)
(python_frame file: (_) @stacktrace.file)
(node_frame_func file: (_) @stacktrace.file)
(node_frame_bare file: (_) @stacktrace.file)
(php_frame file: (_) @stacktrace.file)
(ruby_frame file: (_) @stacktrace.file)
(go_location_frame file: (_) @stacktrace.file)
(rust_frame file: (_) @stacktrace.file)
(swift_prefixed_location file: (_) @stacktrace.file)
(elixir_frame file: (_) @stacktrace.file)
(fallback_file_colon file: (_) @stacktrace.file)
(fallback_file_paren file: (_) @stacktrace.file)
(fallback_file_line file: (_) @stacktrace.file)
(file_path) @stacktrace.file
(file_name) @stacktrace.file
(quoted_file_path) @stacktrace.file

(java_frame line: (number) @stacktrace.line)
(java_frame col: (number) @stacktrace.col)
(csharp_frame line: (number) @stacktrace.line)
(csharp_frame col: (number) @stacktrace.col)
(python_frame line: (number) @stacktrace.line)
(node_frame_func line: (number) @stacktrace.line)
(node_frame_func col: (number) @stacktrace.col)
(node_frame_bare line: (number) @stacktrace.line)
(node_frame_bare col: (number) @stacktrace.col)
(php_frame line: (number) @stacktrace.line)
(ruby_frame line: (number) @stacktrace.line)
(go_location_frame line: (number) @stacktrace.line)
(rust_frame line: (number) @stacktrace.line)
(rust_frame col: (number) @stacktrace.col)
(swift_prefixed_location line: (number) @stacktrace.line)
(swift_prefixed_location col: (number) @stacktrace.col)
(elixir_frame line: (number) @stacktrace.line)
(fallback_file_colon line: (number) @stacktrace.line)
(fallback_file_colon col: (number) @stacktrace.col)
(fallback_file_paren line: (number) @stacktrace.line)
(fallback_file_paren col: (number) @stacktrace.col)
(fallback_file_line line: (number) @stacktrace.line)

(java_frame symbol: (_) @stacktrace.symbol)
(csharp_frame symbol: (_) @stacktrace.symbol)
(python_frame symbol: (_) @stacktrace.symbol)
(node_frame_func symbol: (_) @stacktrace.symbol)
(at_signature_frame symbol: (_) @stacktrace.symbol)
(php_frame symbol: (_) @stacktrace.symbol)
(php_main_frame symbol: (_) @stacktrace.symbol)
(ruby_frame symbol: (_) @stacktrace.symbol)
(go_location_frame symbol: (_) @stacktrace.symbol)
(rust_backtrace_entry symbol: (_) @stacktrace.symbol)
(swift_runtime_frame symbol: (_) @stacktrace.symbol)
(swift_prefixed_location symbol: (_) @stacktrace.symbol)
(elixir_frame symbol: (_) @stacktrace.symbol)
(fallback_file_colon symbol: (_) @stacktrace.symbol)
(fallback_file_paren symbol: (_) @stacktrace.symbol)
(fallback_file_line symbol: (_) @stacktrace.symbol)

(qualified_symbol) @stacktrace.symbol
(node_call_symbol) @stacktrace.symbol
(ruby_symbol) @stacktrace.symbol
(swift_module) @type
(php_main_symbol) @stacktrace.symbol
(identifier) @stacktrace.symbol
