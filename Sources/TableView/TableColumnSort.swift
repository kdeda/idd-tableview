//
//  TableColumnSort.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

public typealias TableColumnSortCompare<RowValue> = (_ lhs: RowValue, _ rhs: RowValue) -> Bool

/// Models the column sort implementation for a particular TableView column
/// We wanted to use KeyPaths for this and avoid introducing an extra generic for the value
/// The solution here is type erasure. We collect the strong type upon init, but than we earse it
public struct TableColumnSort<RowValue> where RowValue: Equatable {
    private let compare: TableColumnSortCompare<RowValue>
    public var ascending = false
    public var columnIndex: Int // match it to the column index
    
    public init(
        compare: @escaping TableColumnSortCompare<RowValue>,
        ascending: Bool = false,
        columnIndex: Int = 0
    ) {
        self.compare = compare
        self.ascending = ascending
        self.columnIndex = columnIndex
    }
    
    @available(*, deprecated, renamed: "init(compare:ascending:columnIndex:)")
    public init<ColumnValue: Comparable>(
        _ value: KeyPath<RowValue, ColumnValue>,
        ascending: Bool = false
    ) {
        // this is really slow ...
        self.compare = { $0[keyPath: value] < $1[keyPath: value] }
        self.ascending = ascending
        self.columnIndex = 0
    }

    public func comparator(_ lhs: RowValue, _ rhs: RowValue) -> Bool {
        return ascending ? compare(lhs, rhs) : compare(rhs, lhs)
    }
}

extension TableColumnSort: Equatable {
    /// We are doing this to play nice with TCA
    /// There are no easy ways to implement Equatable with function variables
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.columnIndex == rhs.columnIndex
        && lhs.ascending == rhs.ascending
    }
}
