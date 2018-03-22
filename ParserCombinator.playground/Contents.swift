import Foundation


enum JSONValue {
    case null
    case bool(Bool)
    case number(Float)
    case string(String)
    case object([String: JSONValue])
    case array([JSONValue])
}



let quote = pchar(Character("\""))




// MARK:- null parser
// Are js null quoted? or not?
func jNull() -> Parser<JSONValue> {
  return quote >>- pstring("null") ->> quote |>> {_ in JSONValue.null } <?> "Null"
}




// MARK:- Boolean parser
// Can boolean be uppercased or not?
func jBool() -> Parser<JSONValue> {
    let jtrue = quote >>- pstring("true") ->> quote |>> {_ in JSONValue.bool(true) }
    let jfalse = quote >>- pstring("false") ->> quote |>> {_ in JSONValue.bool(false) }
    return jtrue <|> jfalse  <?> "Boolean"
}




// MARK:- Number parser
// We convert number to Float
func jNumber() -> Parser<JSONValue> {
    let jFloat = pfloat <|> (pint |>> { Float($0) }) |>> { JSONValue.number($0) } <?> "Number"
    return jFloat
}



// MARK:- The entire json parser
func jsonParser() -> Parser<JSONValue> {
    return [jNull(), jNumber(), jString(), jArray(), jObject()] |> choice
}



// MARK:- json Array parser
func jArray() -> Parser<JSONValue> {
    let left = pchar("[")
    let right = pchar("]")
    let ws = pwhitespace |> many
    let comma = pchar(",")
    let value = jsonParser()
    let wsValue = (ws >>- value ->> ws)
    let wsValueComma = wsValue ->> comma |> many
    
    let parser = left >>- wsValueComma ->>- wsValue ->> right |>> { $0.0 + [$0.1] } |>> { JSONValue.array($0) }
    
    return parser <?> "JSON Array"
}


// MARK:- JSON String parser

func jStringQuotedRaw() -> Parser<String> {
    let quote = pchar("\"") <?> "quote"
    let jChar = jEscapedChars <|> jUnescapedChar <|> jUnicodeChars
    let parser = quote >>- jChar |> many ->> quote
    return parser |>> { String($0) }
}

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
    return p <?> "Unicode character"
}


func jString() -> Parser<JSONValue> {
    // Main string parser
    var jStringQuoted: Parser<JSONValue> {
        return jStringQuotedRaw() |>> { JSONValue.string($0) } <?> "Quoted String"
    }
    
    return jStringQuoted
}


// MARK:- JSON Object parser
func jObject() -> Parser<JSONValue> {
    let open = pchar("{")
    let close = pchar("}")
    let key = jStringQuotedRaw()
    let colon = pchar(":")
    let whiteSpace = whitespacces.map(pchar) |> choice |> many
    
    let wsKey = whiteSpace >>- key ->> whiteSpace
    let wsValue = whiteSpace >>- jsonParser() ->> whiteSpace
    
    let keyValue1OrMany = (wsKey ->> colon) ->>- wsValue |> many1
    

    func kvm() -> Parser<[(String, JSONValue)]> {
        print("asking for kvm")
        return keyValue1OrMany
    }
    //    let objectMatcher = open >>- keyValue1OrMany ->> close
    let objectMatcher = open >>- kvm() ->> close
    
    return objectMatcher.map { inp in
        let x = inp.map { [$0.0 : $0.1 ]}.reduce([String: JSONValue](), +)
        return JSONValue.object(x)
    } <?> "JSON Object"
}

/// Addition on Dictionaries. Prefer rhs when duplicate
func +<T,U>(_ lhs: [T:U], _ rhs: [T:U]) -> [T:U] {
    var x = Dictionary<T,U>()
    lhs.forEach { key, value in
        x[key] = value
    }
    rhs.forEach { key, value in
        x[key] = value
    }
    return x
}



// Test site

jNumber() |> run("123")
jNumber() |> run("-123")
jNumber() |> run("123.12")
jNumber() |> run("-123.12")
let bunchOfArr = "[\"true\", \"true\", \"false\", \"null\", 123.0 ]"
//let boolsArr = jArr |> run(bunchOfArr) |> show


//jObject //|> run(bunchOfArr) |> show

jsonParser()
