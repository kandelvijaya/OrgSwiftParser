import Foundation



/// Parser to match a single character.
///
/// - Parameter charToMatch: Character
/// - Returns: Parser<Character>
public func pchar(_ charToMatch: Character) -> Parser<Character> {
    return Parser { str in
        guard let char = str.first else {
            return .failure("stream is empty")
        }
        guard char == charToMatch else {
            return .failure("Expected \(charToMatch) but got \(char)")
        }
        let remaining = String(str.dropFirst())
        return .success((char, remaining))
    }
    
}


/// Gets a parser that matches any of the character in the string.
///
/// - Parameter string: String
/// - Returns: Parser<Character>
public func anyOfChar(_ string: String) -> Parser<Character> {
    return string.map(pchar) |> choice
}


/// Parser to match a provided String
///
/// - Parameter match: String
/// - Returns: Parser<String>
public func pstring(_ stringToMatch: String) -> Parser<String> {
    return stringToMatch.map(pchar) |> sequenceOutput |>> { String($0) }
}


/// Match a quoted string. It will fail to match a string that
/// doesnot have doublequotes around.
///
/// - Parameter match: String containing double quotes
/// - Returns: Parser<String>
public func pquotedString(_ match: String) -> Parser<String> {
    let quoteMatcher = pchar("\"") |>> { String($0) }
    return quoteMatcher >>- pstring(match) ->> quoteMatcher
}

