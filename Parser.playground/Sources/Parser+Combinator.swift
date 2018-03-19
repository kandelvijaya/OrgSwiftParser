import Foundation

// MARK:- Monadic Combinators. Most of the functions are free functions
// It is sometimes hard to comprehend free functions under composition with
// custom operator thereby associated instance method is provided.
// Refer to Parser+TypedMethpds.swift.
// Please note: typed methods are just a alias on the free function.


/// Map over the input Parser by supplied transform function.
/// This makes Parser Functor.
///
/// - Parameters:
///   - by: (T) -> U
///   - input: Parser<T>
/// - Returns: Parser<U>
public func map<T,U>(_ by: @escaping (T) -> U, to inParser: Parser<T>) -> Parser<U> {
    return Parser<U> { input in
        let firstRun = inParser |> run(input)
        switch firstRun {
        case let .success(v):
            let output = (by(v.0), v.1)
            return .success(output)
        case let .failure(e):
            return .failure(e)
        }
    }
}




/// How do we compose 2 function of type
/// f1: A -> Parser<B> , f2: B -> Parser<C>
/// This makes Parser Monadic. This is equivalent
/// to bind or >>= in Haskell.
///
/// - Parameters:
///   - inputValue: Parser<T>
///   - by: (T) -> Parser<U>
/// - Returns: Parser<U>
public func flatMap<T, U>(_ inputValue: Parser<T>, _ by: @escaping (T) -> Parser<U>) -> Parser<U> {
    return map(by, to: inputValue) |> join
}


/// Flattens a nested parsers into a single parser
/// Currently works on double layered input.
/// FIXME: Add support for n layers input with generics
///
/// - Parameter parser: Parser<Parser<T>>
/// - Returns: Parser<T>
public func join<T>(_ parser: Parser<Parser<T>>) -> Parser<T> {
    return Parser<T> { input in
        let outerRun = parser |> run(input)
        switch outerRun {
        case let .failure(e):
            return .failure(e)
        case let .success(value):
            let innerRun = value.0 |> run(value.1)
            return innerRun
        }
    }
}

/// Lifting function. Also known as return or pure in
/// functional programming languages
///
/// - Parameter output: T
/// - Returns: Parser<T> where output is prefilled
public func lift<T>(_ output: T) -> Parser<T> {
    return Parser<T> { input in
        let out = (output, input)
        return .success(out)
    }
}


/// Applicative apply. Applies the function stuck in wrapped parser to the
/// parser with concrete value. This makes Parser Applicative.
/// Monad are superior to applicative, however we will have this nice
/// apply in place.
/// This answers the question what if I have a normal parser Parser<T>
/// and another parser which has a function stuck inside Parser<(T -> U)>.
/// How can we compose them?
///
/// - Parameters:
///   - wrapped: Parser<(T->U)>
///   - parser: Parser<T>
/// - Returns: Parser<U>
public func applic<T,U>(_ wrapped: Parser<((T) -> U)>, to parser: Parser<T>) -> Parser<U> {
    return flatMap(wrapped) { map($0, to: parser) }
}



extension Parser {
    
    /// Perform first match and then perform second match
    /// with the remainder from first match. Error is propagated
    /// if something goes wrong in any place.
    ///
    /// - Parameter nextParser: Parser<T>
    /// - Returns: Parser<(Output, T)> is a combined parser.
    public func andThen<T>(_ nextParser: Parser<T>) -> Parser<(Output,T)> {
        return Parser<(Output, T)> { input in
            let firstRun = self |> run(input)
            switch firstRun {
            case let .success(v):
                let nextRun = nextParser |> run(v.1)
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
    
    public static func and<T,U>(_ first: Parser<T>, _ second: Parser<U>) -> Parser<(T,U)> {
        return first.andThen(second)
    }
    
    /// Parses the input with the first parser, if that succeeds
    /// returns it. Else, feeds in the input to the second parser
    /// and uses its return value. Its like || condition.
    ///
    /// - Parameter otherParser: Parser
    /// - Returns: Parser representing the OR combined
    public func orElse(_ otherParser: Parser) -> Parser {
        return Parser { input in
            let firstRun = self |> run(input)
            switch firstRun {
            case let .success(v):
                return .success(v)
            case .failure:
                return otherParser |> run(input)
            }
        }
    }
    
    public static func orElse(firstParser: Parser, secondParser: Parser) -> Parser {
        return firstParser.orElse(secondParser)
    }
    
    
    /// Parses using both but ignore the output from
    /// second parser.
    ///
    /// - Parameters:
    ///   - rhs: Parser<T>
    /// - Returns: Parser<T>
    public func keepLeft( _ rhs: Parser) -> Parser {
        return self.andThen(rhs) |>> { $0.0 }
    }
    
    
    /// Use both parses but ignore left's output
    ///
    /// - Parameters:
    ///   - rhs: Parser<T>
    /// - Returns: Parser<T>
    public func keepRight(_ rhs: Parser) -> Parser {
        return self.andThen(rhs) |>> { $0.1 }
    }
    
}


extension Array {
    
    /// Reduces the collection from left to right similar to reduce
    /// However, supplies the first argument as the initial result
    /// Useful, when either the Element doesnot have identity AKA is not a monoid.
    /// [1,2,3].foldl(by: +) rather than [1,2,3].reduce(0, +)
    ///
    /// - Parameter by: A function which will be supplied with result and next item
    /// - Returns: Accumulated result value OR Optional when the list is empty.
    public func foldl1(by: (Element, Element) -> Element) -> Element? {
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


/// Given a list of same typed parsers, reduce them into single parser
/// In the process, sequencing the parsed output in order
/// In case of empty parsers input, we return a identity parser on []
///
/// - Parameter parsers: [Parser<T>]
/// - Returns: Parser<[T]>
public func sequenceOutput<T>(_ parsers: [Parser<T>]) -> Parser<[T]> {
    guard let first = parsers.first else {
        return Parser<[T]> { input in
            let output = ([T](), input)
            return .success(output)
        }
    }
    
    let others: Parser<[T]> = sequenceOutput(Array(parsers.dropFirst()))
    let firstMapped: Parser<[T]> = first |>> { [$0] }
    let andThenned = firstMapped.andThen(others)
    return andThenned |>> { $0.0 + $0.1 }
}



/// Find the parser that works from the list
///
/// - Parameter parsers: [Parser<T>]
/// - Returns: Parser<T>
public func choice<T>(_ parsers: [Parser<T>]) -> Parser<T> {
    return parsers.foldl1(by: <|>)!
}


/// Matches using the parses as many times as possible.
/// The output will be sequenced into an array.
///
/// - Parameter parser: Parser<T>
/// - Returns: Parser<[T]>. This will be empty if there was no match.
public func many<T>(_ parser: Parser<T>)-> Parser<[T]> {
    return Parser<[T]> { input in
        return .success(parser.parseZeroOrMore(input))
    }
}


extension Parser {
    
    /// Parse the given input as many time as possible collecting the output.
    ///
    /// - Parameter input: Stream
    /// - Returns: ([Output], Stream)
    public func parseZeroOrMore(_ input: Stream) -> ([Output], Stream) {
        let thisRun = self |> run(input)
        switch thisRun {
        case .failure:
            return ([], input)
        case let .success(v):
            let (subsequentValues, remainder) = parseZeroOrMore(v.1)
            let values = [v.0] + subsequentValues
            return (values, remainder)
        }
    }
    
}


/// Parse given input 1 or more times
///
/// - Parameter parser: Parser<T>
/// - Returns: Parser<[T]>. If the parser matches none, it will error.
public func many1<T>(_ parser: Parser<T>) -> Parser<[T]> {
    return Parser<[T]> { input in
        let zeroOrMore = parser.parseZeroOrMore(input)
        guard !zeroOrMore.0.isEmpty else {
            return parser |>> { [$0] } |> run(input)
        }
        return .success(zeroOrMore)
    }
}


/// Match for optional existance. In case of match, the character is consumed as
/// like expected. When there is no, stream is not consumed.
///
/// - Parameter parser: Parser<T>
/// - Returns: Parser<T?>
public func optional<T>(_ parser: Parser<T>) -> Parser<T?> {
    return Parser<T?> { input in
        let thisRun = parser |> run(input)
        switch thisRun {
        case .failure:
            let out: (T?, Parser<Any>.RemainingStream) = (nil, input)
            return .success(out)
        case let .success(v):
            let out: (T?, Parser<Any>.RemainingStream) = (v.0, v.1)
            return .success(out)
        }
    }
}
