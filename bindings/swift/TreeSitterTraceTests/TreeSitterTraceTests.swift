import XCTest
import SwiftTreeSitter
import TreeSitterTrace

final class TreeSitterTraceTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_trace())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Trace grammar")
    }
}
