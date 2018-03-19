import Foundation

// Not using typealias as it cannot be extended
// typealias Parser<T> = (String) -> (T, String)

// Q: Is it better to model parser with 2 generic types: Input, Output
public struct Parser<Output> {
    public typealias Stream = String
    public typealias RemainingStream = Stream
    public typealias ParsedOutput = Result<(Output, RemainingStream)>
    
    public let parse: (Stream) -> ParsedOutput
    
    public init(parse: @escaping (Stream) -> ParsedOutput) {
        self.parse = parse
    }
}


/// We will defer the input until the very end
/// because we won't apply it from the very start
/// and we might not have input at the begining
/// In the end, input is provided by run(:) function.
public func run<T>(_ input: Parser<T>.Stream) -> (Parser<T>) -> Parser<T>.ParsedOutput {
    return { parser in
        return parser.parse(input)
    }
}

