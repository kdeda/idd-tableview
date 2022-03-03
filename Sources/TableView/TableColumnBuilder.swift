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
    public static func buildBlock<RowValue, Content>(_ components: TableColumn<RowValue, Content>...) -> [TableColumn<RowValue, Content>] {
        components
    }

    public static func buildBlock<RowValue, Content>(_ components: [TableColumn<RowValue, Content>]...) -> [TableColumn<RowValue, Content>] {
        components.flatMap { $0 }
    }

    public static func buildEither<RowValue, Content>(first component: [TableColumn<RowValue, Content>]) -> [TableColumn<RowValue, Content>] {
        return component
    }

    public static func buildEither<RowValue, Content>(second component: [TableColumn<RowValue, Content>]) -> [TableColumn<RowValue, Content>] {
        return component
    }

    public static func buildOptional<RowValue, Content>(_ component: [TableColumn<RowValue, Content>]?) -> [TableColumn<RowValue, Content>] {
        component ?? []
    }

    public static func buildExpression<RowValue, Content>(_ expression: TableColumn<RowValue, Content>) -> [TableColumn<RowValue, Content>] {
        [expression]
    }

    public static func buildArray<RowValue, Content>(_ components: [[TableColumn<RowValue, Content>]]) -> [TableColumn<RowValue, Content>] {
        components.flatMap { $0 }
    }
}
