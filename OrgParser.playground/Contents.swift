import UIKit

enum OrgTreeDepth: Int {
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case other
}

typealias OrgTreeTitle = String
typealias OrgTreeTag = String
typealias OrgTaskState = String
typealias OrgTreeContent = String

struct OrgTree {
    let level: OrgTreeDepth
    let title: OrgTreeTitle
    let subtrees: [OrgTree]
    
//    let tags: [OrgTreeTag]?
//    let taskState: OrgTaskState?
    
    let content: OrgTreeContent?
}

// Takes a file string and emits [line]
typealias Line = String
typealias FileContent = String

struct Parser<Input: ParserInput, Output> {
    typealias RemainingInput = Input
    let parse: (Input) -> (Output, RemainingInput)?
}

protocol ParserInput {
    var isCompletelyConsumed: Bool { get }
    var emptyState: Self { get }
}

extension Parser {
    
    var many: Parser<Input, [Output]> {
        return Parser<Input, [Output]> { input in
            var outputAccumulator: [Output] = []
            var remainder = input
            while let (out, rem) = self.parse(remainder) {
                outputAccumulator.append(out)
                remainder = rem
            }
            return (outputAccumulator, remainder)
        }
    }
}



extension Parser {
    
    func map<T>(_ transform: @escaping ((Output) -> T)) -> Parser<Input, T> {
        return Parser<Input, T> { input in
            guard let parsed = self.parse(input) else {
                return nil
            }
            let transformed = transform(parsed.0)
            return (transformed, parsed.1)
        }
    }
    
}

extension String: ParserInput {
    var isCompletelyConsumed: Bool {
        return self.isEmpty
    }
    
    var emptyState: String {
        return ""
    }
}

extension Array: ParserInput {
    var isCompletelyConsumed: Bool {
        return self.isEmpty
    }
    
    var emptyState: Array {
        return []
    }
}


let fileParser = Parser<String, Line> { str in
    let newLineString = "\n"
    guard let untilLineEnd = str.range(of: newLineString)?.lowerBound else {
        return (str, "")
    }
    let indexAfterNewline = str.index(untilLineEnd, offsetBy: newLineString.count)
    let thisline = Line(str[str.startIndex..<untilLineEnd])
    let remaining = String(str[indexAfterNewline..<str.endIndex])
    return (thisline, remaining)
}


let str = "hello there \n how are you \n"

fileParser.parse(str)


func line(_ condition: @escaping ((Line) -> Bool)) -> Parser<String, Line> {
    return Parser { str in
        
        let newLineString = "\n"
        guard !str.isEmpty else { return nil }
        
        guard let untilLineEnd = str.range(of: newLineString)?.lowerBound else {
            guard condition(str) else { return nil }
            return (str, "")
        }
        let indexAfterNewline = str.index(untilLineEnd, offsetBy: newLineString.count)
        let thisline = Line(str[str.startIndex..<untilLineEnd])
        let remaining = String(str[indexAfterNewline..<str.endIndex])
        
        guard condition(thisline) else { return nil }
        return (thisline, remaining)
    }
}

let parsed = line({_ in true }).parse(str)
parsed


let parsedC = line({ _ in true }).many.map({ $0 }).parse(str)
parsedC!

extension Line {
    
    var headingLevel: OrgTreeDepth? {
        let prefixChars = self.prefix { $0 == Character(" ") }
        let charsCount = prefixChars.count
        let headingMatcher = Array.init(repeating: "*", count: charsCount).joined()
        guard String(prefixChars) == headingMatcher else { return nil }
        let headingLevel = OrgTreeDepth(rawValue: charsCount)
        return headingLevel
    }
    
}

