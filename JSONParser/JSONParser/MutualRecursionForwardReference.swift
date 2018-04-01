//
//  MutualRecursionForwardReference.swift
//  JSONParser
//
//  Created by Vijaya Prakash Kandel on 4/1/18.
//  Copyright © 2018 Vijaya Prakash Kandel. All rights reserved.
//

import Foundation

final class MutualRecursionForwardReference<T> {
    var recursion_lookup_table: [String: T] = [:]
    private let key = "Key"
    
    /// Initialize with initial reference
    init(with initialReference: T) {
        recursion_lookup_table[key] = initialReference
    }
    
    /// When the mutual recursive defination expression is done
    /// assign the eventual value to be used.
    func forwardReference(to eventualReference: T) {
        recursion_lookup_table[key] = eventualReference
    }
    
    /// retrieve reference
    func currentValue() -> T {
        return recursion_lookup_table[key]!
    }
}
