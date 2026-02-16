import Foundation

func extractEventId(from raw: String) -> String {
    if let range = raw.range(of: "/event/") {
        let after = raw[range.upperBound...]
        if let q = after.firstIndex(of: "?") {
            return String(after[..<q])
        }
        return String(after)
    }
    return raw
}

func isValidHttpsUrl(_ urlString: String) -> Bool {
    guard let url = URL(string: urlString),
          let scheme = url.scheme,
          let host = url.host
    else {
        return false
    }
    return scheme == "https" && !host.isEmpty
}
