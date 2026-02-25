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

## Verify

```bash
make parse-examples
```

This is the single verification target. It runs against `examples/stacktraces` and enforces:

- no parse `ERROR` nodes
- expected frame/field presence (`file`, `line`/`col`, `symbol`) per fixture family

## License

MIT. See [LICENSE](./LICENSE).
