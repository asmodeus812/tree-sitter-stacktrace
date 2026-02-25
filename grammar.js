module.exports = grammar({
  name: 'stacktrace',
  word: ($) => $.identifier,

  extras: () => [],

  rules: {
    source_file: ($) =>
      seq(repeat(seq(optional($._line_content), $._eol)), optional($._line_content)),

    _line_content: ($) => choice(prec(3, $.stacktrace_content), prec(-3, $.unknown_content)),

    stacktrace_content: ($) =>
      choice(
        $.exception_header,
        $.java_more,
        $.java_common_omitted,
        $.java_frame,
        $.csharp_frame,
        $.python_frame,
        $.node_frame_func,
        $.node_frame_bare,
        $.at_signature_frame,
        $.php_frame,
        $.php_main_frame,
        $.ruby_frame,
        $.go_location_frame,
        $.rust_frame,
        $.rust_backtrace_entry,
        $.swift_runtime_frame,
        $.swift_prefixed_location,
        $.elixir_frame,
        $.fallback_file_colon,
        $.fallback_file_paren,
        $.fallback_file_line,
        $.plain_text_line,
      ),

    exception_header: ($) =>
      seq(
        optional($.ws),
        field(
          'kind',
          choice(
            'Exception in thread',
            'Caused by:',
            'Suppressed:',
            'Traceback (most recent call last):',
            'Error:',
            'Exception:',
            'panic:',
            'Thread',
          ),
        ),
        optional(seq($.ws, field('message', $.rest))),
      ),

    java_more: ($) => seq(optional($.ws), '... ', field('count', $.number), ' more'),
    java_common_omitted: ($) => seq(optional($.ws), token(/\.\.\.\s+[0-9]+\s+common frames omitted/)),

    java_frame: ($) =>
      prec(
        30,
        seq(
          optional($.ws),
          'at',
          $.ws,
          field('symbol', $.qualified_symbol),
          '(',
          choice(
            seq(
              field('file', $.file_name),
              ':',
              field('line', $.number),
              optional(seq(':', field('col', $.number))),
            ),
            field('file', $.file_name),
            field('source', choice('Native Method', 'Unknown Source')),
          ),
          ')',
          optional(seq($.ws, field('meta', $.bracket_meta))),
        ),
      ),

    csharp_frame: ($) =>
      prec(
        22,
        seq(
          optional($.ws),
          'at',
          $.ws,
          field('symbol', choice($.qualified_symbol, $.node_call_symbol)),
          field('signature', $.argument_list),
          $.ws,
          'in',
          $.ws,
          field('file', choice($.file_path, $.file_name)),
          ':line',
          $.ws,
          field('line', $.number),
          optional(seq(':', field('col', $.number))),
          optional(seq($.ws, field('tail', $.rest))),
        ),
      ),

    python_frame: ($) =>
      prec(
        28,
        seq(
          optional($.ws),
          'File',
          $.ws,
          field('file', choice($.quoted_file_path, $.file_path, $.file_name)),
          ',',
          $.ws,
          'line',
          $.ws,
          field('line', $.number),
          ',',
          $.ws,
          'in',
          $.ws,
          field('symbol', $.identifier),
        ),
      ),

    node_frame_func: ($) =>
      prec(
        27,
        seq(
          optional($.ws),
          'at',
          $.ws,
          optional(seq('async', $.ws)),
          field('symbol', choice($.qualified_symbol, $.node_call_symbol)),
          optional(seq($.ws, field('alias', $.bracket_meta))),
          $.ws,
          '(',
          field('file', choice($.file_path, $.file_name, $.node_internal_path)),
          ':',
          field('line', $.number),
          ':',
          field('col', $.number),
          ')',
        ),
      ),

    node_frame_bare: ($) =>
      prec(
        26,
        seq(
          optional($.ws),
          'at',
          $.ws,
          optional(seq('async', $.ws)),
          field('file', choice($.file_path, $.file_name, $.node_internal_path)),
          ':',
          field('line', $.number),
          ':',
          field('col', $.number),
        ),
      ),

    at_signature_frame: ($) =>
      prec(
        29,
        seq(
          optional($.ws),
          'at',
          $.ws,
          field('symbol', choice($.qualified_symbol, $.identifier)),
          optional($.ws),
          field('signature', $.argument_list),
        ),
      ),

    php_frame: ($) =>
      prec(
        25,
        seq(
          optional($.ws),
          '#',
          $.number,
          $.ws,
          field('file', choice($.file_path, $.file_name)),
          '(',
          field('line', $.number),
          ')',
          ':',
          optional($.ws),
          field('symbol', $.rest),
        ),
      ),

    php_main_frame: ($) => seq(optional($.ws), '#', $.number, $.ws, field('symbol', $.php_main_symbol)),

    ruby_frame: ($) =>
      prec(
        24,
        seq(
          optional($.ws),
          optional(seq('from', $.ws)),
          field('file', choice($.file_path, $.file_name)),
          ':',
          field('line', $.number),
          ':in',
          $.ws,
          field('symbol', $.ruby_symbol),
        ),
      ),

    go_location_frame: ($) =>
      prec(
        23,
        seq(
          optional($.ws),
          field('file', choice($.file_path, $.file_name)),
          ':',
          field('line', $.number),
          optional(seq($.ws, field('symbol', $.go_offset))),
        ),
      ),

    rust_frame: ($) =>
      prec(
        28,
        seq(
          optional($.ws),
          'at',
          $.ws,
          field('file', $.file_path),
          ':',
          field('line', $.number),
          ':',
          field('col', $.number),
        ),
      ),

    rust_backtrace_entry: ($) =>
      prec(21, seq(optional($.ws), field('index', $.number), ':', optional($.ws), field('symbol', $.rest))),

    swift_runtime_frame: ($) =>
      prec(
        20,
        seq(
          optional($.ws),
          field('index', $.number),
          $.ws,
          field('module', $.swift_module),
          $.ws,
          field('address', $.hex_address),
          $.ws,
          field('symbol', $.rest),
        ),
      ),

    swift_prefixed_location: ($) =>
      prec(
        20,
        seq(
          optional($.ws),
          choice('Fatal error:', 'Precondition failed:', 'Assertion failed:'),
          optional($.ws),
          field('file', choice($.file_path, $.file_name)),
          ':',
          field('line', $.number),
          optional(seq(':', field('col', $.number))),
          optional(seq(':', optional($.ws), field('symbol', $.rest))),
        ),
      ),

    elixir_frame: ($) =>
      prec(
        19,
        seq(
          optional($.ws),
          field('app', $.paren_block),
          $.ws,
          field('file', choice($.file_path, $.file_name)),
          ':',
          field('line', $.number),
          ':',
          optional($.ws),
          field('symbol', $.rest),
        ),
      ),

    fallback_file_colon: ($) =>
      prec(
        8,
        seq(
          optional($.ws),
          field('file', choice($.file_path, $.file_name)),
          ':',
          field('line', $.number),
          ':',
          field('col', $.number),
          optional(seq(':', optional($.ws), field('symbol', $.rest))),
        ),
      ),

    fallback_file_paren: ($) =>
      prec(
        7,
        seq(
          optional($.ws),
          field('file', choice($.file_path, $.file_name)),
          '(',
          field('line', $.number),
          optional(seq(',', optional($.ws), field('col', $.number))),
          ')',
          optional(seq(':', optional($.ws), field('symbol', $.rest))),
        ),
      ),

    fallback_file_line: ($) =>
      prec(
        6,
        seq(
          optional($.ws),
          field('file', choice($.file_path, $.file_name)),
          ':',
          field('line', $.number),
          optional(seq(':', optional($.ws), field('symbol', $.rest))),
        ),
      ),

    plain_text_line: ($) => prec(-10, seq(optional($.ws), field('symbol', $.rest))),

    argument_list: ($) => seq('(', optional($.argument_text), ')'),
    argument_text: () => token(prec(-10, /[^)\r\n]+/)),

    paren_block: () => seq('(', token(/[^)\r\n]*/), ')'),
    bracket_meta: () => seq('[', token(/[^\]\r\n]*/), ']'),

    file_path: () =>
      token(
        choice(
          /[A-Za-z]:\\[^:\r\n()]+\.[A-Za-z0-9_.$@-]{1,6}/,
          /\/(?:[^:\r\n()]+\/)*[^:\r\n()]+\.[A-Za-z0-9_.$@-]{1,6}/,
          /\.\.?[\\/](?:[^:\r\n()]+[\\/])*[^:\r\n()]+\.[A-Za-z0-9_.$@-]{1,6}/,
          /[A-Za-z0-9_~.-]+(?:[\\/][A-Za-z0-9_~ .-]+)+\.[A-Za-z0-9_.$@-]{1,6}/,
        ),
      ),

    file_name: () => token(/[A-Za-z0-9_@$-]+(?:\.[A-Za-z0-9_@$-]+)?\.[A-Za-z0-9_@$-]{1,6}/),
    quoted_file_path: () => token(choice(/"[^"\r\n]+"/, /'[^'\r\n]+'/)),

    qualified_symbol: () =>
      token(
        prec(
          2,
          /[A-Za-z_$<][A-Za-z0-9_$`<>|/.-]*(\[[^\]\r\n]+\])?(\.[A-Za-z_$<][A-Za-z0-9_$`<>|/.-]*(\[[^\]\r\n]+\])?)+/,
        ),
      ),
    node_call_symbol: () => token(prec(-1, /[^()\r\n]+[^()\r\n ]/)),
    node_internal_path: ($) => seq('node:', $.node_internal_ident, repeat(seq('/', $.node_internal_ident))),
    node_internal_ident: () => token(/[A-Za-z0-9_.-]+/),

    ruby_symbol: () => token(choice(/`[^'\r\n]+'/, /`[^`\r\n]+`/)),
    go_offset: () => token(/\+0x[0-9A-Fa-f]+/),
    php_main_symbol: () => token(/\{main\}/),
    hex_address: () => token(/0x[0-9A-Fa-f]+/),
    swift_module: () => token(/[A-Za-z_][A-Za-z0-9_.-]*/),

    identifier: () => token(/[A-Za-z_$<][A-Za-z0-9_$<>-]*/),
    number: () => token(/[0-9]+/),
    ws: () => token(/[ \t]+/),
    rest: () => token(prec(-20, /[^\r\n]+/)),
    unknown_content: () => token(prec(-30, /[^\r\n]+/)),

    _eol: () => token(/\r?\n/),
  },
});
