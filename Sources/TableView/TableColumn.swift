//
//  TableColumn.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

/// Models a particular TableView column
public struct TableColumn<RowValue>: Identifiable where RowValue: Equatable {
    public var id = UUID()
    public var title = ""
    public var width: CGFloat = 100
    public var alignment: Alignment = .leading
    public var sortDescriptor: TableColumnSort<RowValue>
    private var content: (RowValue) -> AnyView

    public init<Content: View>(
        _ title: String,
        width: CGFloat = 100,
        alignment: Alignment = .leading,
        sortDescriptor: TableColumnSort<RowValue>,
        @ViewBuilder content: @escaping (RowValue) -> Content
    ) {
        self.title = title
        self.width = width
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
}
