//
//  TableHeader.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
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
        sortDescriptors.first(where: { $0.value == column.sortDescriptor.value  }) != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                ForEach($columns) { $column in
                    Button(action: {
                        // TODO: When we select this column header and swap the sort
                        // we want to slightly turn the background light gray or secondary color
                        // and when the sort has completed revert back to normal color
                        Log4swift[Self.self].info("sortDescriptor.ascending: '\(column.sortDescriptor.ascending)'")
                        column.sortDescriptor.ascending.toggle()
                        Log4swift[Self.self].info("sortDescriptor.ascending: '\(column.sortDescriptor.ascending)'")

                        // for now we are going to manage one sort at a time
                        sortDescriptors = [column.sortDescriptor]
                    }) {
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
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(Color.primary)
                    .frame(maxWidth: column.width, alignment: .trailing)
                    Divider()
                }
                Spacer()
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            Divider()
        }
        .frame(height: 30)
    }
}
