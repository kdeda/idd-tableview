//
//  ArrayBuilder.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation

/// Creates an array from a variadic list
@resultBuilder
public struct ArrayBuilder<T> {
    public static func buildBlock(_ components: T...) -> [T] {
        components
    }
}

extension Sequence {
    func sorted<T: Comparable>(
        by keyPath: KeyPath<Element, T>,
        using comparator: (T, T) -> Bool = (<)
    ) -> [Element] {
        sorted { a, b in
            comparator(a[keyPath: keyPath], b[keyPath: keyPath])
        }
    }
}

/// Example of the ArrayBuilder pattern ...
struct MyTable {
    let columns: [MyColumn]
}

struct MyColumn {
    let data: String
    let content: () -> Void
}

let myTable = MyTable(columns: [
    MyColumn(data: "First") {
    },
    MyColumn(data: "Second") {
    },
    MyColumn(data: "Third") {
    },
])

extension MyTable {
    init(@ArrayBuilder<MyColumn> content: () -> [MyColumn]) {
        self.columns = content()
    }
}

let myTable2 = MyTable {
    MyColumn(data: "String") {
    }
    MyColumn(data: "String") {
    }
    MyColumn(data: "String") {
    }
}
