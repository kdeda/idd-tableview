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
    
    /// We just want to mutate the frame sizes
    public func frame(minWidth: CGFloat = 100, maxWidth: CGFloat = 100) -> Self {
        var rv = self
        
        rv.minWidth = minWidth
        rv.width = minWidth
        rv.maxWidth = maxWidth
        return rv
    }
    
    /// We just want to mutate the frame sizes
    public func frame(width: CGFloat = 100) -> Self {
        var rv = self
        
        rv.minWidth = width
        rv.width = width
        rv.maxWidth = width
        return rv
    }
    
    /// We just want to mutate the sortDescriptor
    public func updateSortDescriptor(_ sortDescriptor: TableColumnSort<RowValue>) -> Self {
        var rv = self
        
        rv.sortDescriptor = sortDescriptor
        return rv
    }
}

extension Array where Element: Identifiable {
    public func isLastColumn(_ column: Element) -> Bool {
        let index = firstIndex(where: { $0.id == column.id }) ?? 0
        return index == count - 1
    }
}

/// Ideally i would like this to be a generic where Element is of type TableColumn<RowValue>
/// but we can't easily do that right now
/// https://forums.swift.org/t/extension-on-array-where-element-is-generic-type/10225/3
///
extension Array {
    func updateSortDescriptors<RowValue>(_ sortDescriptors: [TableColumnSort<RowValue>]) -> [TableColumn<RowValue>] {
        // preserve the state of the column sort
        // the truth comes from sortDescriptors
        // each column should reflect that value, by keyPath
        // so if the truth says we are sorting by .fileName, ascending and our column is set to sort by .fileName
        // than we copy the truth into the column
        // this assures the view's initial render to perfectly match the state
        // as the column are sorted up or down, the values will be pushed back into the sortDescriptors binding
        let columns = self.compactMap { column -> TableColumn<RowValue>? in
            if let column = column as? TableColumn<RowValue> {
                if let truth = sortDescriptors.first(where: { $0.value == column.sortDescriptor.value  }) {
                    return column.updateSortDescriptor(truth)
                }
                return column
            }
            return nil
        }
        
        return columns
    }
}
