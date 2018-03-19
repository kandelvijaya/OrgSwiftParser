import Foundation

public enum Result<T> {
    case success(T)
    case failure(String)
    
    public func map<U>(_ transform: (T) -> U) -> Result<U> {
        switch self {
        case let .success(v):
            return .success(transform(v))
        case let .failure(e):
            return .failure(e)
        }
    }
    
    public func flatMap<U>(_ transform: (T) -> Result<U>) -> Result<U> {
        return Result.joined(map(transform))
    }
    
    public static func joined<A>(_ input: Result<Result<A>>) -> Result<A> {
        switch input {
        case let .success(v):
            return v
        case let .failure(e):
            return .failure(e)
        }
    }
}