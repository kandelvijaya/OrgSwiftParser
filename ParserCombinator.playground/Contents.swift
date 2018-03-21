import Foundation

"xyz"

enum JSONValue {
    case null
    case bool(Bool)
    case number(Float)
    case string(String)
    case object([String: JSONValue])
    case array([JSONValue])
}



let quote = pchar(Character("\""))

let jNull = quote >>- pstring("null") ->> quote |>> {_ in JSONValue.null } <?> "Null"


let jtrue = quote >>- pstring("true") ->> quote |>> {_ in JSONValue.bool(true) }
let jfalse = quote >>- pstring("false") ->> quote |>> {_ in JSONValue.bool(false) }

let jBool =  jtrue <|> jfalse  <?> "Boolean"
let jFloat = pfloat <|> (pint |>> { Float($0) }) <?> "Number"


var pjson: Parser<JSONValue> {
    return jNull <|> jBool
}

/* let[ + (oneManyWhiteSpace + jValue + oneManyWhiteSpace + comma)oneOrMany + oneManyWhiteSpace + jValue + onManyWhiteSpace + right] */
var jArr: Parser<[JSONValue]> {
    let left = pchar("[")
    let right = pchar("]")
    let ws = pwhitespace |> many
    let comma = pchar(",")
    let value = pjson
    let wsValue = ws >>- value ->> ws
    let commaValue =  comma >>- wsValue
    
    let parser = left >>- wsValue ->>- commaValue ->> right |>> { [$0.0, $0.1] }
    
    return parser
}


// Parsing JSON String

let jUnescapedChar = satisfy({ $0 != Character("\\") || $0 != Character("\"")}, label: "char")
let  escapedChars: [(String, Character)] = [
    // (stringToMatch, resultChar)
    ("\\\"","\""),      // quote
    ("\\\\","\\"),      // reverse solidus
    ("\\/","/"),        // solidus
    
    //TODO: How to represent formfeed and backspace
//    ("\\b","b"),       // backspace
//    ("\\f","f"),       // formfeed
//
    ("\\n","\n"),       // newline
    ("\\r","\r"),       // cr
    ("\\t","\t"),       // tab
]

let jEscapedChars = escapedChars.map { (string, char) in
    return pstring(string) |>> {_ in char }
} |> choice <?> "escaped char"


var jUnicodeChars: Parser<Character> {
    let unicodeCharReps = digits + "abcdef" + "abcdef".uppercased()
    let backspace = pchar("\\")
    let uchar = pchar("u")
    let unicdeChar1 = unicodeCharReps.map(pchar) |> choice
    func repeatP<T>(_ parser: Parser<T>, times: Int) -> Parser<[T]> {
        let pa = Array<Parser<T>>(repeating: parser, count: times)
        return sequenceOutput(pa)
    }

    
    let p = (backspace ->>- uchar) >>- repeatP(unicdeChar1, times: 4) |>> { _ in
        //let strRep = "U+" + String($0)
        // TODO Convert unicode rep to swift character
        return Character(" ")
    }
    return p
}


var jStringQuoted: Parser<JSONValue> {
    let quote = pchar("\"") <?> "quote"
    let jChar = jEscapedChars <|> jUnescapedChar <|> jUnicodeChars
    let parser = quote >>- jChar |> many ->> quote
    return parser |>> { JSONValue.string(String($0)) } <?> "Quoted String"
}


// Parsing JSON Number

