import Foundation

public func choice<T>(_ parsers: [Parser<T>]) -> Parser<T> {
    return parsers.foldl1(by: <|>)!
}

public func anyOf(_ string: String) -> Parser<Character> {
    return string.map(pchar) |> choice
}


public let allChars = "abcdefghijklmnopqrstuvwxyz"
public let digits = "0123456789"
public let whitespacces = ["\t", " "]
assert(allChars.count == 26)

public let plowercase = allChars.lowercased() |> anyOf
public let puppercase = allChars.uppercased() |> anyOf
public let pdigit = digits |> anyOf |>> {Int(String($0))!}
public let pwhitespace = whitespacces.joined() |> anyOf




/// Test site
let aChar = pchar(Character("a"))
//aChar.run("allo")
//aChar.run("ball")

let bChar = pchar(Character("b"))
let lChar = pchar(Character("l"))

let aballaChar = aChar.andThen(bChar).andThen(aChar).andThen(lChar).andThen(lChar).andThen(aChar)
aballaChar.run("aballa")
aballaChar.run("vijaya")

let aballaCharArr = [aChar, bChar, aChar ,lChar, lChar, aChar]

let intParser = "1234567890".map(pchar)

let intParserSequenced = intParser.foldl1(by: Parser.orElse)
let intP = intParserSequenced.flatMap{ par in par.map{ Int(String($0)) } }
intParserSequenced?.run("123")

aChar.andThen(intP!).run("a1")



let aOrb = aChar.orElse(bChar)
aOrb.run("a cat")
aOrb.run("ball")
aOrb.run("vall")

aballaCharArr
sequenceOutput(aballaCharArr).run("aballa")
// aballaChar.run("aballa")
sequenceOutput([Parser<Character>]()).run("aballa")
"0123456789".map(pchar).foldl1(by: <|>)!.run("1")

pstring("hello").run("hello there")


pquotedString("hello").run("\"hello\" there ")
pquotedString("hello") <|> pquotedString("hi")







let lines = """
            * This is a headline
            This are the conetent.
            This is another content.
            ** This is sub heading
            This is subheading's content.
            * This is next heading1
            ** This is next heading 1's subheading
            *** This is h3.
            """


let newLineMatcher = pchar(Character("\n")) |>> { String($0) }
let starMatcher = pchar(Character("*")) |>> {String($0)}
let whitespaceMatcher = pstring(" ") <|> pstring("\t")
let headingMatcher = starMatcher ->> whitespaceMatcher

headingMatcher.run(lines)










