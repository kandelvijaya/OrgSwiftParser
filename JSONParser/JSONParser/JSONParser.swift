//
//  JSONParser.swift
//  JSONParser
//
//  Created by Vijaya Prakash Kandel on 4/1/18.
//  Copyright © 2018 Vijaya Prakash Kandel. All rights reserved.
//

import Foundation
import ParserCombinator


public enum JSONValue {
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

let jUnescapedChar = satisfy({ $0 != Character("\\") && $0 != Character("\"") }, label: "char")

let escapedChars: [(String, Character)] = [
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
    let jChars = [jEscapedChars, jUnescapedChar, jUnicodeChars] |> choice |> many
    let parser = quote >>- jChars ->> quote
    return parser |>> { String($0) }
}


func jString() -> Parser<JSONValue> {
    // Main string parser
    var jStringQuoted: Parser<JSONValue> {
        return jStringQuotedRaw() |>> { JSONValue.string($0) } <?> "Quoted String"
    }
    
    return jStringQuoted
}

var parserLookup = MutualRecursionForwardReference<Parser<JSONValue>>(with: jNull())

// MARK:- The entire json parser
func jsonParser() -> Parser<JSONValue> {
    let parser = [jNull(), jBool(), jNumber(), jString(), jArray(), jObject()]
        |> choice
        <?> "JSON item"
    return parser
}

// MARK:- json Array parser
func jArray() -> Parser<JSONValue> {
    let left = pchar("[")
    let right = pchar("]")
    let ws = pwhitespace |> many
    let comma = pchar(",")
    
    let value = Parser<JSONValue> { inp in
        return parserLookup.currentValue() |> run(inp)
    }
    
    let wsValue = (ws >>- value ->> ws)
    let wsValueComma = wsValue ->> comma |> many
    
    // Array can be empty []
    let arrValue = (wsValueComma ->>- wsValue) |> optional
    
    let parser = left >>- arrValue ->> right
        |>> { got in got.map { $0.0 + [$0.1] } ?? [] }
        |>> { JSONValue.array($0) }
    return parser <?> "JSON Array"
}

var ws: Parser<[Character]> {
    return whitespacces.map(pchar) |> choice |> many
}

// MARK:- JSON Object parser
func jObject() -> Parser<JSONValue> {
    let open = pchar("{")
    let close = pchar("}")
    let key = jStringQuotedRaw()
    let colon = pchar(":")
    
    let parser = Parser<JSONValue> { inp in
        return parserLookup.currentValue() |> run(inp)
    }
    
    let wsKey = ws >>- key ->> ws
    let wsValue = ws >>- parser ->> ws
    
    let keyValue1 = (wsKey ->> colon) ->>- wsValue
    
    let kvmCommas = (keyValue1 ->> pchar(",")) |> many
    let kvm = kvmCommas ->>- keyValue1 |>> { $0 + [$1] }
    
    let objectMatcher = open >>- kvm ->> close
    
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



public func pjson() -> Parser<JSONValue> {
    let parser = jsonParser()
    parserLookup.forwardReference(to: jsonParser())
    return parser
}
