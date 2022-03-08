//
//  TableColumnBuilder.swift
//  TableView
//
//  Created by Klajd Deda on 12/28/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation

/// To better understand this, read
/// https://theswiftdev.com/result-builders-in-swift/
///
@resultBuilder
public enum TableColumnBuilder {
    public static func buildBlock<RowValue>(_ components: TableColumn<RowValue>...) -> [TableColumn<RowValue>] {
        components
    }

    public static func buildBlock<RowValue>(_ components: [TableColumn<RowValue>]...) -> [TableColumn<RowValue>] {
        components.flatMap { $0 }
    }

    public static func buildEither<RowValue>(first component: [TableColumn<RowValue>]) -> [TableColumn<RowValue>] {
        return component
    }

    public static func buildEither<RowValue>(second component: [TableColumn<RowValue>]) -> [TableColumn<RowValue>] {
        return component
    }

    public static func buildOptional<RowValue>(_ component: [TableColumn<RowValue>]?) -> [TableColumn<RowValue>] {
        component ?? []
    }

    public static func buildExpression<RowValue>(_ expression: TableColumn<RowValue>) -> [TableColumn<RowValue>] {
        [expression]
    }

    public static func buildArray<RowValue>(_ components: [[TableColumn<RowValue>]]) -> [TableColumn<RowValue>] {
        components.flatMap { $0 }
    }
}
