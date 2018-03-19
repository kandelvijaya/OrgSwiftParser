import Foundation

// Not using typealias as it cannot be extended
// typealias Parser<T> = (String) -> (T, String)

// Q: Is it better to model parser with 2 generic types: Input, Output
public struct Parser<Output> {
    public typealias Stream = String
    public typealias RemainingStream = Stream
    public typealias ParsedOutput = Result<(Output, RemainingStream)>
    
    public let parse: (Stream) -> ParsedOutput
    var label: ParserError.Label? = nil
    
    public init(parse: @escaping (Stream) -> ParsedOutput) {
        self.parse = parse
    }
    
    public init(parse: @escaping (Stream) -> ParsedOutput, label: String) {
        self.parse = parse
        self.label = label
    }
    
}


public func labelParser<T>(_ parser: Parser<T>, _ label: String) -> Parser<T> {
    return Parser<T>.init(parse: parser.parse, label: label)
}

infix operator <?>: ApplicationPrecedenceGroup
public func <?><T>(_ parser: Parser<T>, _ label: String) -> Parser<T> {
    return labelParser(parser, label)
}


/// InputStream to run the parser against.
///
/// - Parameter input: The parser to use to match.
/// - Returns: Result<(Output, RemainingStream)>
public func run<T>(_ input: Parser<T>.Stream) -> (Parser<T>) -> Parser<T>.ParsedOutput {
    return { parser in
        return parser.parse(input)
    }
}

