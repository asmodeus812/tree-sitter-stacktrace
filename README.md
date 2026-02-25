# tree-sitter-stacktrace

Tree-sitter grammar for parsing runtime stack traces across multiple languages.

## Goal

Parse stacktrace lines into stable nodes/fields so editors and tools can extract:

1. `file`
2. `line` / `col` (location)
3. `symbol` (optional)

This grammar prioritizes file and location capture over symbol detail.

## Supported Formats

Primary language families currently covered:

- Java
- C# / .NET
- Node.js / V8
- Python
- PHP
- Ruby
- Go
- Rust
- Swift
- Elixir

Fallback patterns are included for generic `file:line[:col]` and `file(line,col)` forms.

## Project Layout

- `grammar.js`: grammar source
- `src/`: generated parser artifacts
- `queries/`: tree-sitter queries (highlights)
- `examples/stacktraces/`: real-world fixtures
- `scripts/parse_examples.sh`: fixture parser + field assertion runner

## Build

```bash
make build
```

Build regenerates parser artifacts, compiles the grammar, and refreshes `parser.so`.

## Neovim

Installation can be done through extending the parsers table, and providing the
URL location for the parser

```lua
parsers = {
    stacktrace = {
        install_info = {
            url = "https://github.com/asmodeus812/tree-sitter-stacktrace.git",
            branch = "main",
        },
        filetype = "stacktrace"
    }
},
```

An example integration module that can be used against a raw text, a raw
buffer  or one that has already had the tree loaded for it, to pull viable
information from the content

```lua
local function ts_node_text(node, source)
    if not node then
        return nil
    end
    local text = vim.treesitter.get_node_text(node, source)
    if type(text) == "table" then
        return table.concat(text, "\n")
    end
    return text
end

local function ts_first_field_text(node, field_name, source)
    if not node then
        return nil
    end
    local fields = node:field(field_name)
    if not fields or #fields == 0 then
        return nil
    end
    return ts_node_text(fields[1], source)
end

local function language_from_node_type(node_type)
    local map = {
        java_frame = "java",
        java_more = "java",
        java_common_omitted = "java",
        csharp_frame = "csharp",
        python_frame = "python",
        node_frame_func = "node",
        node_frame_bare = "node",
        at_signature_frame = "generic",
        php_frame = "php",
        php_main_frame = "php",
        ruby_frame = "ruby",
        go_location_frame = "go",
        rust_frame = "rust",
        rust_backtrace_entry = "rust",
        swift_runtime_frame = "swift",
        swift_prefixed_location = "swift",
        elixir_frame = "elixir",
        fallback_file_colon = "generic",
        fallback_file_paren = "generic",
        fallback_file_line = "generic",
    }
    return map[node_type] or "generic"
end

local function sanitize_symbol_generic(symbol)
    if type(symbol) ~= "string" then
        return nil
    end
    local s = vim.trim(symbol)
    if s == "" then
        return nil
    end

    s = s:gsub("%s+%b()", "")
    s = s:gsub("%b()", "")
    s = s:gsub("%[as [^%]]+%]", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s ~= "" and s or nil
end

local function strip_callable_tail(symbol)
    if type(symbol) ~= "string" or symbol == "" then
        return symbol
    end

    local s = symbol
    s = s:gsub("::[%w_$<>%-]+$", "")
    s = s:gsub("%.[%w_$<>%-]+$", "")
    s = s:gsub("#[%w_$<>%-]+$", "")

    return s ~= "" and s or symbol
end

local function sanitize_symbol(symbol, lang)
    local s = sanitize_symbol_generic(symbol)
    if not s then
        return nil
    end

    if lang == "java" then
        s = s:gsub("%$%$EnhancerBy[^%.]+", "")
        s = s:gsub("%$%$FastClassBy[^%.]+", "")
        s = s:gsub("%$%$Lambda%$[^%.]+", "")
        s = s:gsub("%$Proxy%d+", "")
    elseif lang == "csharp" then
        s = s:gsub("%+<[^>]+>d__%d+", "")
    elseif lang == "rust" then
        s = s:gsub("::%{%{closure%}%}", "")
    elseif lang == "elixir" then
        s = s:gsub("/%d+$", "")
    end

    s = strip_callable_tail(s)
    s = s:gsub("%.%.+", ".")
    s = s:gsub("^%.+", ""):gsub("%.+$", "")
    s = vim.trim(s)
    return s ~= "" and s or nil
end

local function parse_from_node(node, source)
    if not node then
        return nil
    end

    local node_type = node:type()
    local lang = language_from_node_type(node_type)
    local file = ts_first_field_text(node, "file", source)
    local line = ts_first_field_text(node, "line", source)
    local column = ts_first_field_text(node, "col", source)
    local symbol = ts_first_field_text(node, "symbol", source)

    if file or line then
        if type(file) == "string" then
            file = file:gsub("^['\"]", ""):gsub("['\"]$", "")
            file = vim.fs.normalize(vim.fn.simplify(file))
        end

        local identifier = symbol ~= "" and symbol or nil
        symbol = sanitize_symbol(identifier, lang)
        file = file ~= "" and file or nil

        local lnum = line ~= "" and tonumber(line) or 1
        local col = column ~= "" and tonumber(column) or 1

        return {
            symbol = symbol,
            identifier = identifier,
            language = lang,
            file = file,
            lnum = lnum,
            col = col,
            location = { lnum = lnum, col = col },
        }
    end
end

local function parse_from_tree(tree, row, col, source)
    if not tree then
        return nil
    end
    local node = tree:root():named_descendant_for_range(row, col, row, col)
    while node do
        local parsed = parse_from_node(node, source)
        if parsed and next(parsed) then
            return parsed
        end
        node = node:parent()
    end
    return nil
end

local function parse_raw_text(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end
    local ok, parser = pcall(vim.treesitter.get_string_parser, text .. "\n", "stacktrace")
    if not ok or not parser then
        return nil
    end
    local trees = parser:parse()
    local tree = trees and trees[1] or nil
    return parse_from_tree(tree, 0, 0, text)
end

local function get_stacktrace_context(opts)
    opts = opts or {}
    local text = opts.text
    local winid = opts.winid
    local bufnr = opts.bufnr

    if type(text) == "string" then
        assert(winid == nil and bufnr == nil)
        return parse_raw_text(text)
    end

    if not winid then
        winid = vim.api.nvim_get_current_win()
    end

    if not bufnr then
        bufnr = vim.api.nvim_win_get_buf(winid)
    end

    assert(text == nil)
    local row, col = 0, 0
    if opts.lnum ~= nil then
        row = math.max(0, opts.lnum - 1)
        col = math.max(0, opts.col or 0)
    elseif winid then
        local cursor = vim.api.nvim_win_get_cursor(winid)
        row = cursor[1] - 1
        col = cursor[2]
    end

    if bufnr then
        local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "stacktrace")
        if not ok or not parser then
            ok, parser = pcall(vim.treesitter.get_parser, bufnr)
        end
        if ok and parser then
            local trees = parser:parse()
            local tree = trees and trees[1] or nil
            return parse_from_tree(tree, row, col, bufnr)
        else
            text = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)
            return text and #text > 0 and parse_raw_text(text[1])
        end
    end

    return nil
end
```

## Verify

```bash
make parse-examples
```

This is the single verification target. It runs against `examples/stacktraces` and enforces:

- no parse `ERROR` nodes
- expected frame/field presence (`file`, `line`/`col`, `symbol`) per fixture family

## License

MIT. See [LICENSE](./LICENSE).
