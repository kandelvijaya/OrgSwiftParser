import Foundation


// MARK:- primitive

public let digits = "0123456789"
public let whitespacces = ["\t", " "]
public let plowercase = allAlphabets.lowercased() |> anyOfChar <?> "lowercase alphabets"
public let puppercase = allAlphabets.uppercased() |> anyOfChar <?> "uppercase alphabets"
public let pdigit = digits |> anyOfChar |>> {Int(String($0))!} <?> "integers"
public let pwhitespace = whitespacces.joined() |> anyOfChar <?> "whitespaces"

public var allAlphabets: String{
    let temp = "abcdefghijklmnopqrstuvwxyz"
    assert(temp.count == 26)
    return temp
}


// MARK:- Still primitive but more than a character

/// Parser to match a single character.
///
/// - Parameter charToMatch: Character
/// - Returns: Parser<Character>
public func pchar(_ charToMatch: Character) -> Parser<Character> {
    return Parser { str in
        guard let char = str.first else {
            return .failure(error("character", "stream is empty"))
        }
        guard char == charToMatch else {
            return .failure(error("character", "Expected \(charToMatch) but got \(char)"))
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


/// Parser for signed and unsigned Int
public var pint: Parser<Int> {
    let pminus = pchar("-")
    let optSignedInt = pminus |> optional ->>- digits |> anyOfChar |> many1 |>> { Int(String($0))! }
    return optSignedInt |>> { (charO, int) in
        return charO.map{_ in -int } ?? int
    }
}
