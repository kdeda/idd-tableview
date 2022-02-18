//
//  TableColumn.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

/// Models a particular TableView column
public struct TableColumn<RowValue>: Identifiable where RowValue: Equatable {
    public var id = UUID()
    public var title = ""
    public var width: CGFloat = 100
    public var maxWidth: CGFloat = 100
    public var minWidth: CGFloat = 100
    public var alignment: Alignment = .leading
    public var sortDescriptor: TableColumnSort<RowValue>
    private var content: (RowValue) -> AnyView

    public init<Content: View>(
        _ title: String,
        alignment: Alignment = .leading,
        sortDescriptor: TableColumnSort<RowValue>,
        @ViewBuilder content: @escaping (RowValue) -> Content
    ) {
        self.title = title
        self.alignment = alignment
        self.sortDescriptor = sortDescriptor
        self.content = { rowValue in
            AnyView(content(rowValue))
        }
    }
    
    @ViewBuilder
    public func createCellView(_ rowValue: RowValue) -> some View {
        content(rowValue)
    }

    public var iconName: String {
        sortDescriptor.ascending ? "chevron.up" : "chevron.down"
    }
    
    public func frame(minWidth: CGFloat = 100, maxWidth: CGFloat = 100) -> Self {
        var rv = self
        
        rv.minWidth = minWidth
        rv.width = minWidth
        rv.maxWidth = maxWidth
        return rv
    }
    
    public func frame(width: CGFloat = 100) -> Self {
        var rv = self
        
        rv.minWidth = width
        rv.width = width
        rv.maxWidth = width
        return rv
    }
}

extension Array where Element: Identifiable {
    public func isLastColumn(_ column: Element) -> Bool {
        let index = firstIndex(where: { $0.id == column.id }) ?? 0
        return index == count - 1
    }
}
