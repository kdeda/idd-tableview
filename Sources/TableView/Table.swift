//
//  Table.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI
import Log4swift

/// Generic, Simple TableView that supports BigSur
/// Apple's Table SwiftUI component requires a whole new oeprating system for it to work
/// Must be really hard to write
///
/// We have to resort to this to support macOS 11.
///
/// https://noahgilmore.com/blog/swiftui-self-sizing-cells/
/// https://dev.to/hugh_jeremy/adding-an-nstableview-to-a-swiftui-view-212p
/// https://swiftui-lab.com/a-powerful-combo/
/// https://stackoverflow.com/questions/68462035/is-there-a-better-way-to-create-a-multi-column-data-table-list-view-in-swiftui

public struct Table<RowValue>: View where RowValue: Identifiable, RowValue: Hashable {
    private var rows: Array<RowValue>
    @Binding private var selection: Set<RowValue.ID>
    @Binding private var sortDescriptors: [TableColumnSort<RowValue>]
    @State private var columns: [TableColumn<RowValue>]
    
    public init(
        _ rows: Array<RowValue>,
        selection: Binding<Set<RowValue.ID>>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>,
        @ArrayBuilder<TableColumn<RowValue>> columns: @escaping () -> [TableColumn<RowValue>]
    ) {
        self.rows = rows
        self._selection = selection
        self._sortDescriptors = sortDescriptors
        self.columns = columns()
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            TableHeader(columns: $columns, sortDescriptors: $sortDescriptors)
            List(rows, selection: $selection) { rowValue in
                HStack(alignment: .center, spacing: 6) {
                    ForEach(columns) { column in
                        column.createCellView(rowValue)
                            .frame(maxWidth: column.width, alignment: column.alignment)
                        // We have 2 options here, display the rectangle as an invisible vertical devider
                        // Or display the Divider
//                        Rectangle()
//                            .fill(Color.clear)
//                            .frame(width: 1, height: 6)
                        Divider()
                    }
                    Spacer()
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}
