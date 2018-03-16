import Foundation

// Not using typealias as it cannot be extended
// typealias Parser<T> = (String) -> (T, String)


enum Result<T> {
    case success(T)
    case failure(String)
    
    func map<U>(_ transform: (T) -> U) -> Result<U> {
        switch self {
        case let .success(v):
            return .success(transform(v))
        case let .failure(e):
            return .failure(e)
        }
    }
    
    func flatMap<U>(_ transform: (T) -> Result<U>) -> Result<U> {
        return Result.joined(map(transform))
    }
    
    static func joined<A>(_ input: Result<Result<A>>) -> Result<A> {
        switch input {
        case let .success(v):
            return v
        case let .failure(e):
            return .failure(e)
        }
    }
}

// Q: Is it better to model parser with 2 generic types: Input, Output
struct Parser<Output> {
    typealias Stream = String
    typealias RemainingStream = Stream
    typealias ParsedOutput = Result<(Output, RemainingStream)>
    
    var parse: (Stream) -> ParsedOutput
}


extension Parser {
    
    /// We will defer the input until the very end
    /// because we won't apply it from the very start
    /// and we might not have input at the begining
    /// In the end, input is provided by run(:) function.
    func run(_ input: Stream) -> ParsedOutput {
        return parse(input)
    }
    
}

/// Moving into Combinator territory
extension Parser {
    
    
    /// Perform first match and then perform second match
    /// with the remainder from first match. Error is propagated
    /// if something goes wrong in any place.
    ///
    /// - Parameter nextParser: Parser<T>
    /// - Returns: Parser<(Output, T)> is a combined parser.
    func andThen<T>(_ nextParser: Parser<T>) -> Parser<(Output,T)> {
        return Parser<(Output, T)> { input in
            let firstRun = self.run(input)
            switch firstRun {
            case let .success(v):
                let nextRun = nextParser.run(v.1)
                switch nextRun {
                case let .success(v2):
                    let value = ((v.0, v2.0), v2.1)
                    return .success(value)
                case let .failure(e):
                    return .failure(e)
                }
            case let .failure(e):
                return .failure(e)
            }
        }
    }
    
    /// Parses the input with the first parser, if that succeeds
    /// returns it. Else, feeds in the input to the second parser
    /// and uses its return value. Its like || condition.
    ///
    /// - Parameter otherParser: Parser
    /// - Returns: Parser representing the OR combined
    func orElse(_ otherParser: Parser) -> Parser {
        return Parser { input in
            let firstRun = self.run(input)
            switch firstRun {
            case let .success(v):
                return .success(v)
            case .failure:
                return otherParser.run(input)
            }
        }
    }
    
    static func orElse(firstParser: Parser, secondParser: Parser) -> Parser {
        return firstParser.orElse(secondParser)
    }
    
    
    /// Transforms the eventual type of the parser output
    /// Functorial
    ///
    /// - Parameter by: Output -> T
    /// - Returns: Parser<T>
    func map<T>(_ by: @escaping (Output) -> T) -> Parser<T> {
        return Parser<T> { input in
            let firstRun = self.run(input)
            switch firstRun {
            case let .success(v):
                let output = (by(v.0), v.1)
                return .success(output)
            case let .failure(e):
                return .failure(e)
            }
        }
    }
    
}



/// A Single character parser
/// Takes a satisfy function and test against each character in stream
func character(_ satisfy: @escaping (Character) -> Bool) -> Parser<Character> {
    
    return Parser { str in
        guard let char = str.first else {
            return .failure("stream is empty")
        }
        guard satisfy(char) else {
            return .failure("current character \(char) doesnot satisfy the rule")
        }
        let remaining = String(str.dropFirst())
        return .success((char, remaining))
    }
    
}


extension Array {
    
    func foldl(by: (Element, Element) -> Element) -> Element? {
        guard let first = self.first else {
            assertionFailure("foldl with empty list is programming error")
            return nil
        }
        let other = dropFirst()
        return other.reduce(first) { (result, item)in
            return by(result, item)
        }
    }

}


/// Test site
let aChar = character { $0 == Character("a") }
aChar.run("allo")
aChar.run("ball")

let bChar = character { $0 == Character("b") }
let lChar = character { $0 == Character("l") }

let aballaChar = aChar.andThen(bChar).andThen(aChar).andThen(lChar).andThen(lChar).andThen(aChar)
aballaChar.run("aballa")
aballaChar.run("vijaya")

let aballaCharArr = [aChar, bChar, lChar, lChar, aChar]

let intParser = "1234567890".map { int in  character{ $0 == int  } }

let intParserSequenced = intParser.foldl(by: Parser.orElse)
let intP = intParserSequenced.flatMap{ par in par.map{ Int(String($0)) } }
intParserSequenced?.run("123")

aChar.andThen(intP!).run("a1")



let aOrb = aChar.orElse(bChar)
aOrb.run("a cat")
aOrb.run("ball")
aOrb.run("vall")
