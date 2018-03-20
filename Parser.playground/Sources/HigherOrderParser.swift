import Foundation


// MARK:- primitive

public let digits = "0123456789"
public let whitespacces = ["\t", " "]
public let plowercase = allAlphabets.lowercased() |> anyOfChar <?> "lowercase alphabets"
public let puppercase = allAlphabets.uppercased() |> anyOfChar <?> "uppercase alphabets"
public let pdigit = digits |> anyOfChar |>> {Int(String($0))!} <?> "Digits"
public let pwhitespace = whitespacces.joined() |> anyOfChar <?> "Whitespaces"

public var allAlphabets: String{
    let temp = "abcdefghijklmnopqrstuvwxyz"
    assert(temp.count == 26)
    return temp
}


// MARK:- Still primitive but more than a character

public func satisfy(_ predicate: @escaping (Character) -> Bool, label: Parser<Any>.Label) -> Parser<Character> {
    return Parser<Character> { str in
        guard let char = str.first else {
            return .failure(error(label, "stream is empty"))
        }
        guard predicate(char) else {
            return .failure(error(label, "Unexpected '\(char)'"))
        }
        let remaining = String(str.dropFirst())
        return .success((char, remaining))
        } <?> label
}


/// Parser to match a single character.
///
/// - Parameter charToMatch: Character
/// - Returns: Parser<Character>
public func pchar(_ character: Character) -> Parser<Character> {
    let predicate = { $0 == character}
    let label = "\(character)"
    return satisfy(predicate, label: label)
}


/// Gets a parser that matches any of the character in the string.
///
/// - Parameter string: String
/// - Returns: Parser<Character>
public func anyOfChar(_ string: String) -> Parser<Character> {
    return string.map(pchar) |> choice <?> "Any of \(string)"
}


/// Parser to match a provided String
///
/// - Parameter match: String
/// - Returns: Parser<String>
public func pstring(_ stringToMatch: String) -> Parser<String> {
    return stringToMatch.map(pchar) |> sequenceOutput |>> { String($0) } <?> stringToMatch
}

/// Given a list of same typed parsers, reduce them into single parser
/// In the process, sequencing the parsed output in order
/// In case of empty parsers input, we return a identity parser on []
///
/// - Parameter parsers: [Parser<T>]
/// - Returns: Parser<[T]>
public func sequenceOutput<T>(_ parsers: [Parser<T>]) -> Parser<[T]> {
    guard let first = parsers.first else {
        return Parser<[T]> { input in
            let output = ([T](), input)
            return .success(output)
        }
    }
    
    let others: Parser<[T]> = sequenceOutput(Array(parsers.dropFirst()))
    let firstMapped: Parser<[T]> = first |>> { [$0] }
    let andThenned = firstMapped.andThen(others)
    return andThenned |>> { $0.0 + $0.1 } <?> "Sequence of '\(parsers.reduce("", { $0 + $1.label}))'"
}



/// Match a quoted string. It will fail to match a string that
/// doesnot have doublequotes around.
///
/// - Parameter match: String containing double quotes
/// - Returns: Parser<String>
public func pquotedString(_ match: String) -> Parser<String> {
    let quoteMatcher = pchar("\"") |>> { String($0) }
    return quoteMatcher >>- pstring(match) ->> quoteMatcher <?> match
}


/// Parser for signed and unsigned Int
public var pint: Parser<Int> {
    let pminus = pchar("-")
    let optSignedInt = pminus |> optional ->>- digits |> anyOfChar |> many1 |>> { Int(String($0))! }
    return optSignedInt |>> { (charO, int) in
        return charO.map{_ in -int } ?? int
    } <?> "Integer"
}
