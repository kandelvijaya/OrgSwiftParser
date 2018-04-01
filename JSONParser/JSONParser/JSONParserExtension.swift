//
//  JSONParserExtension.swift
//  JSONParser
//
//  Created by Vijaya Prakash Kandel on 4/1/18.
//  Copyright © 2018 Vijaya Prakash Kandel. All rights reserved.
//

import Foundation
import ParserCombinator

/// JSONValue to [String: JSONValue]

extension JSONValue {
    
    public func typedValue() -> Any? {
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
    
    public func toDict() -> [String: Any]? {
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
    
    public subscript(keypath: String) -> Any? {
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

