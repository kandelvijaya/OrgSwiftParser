import Foundation

/// Operators

precedencegroup ApplicationPrecedenceGroup {
    associativity: left
    higherThan: AndThenPrecedenceGroup
}

infix operator |>: ApplicationPrecedenceGroup
public func |> <T,U>(_ value: T, _ transfrom: (T) -> U) -> U {
    return transfrom(value)
}


infix operator |>>: ApplicationPrecedenceGroup
public func |>> <T,U>(_ value: Parser<T>, _ transfrom: @escaping (T) -> U) -> Parser<U> {
    return value.map(transfrom)
}


precedencegroup AndThenPrecedenceGroup {
    associativity: left
    higherThan: AssignmentPrecedence
}

infix operator ->>-: AndThenPrecedenceGroup
public func ->>- <T,U>(_ lhs: Parser<T>, _ rhs: Parser<U>) -> Parser<(T,U)> {
    return lhs.andThen(rhs)
}

infix operator <|>: ApplicationPrecedenceGroup
public func <|> <T>(_ lhs: Parser<T>, _ rhs: Parser<T>) -> Parser<T> {
    return lhs.orElse(rhs)
}

infix operator ->>: ApplicationPrecedenceGroup
public func ->> <T>(_ lhs: Parser<T>, _ rhs: Parser<T>) -> Parser<T> {
    return lhs.keepLeft(rhs)
}

/*
 Would be nice if we could use .>>., .>> and >>.
 However, swift compiler warns for the last instance: >>.
 */

infix operator >>-: ApplicationPrecedenceGroup
public func >>- <T>(_ lhs: Parser<T>, _ rhs: Parser<T>) -> Parser<T> {
    return lhs.keepRight(rhs)
}
