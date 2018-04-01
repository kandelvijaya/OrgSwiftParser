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

final class MutualRecursionForwardReference<T> {
    var recursion_lookup_table: [String: T] = [:]
    private let key = "Key"
    
    /// Initialize with initial reference
    init(with initialReference: T) {
        recursion_lookup_table[key] = initialReference
    }
    
    /// When the mutual recursive defination expression is done
    /// assign the eventual value to be used.
    func forwardReference(to eventualReference: T) {
        recursion_lookup_table[key] = eventualReference
    }
    
    /// retrieve reference
    func currentValue() -> T {
        return recursion_lookup_table[key]!
    }
}

var parserLookup: MutualRecursionForwardReference<Parser<JSONValue>>!
parserLookup = MutualRecursionForwardReference(with: jNull())

// MARK:- The entire json parser
func jsonParser() -> Parser<JSONValue> {
    return [jNull(), jBool(), jNumber(), jString(), jArray() , jObject()]
        |> choice <?> "JSON item"
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
    
    /// This doesnot work. Why??????
    // let parser = parserLookup.currentValue()
    
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


parserLookup.forwardReference(to: jsonParser())

// MARK:-  Test site

let inputJSONString = "{\n\t\"created_at\": \"Thu Jun 22 21:00:00 +0000 2017\",\n\t\"id\": 877994604561387500,\n\t\"id_str\": \"877994604561387520\",\n\t\"text\": \"Creating a Grocery List Manager Using Angular, Part 1: Addamp; Display Items https://t.co/xFox78juL1 #Angular\",\n\t\"truncated\": false,\n\t\"entities\": {\n\t\t\"hashtags\": [{\n\t\t\t\"text\": \"Angular\",\n\t\t\t\"indices\": [103, 111]\n\t\t}],\n\t\t\"symbols\": [12],\n\t\t\"user_mentions\": [],\n\t\t\"urls\": [{\n\t\t\t\"url\": \"https://t.co/xFox78juL1\",\n\t\t\t\"expanded_url\": \"http://buff.ly/2sr60pf\",\n\t\t\t\"display_url\": \"buff.ly/2sr60pf\",\n\t\t\t\"indices\": [79, 102]\n\t\t}]\n\t},\n\t\"source\": \"<a href=\\\"http://bufferapp.com\\\" rel=\\\"nofollow\\\">Buffer</a>\",\n\t\"user\": {\n\t\t\"id\": 772682964,\n\t\t\"id_str\": \"772682964\",\n\t\t\"name\": \"SitePoint JavaScript\",\n\t\t\"screen_name\": \"SitePointJS\",\n\t\t\"location\": \"Melbourne, Australia\",\n\t\t\"description\": \"Keep up with JavaScript tutorials, tips, tricks and articles at SitePoint.\",\n\t\t\"url\": \"http://t.co/cCH13gqeUK\",\n\t\t\"entities\": {\n\t\t\t\"url\": {\n\t\t\t\t\"urls\": [{\n\t\t\t\t\t\"url\": \"http://t.co/cCH13gqeUK\",\n\t\t\t\t\t\"expanded_url\": \"http://sitepoint.com/javascript\",\n\t\t\t\t\t\"display_url\": \"sitepoint.com/javascript\",\n\t\t\t\t\t\"indices\": [0, 22]\n\t\t\t\t}]\n\t\t\t},\n\t\t\t\"description\": {\n\t\t\t\t\"urls\": []\n\t\t\t}\n\t\t},\n\t\t\"protected\": false,\n\t\t\"followers_count\": 2145,\n\t\t\"friends_count\": 18,\n\t\t\"listed_count\": 328,\n\t\t\"created_at\": \"Wed Aug 22 02:06:33 +0000 2012\",\n\t\t\"favourites_count\": 57,\n\t\t\"utc_offset\": 43200,\n\t\t\"time_zone\": \"Wellington\"\n\t}\n}"

let inputJSONparser = jsonParser() |> run(inputJSONString)



/// JSONValue to [String: JSONValue]

extension JSONValue {
    
    func typedValue() -> Any? {
        switch self {
        case .null:
            return nil
        case let .bool(booleanV):
            return booleanV
        case let .string(str):
            return str
        case let .number(n):
            return n
        case let .array(arr):
            return arr.compactMap { $0.typedValue() }
        case .object:
            return self.toDict()
        }
    }
    
    func toDict() -> [String: Any]? {
        guard case let .object(obj) = self else {
            return nil
        }
        
        var final = [String: Any]()
        obj.map {
            return ($0.key, $0.value.typedValue())
        }.reduce(into: final) {
            if let value = $1.1 {
                final[$1.0] = value
            }
        }
        return final
    }
    
    subscript(keypath: String) -> Any? {
        get {
            let pathComponents = keypath.split(separator: ".").map(String.init)
            return JSONValue.retrieveValue(from: self, withPaths: pathComponents)
        }
        set {
            assertionFailure("Cannot set on JSONValue")
        }
    }
    
    private static func retrieveValue(from json: JSONValue, withPaths pathsInOrder: [String])  -> Any?{
        guard let first = pathsInOrder.first else {
            return json.typedValue()
        }
        let remainingPaths = Array(pathsInOrder.dropFirst())
        
        let firstAsArrayIndex: Int? = (pint |> run(first)).value()?.0
        
        switch (json, firstAsArrayIndex) {
        // when keypath is a integer it means use this index item of array
        case let (.array(items), int?):
            guard int < items.count else { return nil }
            return retrieveValue(from: items[int], withPaths: remainingPaths)
        // when keypath is not an integer; its a object key value lookup
        case let (.object(dict), nil):
            guard let thisOne = dict["\(first)"] else {
                return nil
            }
            return retrieveValue(from: thisOne, withPaths: remainingPaths)
        default:
            // Amy other types besides object can't contain dict values to subscript directly
            return nil
        }
    }
    
}


//let jsonValue = inputJSONparser.value()!.0
//let createdAt = jsonValue["created_at"]
//print(createdAt)
//
//let entitiesUrlURLs = jsonValue["user.entities.url.urls.0.url"]
//print(entitiesUrlURLs)




private func retrieveValue(from json: JSONValue, withPaths pathsInOrder: [String])  -> Any?{
    guard let first = pathsInOrder.first else {
        return json.typedValue()
    }
    let remainingPaths = Array(pathsInOrder.dropFirst())
    
    let firstAsArrayIndex: Int? = (pint |> run(first)).value()?.0
    
    switch (json, firstAsArrayIndex) {
    // when keypath is a integer it means use this index item of array
    case let (.array(items), int?):
        guard int < items.count else { return nil }
        return retrieveValue(from: items[int], withPaths: remainingPaths)
    // when keypath is not an integer; its a object key value lookup
    case let (.object(dict), nil):
        guard let thisOne = dict["\(first)"] else {
            return nil
        }
        return retrieveValue(from: thisOne, withPaths: remainingPaths)
    default:
        // Amy other types besides object can't contain dict values to subscript directly
        return nil
    }
}

struct OutlineHeading {
    let title: String
    let depth: Int
}

enum OrgFileLine {
    case line(String)
    case heading(OutlineHeading)
}

struct Outline {
    let heading: OutlineHeading
    let content: [String]
    let subItems: [Outline]
    
    init(heading: OutlineHeading, content: [String], subItems: [Outline] = []) {
        self.heading = heading
        self.content = content
        self.subItems = subItems
    }
}


enum OrgFile {
    case outline(Outline)
    case tree([OrgFile])
}


/*
 This could also be represented as
 enum Outline {
    case tree(heading: String, content: [String], subTrees: [Outline])
 }
 */

let pstars = pchar("*") |> many1
let anyCharacterBesidesNewLine = satisfy({ $0 != Character("\n") }, label: "Except New Line")
let newLine = pchar("\n") |> many1

func headingParser() -> Parser<OutlineHeading> {
    let p = (pstars ->> (pchar(" ") |> many1)) ->>- (anyCharacterBesidesNewLine |> many1) ->> newLine
    let pH = p |>> { OutlineHeading(title: String($1), depth: $0.count) }
    return pH <?> "Org Heading"
}

func headingParser(depth: Int) -> Parser<OutlineHeading> {
    let depthStars = Array<Parser<Character>>(repeating: pchar("*"), count: depth) |> sequenceOutput
    let p = (depthStars ->> (pchar(" ") |> many1)) ->>- (anyCharacterBesidesNewLine |> many1) ->> newLine
    let pH = p |>> { OutlineHeading(title: String($1), depth: $0.count) }
    return pH <?> "Org Heading"
}

/// Run the parser Parser<U> unless the next stream is satisfied with Parser<T>
func parseUntil<T,U>(_ next: Parser<T>) -> (Parser<U>) -> Parser<[U]> {
    return { useParser in
        return Parser<[U]> { input in
            
            var fedInput = input
            var accumulatorResult = [U]()
            while fedInput.currentLine != InputState.EOF, let _ = (next |> run(fedInput)).error() {
                if let thisValue = (useParser |> run(fedInput)).value() {
                    accumulatorResult.append(thisValue.0)
                    fedInput = thisValue.1
                } else {
                    // neither thisParser Matched nor the next
                    return [useParser] |> sequenceOutput |> run(fedInput)
                }
            }
            
            let out = (accumulatorResult, fedInput)
            return .success(out)
        }
    }
}


func contentParser() -> Parser<[String]> {
    let anyContent = (anyCharacterBesidesNewLine |> many1) ->> newLine |>> {String($0)}
    let manyLines = anyContent |> parseUntil(headingParser())
    return manyLines <?> "Org Content"
}


let realEmacsOrg =
"""
"""

let str =   """
            * 2018/04/01 Task
            ** Q1:
            *** TODO: Work on Org Parser
            - list item 1
            - list item 2
            *** This is H1 -> H2 -> H3
            - list item H3
            - list item H3 2
            ** This is H1 -> H2Second
            - list item 1 H2 second
            - list item 2 H2 second
            ** This is H1 -> H2 Three
            - list item 1 H2 3
            - list item 2 H2 3
            *** This is H1 -> H2 4 -> H3
            - list item 1
            - list item 2
            """

let strWithSub =   """
            * B This is another heading H1 without content
            ** This is B's subheading
            - list item 1
            - list item 2
            """
let strC =   """
            This is the content line 1
            This is content line 2
            * B This is another heading H1 without content
            """
let strWithoutContent =  """
            * This is the content line 1
            This is content line 2
            * B This is another heading H1 without content
            """

func outlineParser() -> Parser<Outline> {
    let parser = headingParser() ->>- contentParser() |>> { Outline(heading: $0, content: $1) }
    return parser
}

func outlineParser(for level: Int) -> Parser<Outline> {
    return headingParser(depth: level)
        ->>- contentParser()
        |>> { Outline(heading: $0, content: $1) }
}

func orgOutlineParser() -> Parser<OrgFile> {
    return outlineParser() |>> { OrgFile.outline($0) }
}


func orgParser(start from: Int = 1) -> Parser<Outline> {
    typealias Output = Result<(Outline, Parser<Outline>.RemainingStream)>
    return Parser<Outline> { input in
        let thisLevel = outlineParser(for: from) |> run(input)
        let mapped: Output = thisLevel.flatMap { v in
            let nextRun = orgParser(start: from + 1) |> many |> run(v.1)
            
            let inner: Output = nextRun.map { subV in
                let output = Outline(heading: v.0.heading, content: v.0.content, subItems: subV.0)
                return (output, subV.1)
            }
            return inner
        }
        return mapped
    }
}








let orgParsed = orgParser() |> many |> run(realEmacsOrg)
orgParsed |> log
let firstItem = orgParsed.value()!.0[0]
let secondItem = orgParsed.value()!.0[1]

firstItem.heading.title
secondItem.heading.title
secondItem.subItems.count
firstItem.subItems.count







func log(_ a: Any) {
    print(a)
}

struct OrgTreeModel {
    let heading: OutlineHeading
    let content: [String]
    let subItems: [OrgTreeModel]
}

struct OrgFileModel {
    let outlines: [OrgTreeModel]
}



