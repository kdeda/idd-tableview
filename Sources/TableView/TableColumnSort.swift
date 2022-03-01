//
//  TableColumnSort.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

/// Models the column sort implementation for a particular TableView column
/// We wanted to use KeyPaths for this and avoid introducing an extra generic for the value
/// The solution here is type erasure. We collect the strong type upon init, but than we earse it
public struct TableColumnSort<RowValue> where RowValue: Equatable {
    public var ascending = false
    public let value: PartialKeyPath<RowValue>
    private let compare: (_ lhs: RowValue, _ rhs: RowValue) -> Bool

    public init<ColumnValue: Comparable>(
        _ value: KeyPath<RowValue, ColumnValue>,
        ascending: Bool = false
    ) {
        self.ascending = ascending
        self.value = value
        self.compare = { $0[keyPath: value] < $1[keyPath: value] }
    }
    
    public func comparator(_ lhs: RowValue, _ rhs: RowValue) -> Bool {
        return ascending ? compare(lhs, rhs) : compare(rhs, lhs)
    }
}

extension TableColumnSort: Equatable {
    /// We are doing this to play nice with TCA
    /// There are no easy ways to implement Equatable with function variables
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.value == rhs.value && lhs.ascending == rhs.ascending
    }
}
