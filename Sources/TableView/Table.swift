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
    enum SelectionType {
        case single
        case multiple
    }
    
    private var rows: Array<RowValue>
    private var selectionType: SelectionType
    @Binding private var singleSelection: RowValue.ID?
    @Binding private var multipleSelection: Set<RowValue.ID>
    @Binding private var sortDescriptors: [TableColumnSort<RowValue>]
    @State private var columns: [TableColumn<RowValue>]
    
    public init(
        _ rows: Array<RowValue>,
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>,
        @ArrayBuilder<TableColumn<RowValue>> columns: @escaping () -> [TableColumn<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .single
        self._singleSelection = singleSelection
        self._multipleSelection = .constant(Set())
        self._sortDescriptors = sortDescriptors
        self._columns = State(initialValue: columns())
    }
    
    public init(
        _ rows: Array<RowValue>,
        multipleSelection: Binding<Set<RowValue.ID>>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>,
        @ArrayBuilder<TableColumn<RowValue>> columns: @escaping () -> [TableColumn<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .multiple
        self._singleSelection = .constant(.none)
        self._multipleSelection = multipleSelection
        self._sortDescriptors = sortDescriptors
        self._columns = State(initialValue: columns())
    }

    @ViewBuilder
    fileprivate func rowView() -> some View {
        ForEach(rows) { rowValue in
            HStack(alignment: .center, spacing: 6) {
                ForEach(columns) { column in
                    column.createCellView(rowValue)
                        .frame(minWidth: column.minWidth, maxWidth: column.maxWidth, alignment: column.alignment)
                    // We have 2 options here, display the rectangle as an invisible vertical devider
                    // Or display the Divider
                    // Rectangle()
                    //   .fill(Color.clear)
                    //   .frame(width: 1, height: 6)
                    if !columns.isLastColumn(column) {
                        Divider()
                    }
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    fileprivate func singleSelectionView() -> some View {
        List(selection: $singleSelection) {
            rowView()
        }
        .listStyle(PlainListStyle())
    }
    
    @ViewBuilder
    fileprivate func multipleSelectionView() -> some View {
        List(selection: $multipleSelection) {
            rowView()
        }
        .listStyle(PlainListStyle())
    }

    public var body: some View {
        VStack(spacing: 0) {
            TableHeader(columns: $columns, sortDescriptors: $sortDescriptors)
            
            switch selectionType {
            case .single: singleSelectionView()
            case .multiple: multipleSelectionView()
            }
        }
    }
}
