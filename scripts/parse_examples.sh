#!/usr/bin/env bash
set -u

TS_BIN="${TS:-tree-sitter}"
EXAMPLES_DIR="${1:-examples/stacktraces}"
LOG_DIR="${2:-.parse-examples}"

if [ ! -d "$EXAMPLES_DIR" ]; then
  echo "[parse-examples] directory not found: $EXAMPLES_DIR" >&2
  exit 2
fi

shopt -s nullglob
files=("$EXAMPLES_DIR"/*.txt)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "[parse-examples] no .txt fixtures found in $EXAMPLES_DIR" >&2
  exit 2
fi

failures=0

count_ge() {
  local text="$1" pattern="$2" min="$3" label="$4"
  local c
  c=$(grep -E -c "$pattern" <<<"$text" || true)
  if [ "$c" -lt "$min" ]; then
    echo "      fail: $label (have=$c need>=$min)"
    return 1
  fi
  return 0
}

run_checks() {
  local name="$1" out="$2"
  local ok=0

  case "$name" in
    java_*)
      count_ge "$out" "\\(java_frame" 8 "java frames" || ok=1
      count_ge "$out" "file:" 8 "java file fields" || ok=1
      count_ge "$out" "line:" 7 "java line fields" || ok=1
      count_ge "$out" "symbol:" 8 "java symbol fields" || ok=1
      ;;
    csharp_*)
      count_ge "$out" "\\(csharp_frame" 6 "csharp frames" || ok=1
      count_ge "$out" "file:" 3 "csharp file fields" || ok=1
      count_ge "$out" "line:" 3 "csharp line fields" || ok=1
      count_ge "$out" "symbol:" 6 "csharp symbol fields" || ok=1
      ;;
    nodejs_*)
      count_ge "$out" "\\(node_frame_(func|bare)" 8 "node frames" || ok=1
      count_ge "$out" "file:" 8 "node file fields" || ok=1
      count_ge "$out" "line:" 8 "node line fields" || ok=1
      count_ge "$out" "col:" 8 "node col fields" || ok=1
      count_ge "$out" "symbol:" 6 "node symbol fields" || ok=1
      ;;
    python_*)
      count_ge "$out" "\\(python_frame" 8 "python frames" || ok=1
      count_ge "$out" "file:" 8 "python file fields" || ok=1
      count_ge "$out" "line:" 8 "python line fields" || ok=1
      count_ge "$out" "symbol:" 8 "python symbol fields" || ok=1
      ;;
    php_*)
      count_ge "$out" "\\(php_frame" 8 "php frames" || ok=1
      count_ge "$out" "file:" 8 "php file fields" || ok=1
      count_ge "$out" "line:" 8 "php line fields" || ok=1
      count_ge "$out" "symbol:" 8 "php symbol fields" || ok=1
      ;;
    ruby_*)
      count_ge "$out" "\\(ruby_frame" 6 "ruby frames" || ok=1
      count_ge "$out" "file:" 6 "ruby file fields" || ok=1
      count_ge "$out" "line:" 6 "ruby line fields" || ok=1
      count_ge "$out" "symbol:" 6 "ruby symbol fields" || ok=1
      ;;
    go_*)
      count_ge "$out" "\\(go_location_frame" 6 "go frames" || ok=1
      count_ge "$out" "file:" 6 "go file fields" || ok=1
      count_ge "$out" "line:" 6 "go line fields" || ok=1
      ;;
    rust_*)
      count_ge "$out" "\\(rust_frame" 8 "rust location frames" || ok=1
      count_ge "$out" "\\(rust_backtrace_entry" 6 "rust symbol entries" || ok=1
      count_ge "$out" "file:" 8 "rust file fields" || ok=1
      count_ge "$out" "line:" 8 "rust line fields" || ok=1
      count_ge "$out" "col:" 8 "rust col fields" || ok=1
      count_ge "$out" "symbol:" 6 "rust symbol fields" || ok=1
      ;;
    swift_*)
      count_ge "$out" "\\(swift_prefixed_location" 1 "swift prefixed location" || ok=1
      count_ge "$out" "\\(swift_runtime_frame" 6 "swift runtime frames" || ok=1
      count_ge "$out" "file:" 1 "swift file fields" || ok=1
      count_ge "$out" "line:" 1 "swift line fields" || ok=1
      count_ge "$out" "symbol:" 6 "swift symbol fields" || ok=1
      ;;
    elixir_*)
      count_ge "$out" "\\(elixir_frame" 6 "elixir frames" || ok=1
      count_ge "$out" "file:" 6 "elixir file fields" || ok=1
      count_ge "$out" "line:" 6 "elixir line fields" || ok=1
      count_ge "$out" "symbol:" 6 "elixir symbol fields" || ok=1
      ;;
    generic_*)
      count_ge "$out" "\\(fallback_file_(colon|paren|line)" 4 "fallback frames" || ok=1
      count_ge "$out" "file:" 4 "fallback file fields" || ok=1
      count_ge "$out" "line:" 4 "fallback line fields" || ok=1
      ;;
    *)
      count_ge "$out" "file:" 1 "at least one file field" || ok=1
      count_ge "$out" "line:" 1 "at least one line field" || ok=1
      ;;
  esac

  return $ok
}

echo "[parse-examples] using: $TS_BIN"
echo "[parse-examples] fixtures: ${#files[@]}"
mkdir -p "$LOG_DIR"

for f in "${files[@]}"; do
  echo
  echo "==> $f"
  out="$($TS_BIN parse "$f" 2>&1)"
  status=$?
  base="$(basename "$f")"
  log_file="$LOG_DIR/${base}.log"
  printf "%s\n" "$out" > "$log_file"

  if [ $status -ne 0 ]; then
    echo "FAIL  parser returned non-zero status"
    echo "      log: $log_file"
    failures=$((failures + 1))
    continue
  fi

  if grep -q "(ERROR" <<<"$out"; then
    summary="$(grep -m1 -o '(ERROR [^)]*)' <<<"$out" || true)"
    [ -n "$summary" ] || summary="contains ERROR nodes"
    echo "FAIL  $summary"
    echo "      log: $log_file"
    failures=$((failures + 1))
    continue
  fi

  if run_checks "$base" "$out"; then
    echo "PASS"
  else
    echo "FAIL  missing expected fields"
    echo "      log: $log_file"
    failures=$((failures + 1))
  fi
done

echo
if [ $failures -eq 0 ]; then
  echo "[parse-examples] all fixtures passed parse + field assertions"
  exit 0
fi

echo "[parse-examples] failures: $failures"
exit 1
