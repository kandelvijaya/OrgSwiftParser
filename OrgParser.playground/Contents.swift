import Foundation
import ParserCombinator

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

func outlineParser() -> Parser<Outline> {
    return headingParser() ->>- contentParser() |>> { Outline(heading: $0, content: $1) }
}

func outlineParser(for level: Int) -> Parser<Outline> {
    return headingParser(depth: level) ->>- contentParser() |>> { Outline(heading: $0, content: $1) }
}

func orgParser(start startLevel: Int = 1) -> Parser<Outline> {
    typealias Output = ParserResult<(Outline, Parser<Outline>.RemainingStream)>
    return Parser<Outline> { input in
        let thisLevel = outlineParser(for: startLevel) |> run(input)
        let mapped: Output = thisLevel.flatMap { v in
            let nextLevel = startLevel + 1
            let nextRun = orgParser(start: nextLevel) |> many |> run(v.1)
            
            let inner: Output = nextRun.map { subV in
                let output = Outline(heading: v.0.heading, content: v.0.content, subItems: subV.0)
                return (output, subV.1)
            }
            return inner
        }
        return mapped
    }
}





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



func consoleOut(_ a: Any) {
    print(a)
}




func eventFileContent() -> String {
    guard let url = Bundle.main.url(forResource: "dailyEvents", withExtension: "org") else {
        return ""
    }
    return try! String(contentsOf: url)
}


let orgParsed = orgParser() |> many |> run(eventFileContent())
orgParsed |> consoleOut

orgParsed.value()?.0[0].heading.title
orgParsed.value()?.0[1].subItems.count


