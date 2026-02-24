import Foundation

enum JSONExtractor {
    static func firstJSONObjectData(in text: String) -> Data? {
        guard let start = text.firstIndex(of: "{") else { return nil }

        var depth = 0
        var inString = false
        var escape = false

        var idx = start
        while idx < text.endIndex {
            let ch = text[idx]
            if inString {
                if escape {
                    escape = false
                } else if ch == "\\" {
                    escape = true
                } else if ch == "\"" {
                    inString = false
                }
            } else {
                if ch == "\"" {
                    inString = true
                } else if ch == "{" {
                    depth += 1
                } else if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        let slice = text[start...idx]
                        return Data(slice.utf8)
                    }
                }
            }
            idx = text.index(after: idx)
        }

        return nil
    }
}

