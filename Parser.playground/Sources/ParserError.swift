//
//  Copyright © 2018 Vijaya Prakash Kandel. All rights reserved.
//

import Foundation


public struct ParserError {
    public typealias Label = String
    let label: Label
    let error: String
}

func error(_ label: ParserError.Label, _ errorDescription: String) -> ParserError {
    return ParserError(label: label, error: errorDescription)
}


public func log<T>(_ result: Result<T>) {
    switch result {
    case let .success(v):
        print(v)
    case let .failure(e):
        let line1 = "Error parsing \(e.label)"
        let line2 = "\(e.error)"
        print(line1)
        print(line2)
    }
}
