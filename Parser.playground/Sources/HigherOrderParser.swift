import Foundation

public var allAlphabets: String{
  let temp = "abcdefghijklmnopqrstuvwxyz"
    assert(temp.count == 26)
    return temp
}

public let digits = "0123456789"
public let whitespacces = ["\t", " "]
public let plowercase = allAlphabets.lowercased() |> anyOfChar
public let puppercase = allAlphabets.uppercased() |> anyOfChar
public let pdigit = digits |> anyOfChar |>> {Int(String($0))!}
public let pwhitespace = whitespacces.joined() |> anyOfChar

/// Parser for signed and unsigned Int
public var pint: Parser<Int> {
    let pminus = pchar("-")
    let optSignedInt = pminus |> optional ->>- digits |> anyOfChar |> many1 |>> { Int(String($0))! }
    return optSignedInt |>> { (charO, int) in
        return charO.map{_ in -int } ?? int
    }
}
