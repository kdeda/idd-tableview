//
//  TableColumnBuilder.swift
//  TableView
//
//  Created by Klajd Deda on 12/28/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import SwiftUI

/// To better understand this, read
/// https://theswiftdev.com/result-builders-in-swift/
///
/// This was causing swift compiler to not infer the generic types
/// To read more
/// https://sarunw.com/posts/how-to-explicitly-specialize-generic-function-in-swift/
/// The issue is that generic propagation needs to be properly consider

@resultBuilder
public enum TableColumnBuilder<RowValue> where RowValue: Identifiable, RowValue: Hashable {
    public static func buildBlock(_ components: TableColumn<RowValue>...) -> [TableColumn<RowValue>] {
        components
    }

    public static func buildBlock(_ components: [TableColumn<RowValue>]...) -> [TableColumn<RowValue>] {
        components.flatMap { $0 }
    }

    public static func buildEither(first component: [TableColumn<RowValue>]) -> [TableColumn<RowValue>] {
        return component
    }

    public static func buildEither(second component: [TableColumn<RowValue>]) -> [TableColumn<RowValue>] {
        return component
    }

    public static func buildOptional(_ component: [TableColumn<RowValue>]?) -> [TableColumn<RowValue>] {
        component ?? []
    }

    public static func buildExpression(_ expression: TableColumn<RowValue>) -> [TableColumn<RowValue>] {
        [expression]
    }

    public static func buildArray(_ components: [[TableColumn<RowValue>]]) -> [TableColumn<RowValue>] {
        components.flatMap { $0 }
    }
}
