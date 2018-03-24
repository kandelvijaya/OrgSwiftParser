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
    let jtrue = optional(quote) >>- pstring("true") ->> optional(quote) |>> {_ in JSONValue.bool(true) }
    let jfalse = optional(quote) >>- pstring("false") ->> optional(quote) |>> {_ in JSONValue.bool(false) }
    return jtrue <|> jfalse  <?> "Boolean"
}




// MARK:- Number parser
// We convert number to Float
func jNumber() -> Parser<JSONValue> {
    let jFloat = pfloat <|> (pint |>> { Float($0) }) |>> { JSONValue.number($0) } <?> "Number"
    return jFloat
}


// MARK:- JSON String parser

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


func jStringQuotedRaw() -> Parser<String> {
    let quote = pchar("\"") <?> "quote"
    let jChar = jEscapedChars <|> jUnescapedChar <|> jUnicodeChars
    let parser = quote >>- jChar |> many ->> quote
    return parser |>> { String($0) }
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
    let parser = parserLookup.currentValue()
    
    let wsKey = whiteSpace >>- key ->> whiteSpace
    let wsValue = whiteSpace >>- parser ->> whiteSpace
    
    let keyValue1OrMany = (wsKey ->> colon) ->>- wsValue |> many1
    

    func kvm() -> Parser<[(String, JSONValue)]> {
        return keyValue1OrMany
    }
    //    let objectMatcher = open >>- keyValue1OrMany ->> close
    let objectMatcher = open >>- kvm() ->> close
    
    return objectMatcher.map { inp in
        let x = inp.map { [$0.0 : $0.1 ]}.reduce([String: JSONValue](), +)
        return JSONValue.object(x)
    } <?> "JSON Object"
}

final class MutualRecursionForwardReference<T> {
    
    var recursion_lookup_table: [String: T] = [:]
    private let key = "Key"
    
    init(with initialReference: T) {
        print("Forward reference initialized with \(initialReference)")
        recursion_lookup_table[key] = initialReference
    }
    
    func forwardReference(to eventualReference: T) {
        print("Forward reference evaluated to \(eventualReference)")
        recursion_lookup_table[key] = eventualReference
    }
    
    func currentValue() -> T {
        let value = recursion_lookup_table[key]
        print("forward reference obtined is \(value!)")
        return value as! T
    }
}

var parserLookup: MutualRecursionForwardReference<Parser<JSONValue>>!
parserLookup = MutualRecursionForwardReference(with: jNull())

// MARK:- The entire json parser
func jsonParser() -> Parser<JSONValue> {
    return [jNull(),
            jBool(),
            jNumber(),
            jString(),
            jArray(),
            jObject()] |> choice <?> "JSON Object"
}

// MARK:- json Array parser
func jArray() -> Parser<JSONValue> {
    let left = pchar("[")
    let right = pchar("]")
    let ws = pwhitespace |> many
    let comma = pchar(",")
    
    let value = parserLookup.currentValue()
    print("Obtained parser is \(value)")
    
    let wsValue = (ws >>- value ->> ws)
    let wsValueComma = wsValue ->> comma |> many
    let parser = left >>- wsValueComma ->>- wsValue ->> right |>> { $0.0 + [$0.1] } |>> { JSONValue.array($0) }
    return parser <?> "JSON Array"
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
let bunchOfArr = "[ \"true\", \"true\", \"false\", \"null\", 123.0 ]"


parserLookup.forwardReference(to: jsonParser())
jsonParser() |> run(bunchOfArr) |> show
