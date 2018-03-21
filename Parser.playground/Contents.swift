import Foundation



//////////////////////////

func readAllChars(_ state: InputState) -> [Character] {
    let new = state.nextChar()
    switch new {
    case (let newState, let char?):
        return [char] + readAllChars(newState)
    case (_, nil):
        return []
    }
}


/// Test site
let aChar = pchar(Character("a"))
let bChar = pchar(Character("b"))
let lChar = pchar(Character("l"))

lChar <?> "lchar" |> run("peee") |> show

let aballaChar = aChar.andThen(bChar).andThen(aChar).andThen(lChar).andThen(lChar).andThen(aChar)
aballaChar |> run("aballa")
aballaChar |> run("vijaya")

let aballaCharArr = [aChar, bChar, aChar ,lChar, lChar, aChar]

let intParser = "1234567890".map(pchar)

let intParserSequenced = intParser.foldl1(by: Parser.orElse)
let intP = intParserSequenced.flatMap{ par in par.map { Int(String($0)) } }
intParserSequenced |?> run("123")

aChar.andThen(intP!) |> run("a1")



let aOrb = aChar.orElse(bChar)
aOrb |> run("a cat")
aOrb |> run("ball")
aOrb |> run("vall")

aballaCharArr
sequenceOutput(aballaCharArr) |> run("aballa")
// aballaChar.run("aballa")
sequenceOutput([Parser<Character>]()) |> run("aballa")
"0123456789".map(pchar).foldl1(by: <|>)! |> run("1")

pstring("hello") |> run("hello there")


pquotedString("hello") |> run("\"hello\" there ")
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

let input = InputState(from: lines)
let out = readAllChars(input).reduce("", { $0 + String($1)})
print(out)




let newLineMatcher = pchar(Character("\n")) |>> { String($0) }
let starMatcher = pchar(Character("*")) |>> {String($0)}
let whitespaceMatcher = pstring(" ") <|> pstring("\t")
let headingMatcher = starMatcher ->> whitespaceMatcher

headingMatcher |> run(lines)

(pchar("a") |> many) |> run("aale")

(pchar("a") |> many1) |> run("aale")
(pchar("b") |> many1) |> run("aale")
(pchar("a") |> many) |> run("ball")

pint |> run("123,")

let plineend = pchar("\n")

let anyCharP = anyOfChars(digits + allAlphabets)
let commaP = pchar(Character(","))

let commaSeparateCharP = separated1(anyCharP, by: commaP)
commaSeparateCharP |> run("#a1,2,3,4;+45")


many(commaP >>- anyCharP) |> run("ab")

let separatedBy = (anyCharP ->>- many(commaP >>- anyCharP)) |>> { [$0.0] + $0.1 }
separatedBy |> run("ab")


anyOfChars(digits) |> run("lamo") |> show


pfloat |> run("-123.0")
