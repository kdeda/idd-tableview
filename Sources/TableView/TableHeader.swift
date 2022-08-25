//
//  TableHeader.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation
import SwiftUI
import Log4swift

/// Models the Header View for the TableView
struct TableHeader<RowValue>: View where RowValue: Equatable {
    @Binding var columns: [TableColumn<RowValue>]
    @Binding var sortDescriptors: [TableColumnSort<RowValue>]
    
    public init(
        columns: Binding<[TableColumn<RowValue>]>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>
    ) {
        self._columns = columns
        self._sortDescriptors = sortDescriptors
    }

    private func isSelectedColumn(_ column: TableColumn<RowValue>) -> Bool {
        sortDescriptors.first(where: { $0.columnIndex == column.sortDescriptor.columnIndex }) != nil

        // debug code ...
        //        let rv = sortDescriptors.first(where: { $0.value == column.sortDescriptor.value }) != nil
        //
        //        if rv {
        //            Log4swift[Self.self].info("selected: '\(column.title)' iconName: '\(column.iconName)'")
        //        }
        //        return rv
    }
    
    /**
     The Intrinsic size for this component is calculated as following
     1) horizontalPadding pixels spacing on the leading of the first column
     2) betweenColumnsPadding pixels spacing between each column and the column dividers. If there are n columns there are n -1 dividers
     3) horizontalPadding pixels spacing on the trailing of the last column
     
     Finaly the intrinsic width for the tableview is based of the header math
     the sum of all columns + horizontalPadding + (n + (n - 1)) * betweenColumnsPadding + horizontalPadding
     */
    var body: some View {
        Log4swift[Self.self].info("columns: \(self.columns.count)")
        
        return HStack(alignment: .center, spacing: TableViewConfig.shared.betweenColumnsPadding) {
            ForEach($columns) { $column in
                HStack(spacing: 0) {
                    Text(column.title)
                        .fontWeight(isSelectedColumn(column) ? .bold : .regular)
                        .frame(maxWidth: .infinity, alignment: column.alignment)
                        .lineLimit(1)
                    if isSelectedColumn(column) {
                        Image(systemName: column.iconName)
                            .font(Font.system(.caption).bold())
                            .padding(.leading, 6)
                    }
                }
                .padding(.vertical, 4)
                .foregroundColor(isSelectedColumn(column) ? Color.primary : Color.secondary)
                .frame(minWidth: column.minWidth, maxWidth: column.maxWidth, alignment: column.alignment)
                // .background(Color.yellow)
                // .border(Color.yellow)
                .contentShape(Rectangle())
                .onTapGesture {
                    // TODO: When we select this column header and swap the sort
                    // we want to slightly turn the background light gray or secondary color
                    // and when the sort has completed revert back to normal color
                    // it would require us to use a local private @State which start at false
                    // and we turn it to true when we trigger sorting
                    // after the sort has completed we we will reloaded
                    //
                    Log4swift[Self.self].info("column: '\(column.title)' ascending: '\(column.sortDescriptor.ascending)'")
                    column.sortDescriptor.ascending.toggle()
                    Log4swift[Self.self].info("column: '\(column.title)' ascending: '\(column.sortDescriptor.ascending)'")
                    
                    // for now we are going to manage one sort at a time
                    sortDescriptors = [column.sortDescriptor]
                }
                if !columns.isLastColumn(column) {
                    Divider()
                }
            }
        }
        .frame(height: 20)
        .font(.subheadline)
        .padding(.horizontal, TableViewConfig.shared.horizontalPadding)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct TableHeaderPreview: View {
    struct Person: Equatable, Hashable, Comparable {
        var firstName: String
        var lastName: String
        var address: String

        static func < (lhs: Person, rhs: Person) -> Bool {
            false
        }
    }
    
    @State private var sortDescriptors: [TableColumnSort<Person>]
    @State private var columns: [TableColumn<Person>]

    init() {
        let sortDescriptors: [TableColumnSort<Person>] = [
            .init(compare: { $0.firstName < $1.firstName }, ascending: true, columnIndex: 1)
        ]

        let columns = [
            TableColumn<Person>("First Name", alignment: .trailing) { rowValue in
                Text(rowValue.firstName)
            }
                .sortDescriptor(compare: { $0.firstName < $1.firstName })
                .frame(width: 130),
            TableColumn<Person>("Last Name", alignment: .trailing) { rowValue in
                Text(rowValue.lastName)
                    .textColor(Color.red)
            }
                .sortDescriptor(compare: { $0.lastName < $1.lastName })
                .frame(width: 90),
            TableColumn<Person>("", alignment: .leading) { rowValue in
                Text("")
            }
                .frame(width: 20),
            TableColumn<Person>("Address", alignment: .leading) { rowValue in
                Text(rowValue.address)
            }
                .sortDescriptor(compare: { $0.address < $1.address })
                .frame(minWidth: 180, maxWidth: .infinity)
        ]
            .updateSortDescriptors(sortDescriptors)

        self._sortDescriptors = State(initialValue: sortDescriptors)
        self._columns = State(initialValue: columns)
    }
    
    var body: some View {
        TableHeader<Person>(columns: $columns, sortDescriptors: $sortDescriptors)
    }
}

struct TableHeaderPreview_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TableHeaderPreview()
                .frame(minWidth: 480)
                .background(Color(NSColor.windowBackgroundColor))
                .environment(\.colorScheme, .light)
                .padding()
        }
        VStack {
            TableHeaderPreview()
                .frame(minWidth: 480)
                .background(Color(NSColor.windowBackgroundColor))
                .environment(\.colorScheme, .dark)
                .padding()
        }
    }
}
