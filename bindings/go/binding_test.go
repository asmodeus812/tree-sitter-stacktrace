package tree_sitter_trace_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_trace "github.com/asmodeus812/tree-sitter-stacktrace.git/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_trace.Language())
	if language == nil {
		t.Errorf("Error loading Trace grammar")
	}
}
