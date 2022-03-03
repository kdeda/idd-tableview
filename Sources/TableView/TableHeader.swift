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
struct TableHeader<RowValue, Content>: View where RowValue: Equatable, Content: View {
    @Binding var columns: [TableColumn<RowValue, Content>]
    @Binding var sortDescriptors: [TableColumnSort<RowValue>]
    
    public init(
        columns: Binding<[TableColumn<RowValue, Content>]>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>
    ) {
        self._columns = columns
        self._sortDescriptors = sortDescriptors
    }

    private func isSelectedColumn(_ column: TableColumn<RowValue, Content>) -> Bool {
        sortDescriptors.first(where: { $0.value == column.sortDescriptor.value }) != nil

        // debug code ...
        //        let rv = sortDescriptors.first(where: { $0.value == column.sortDescriptor.value }) != nil
        //
        //        if rv {
        //            Log4swift[Self.self].info("selected: '\(column.title)' iconName: '\(column.iconName)'")
        //        }
        //        return rv
    }
    
    var body: some View {
        Log4swift[Self.self].info("columns: \(self.columns.count)")

        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                ForEach($columns) { $column in
                    HStack(spacing: 8) {
                        Text(column.title)
                            .fontWeight(isSelectedColumn(column) ? .bold : .regular)
                            .frame(maxWidth: .infinity, alignment: column.alignment)
                        if isSelectedColumn(column) {
                            Image(systemName: column.iconName)
                                .font(Font.system(.caption).bold())
                                .foregroundColor(Color.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .foregroundColor(Color.primary)
                    .frame(minWidth: column.minWidth, maxWidth: column.maxWidth, alignment: column.alignment)
                    // .background(Color.yellow)
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
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            Divider()
        }
        .frame(height: 30)
    }
}

//struct TableHeaderPreview: View {
//    struct Person: Equatable, Hashable, Comparable {
//        var firstName: String
//        var lastName: String
//        var address: String
//
//        static func < (lhs: Person, rhs: Person) -> Bool {
//            false
//        }
//    }
//    @State private var sortDescriptors: [TableColumnSort<Person>] = [
//        .init(\.firstName)
//    ]
//    @State private var columns: [TableColumn<Person>] = [
//        TableColumn("First", alignment: .trailing, sortDescriptor: .init(\Person.firstName)) { rowValue in
//            Text("\(rowValue.firstName)")
//                .frame(alignment: .trailing)
//        }
//            .frame(width: 130),
//        TableColumn("Last", alignment: .trailing, sortDescriptor: .init(\Person.lastName)) { rowValue in
//            Text(rowValue.lastName)
//                .frame(alignment: .trailing)
//        }
//            .frame(width: 80),
//        TableColumn("", alignment: .leading, sortDescriptor: .init(\Person.self)) { rowValue in
//            Text("")
//        }
//            .frame(width: 20),
//        TableColumn("Address", alignment: .leading, sortDescriptor: .init(\Person.address)) { rowValue in
//            Text(rowValue.address)
//                .frame(alignment: .trailing)
//        }
//        .frame(minWidth: 120, maxWidth: .infinity)
//    ]
//
//    var body: some View {
//        TableHeader<Person>(columns: $columns, sortDescriptors: $sortDescriptors)
//    }
//}
//
//struct TableHeaderPreview_Previews: PreviewProvider {
//    static var previews: some View {
//        TableHeaderPreview()
//            .frame(minWidth: 480)
//            .background(Color(NSColor.windowBackgroundColor))
//            .environment(\.colorScheme, .light)
//        TableHeaderPreview()
//            .frame(minWidth: 480)
//            .background(Color(NSColor.windowBackgroundColor))
//            .environment(\.colorScheme, .dark)
//    }
//}
