//
//  TableHeader2.swift
//  TCATable
//
//  Created by Klajd Deda on 3/14/22.
//

import SwiftUI
import Log4swift

struct TableHeader2: View {
    @Binding var columns: [ColumnInfo]
    @Binding var sortDescriptors: [SortDescriptor]

    public init(
        columns: Binding<[ColumnInfo]>,
        sortDescriptors: Binding<[SortDescriptor]>
    ) {
        self._columns = columns
        self._sortDescriptors = sortDescriptors
    }
    
    private func isSelectedColumn(_ column: ColumnInfo) -> Bool {
        sortDescriptors.first(where: { $0.id == column.id }) != nil
    }

    private var columnDebug: String {
        let columnDebug = columns
            .map { column in
                if column.isDivider {
                    return "|:\(column.minWidth ?? 0)"
                }
                return "\(column.title) : \(column.minWidth ?? 0)"
            }
            .joined(separator: " ")
        return columnDebug
    }
    
    private func toggleColumnSort(_ column: ColumnInfo) {
        guard !column.isDivider
        else { return }
        // TODO: When we select this column header and swap the sort
        // we want to slightly turn the background light gray or secondary color
        // and when the sort has completed revert back to normal color
        // it would require us to use a local private @State which start at false
        // and we turn it to true when we trigger sorting
        // after the sort has completed we we will reloaded
        //
        var column = columns[column.id]
        
        if isSelectedColumn(column) {
            column.sortDescriptor.ascending.toggle()
        }
        
        columns[column.id] = column
        // for now we are going to manage one sort at a time
        sortDescriptors = [column.sortDescriptor]
    }
    
    var body: some View {
        Log4swift[Self.self].info("columns: \(self.columns.count)")

        return VStack(spacing: 10) {
            //    HStack {
            //        Text(columnDebug)
            //            .frame(maxWidth: .infinity, alignment: .leading)
            //            .font(.subheadline)
            //    }
            //    Divider()
            HStack(alignment: .center, spacing: 6) {
                ForEach($columns) { $column in
                    HStack(spacing: 0) {
                        switch column.alignment {
                        case .leading: EmptyView()
                        case .center: Spacer()
                        case .trailing: Spacer()
                        default: EmptyView()
                        }
                        Text(column.title)
                            .fontWeight(isSelectedColumn(column) ? .bold : .regular)
                            .foregroundColor(isSelectedColumn(column) ? .none : .secondary)
                            // .frame(alignment: column.alignment)
                            .lineLimit(1)
                        if isSelectedColumn(column) {
                            Image(systemName: column.iconName)
                                .font(Font.system(.caption).bold())
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color.secondary)
                                .padding(.leading, 4)
                        }
                        switch column.alignment {
                        case .leading: Spacer()
                        case .center: Spacer()
                        case .trailing: EmptyView()
                        default: EmptyView()
                        }
                        if !columns.isLastColumn(column) {
                            Divider()
                                .padding(.leading, 4)
                        }
                    }
                    // .border(.yellow)
                    .padding(.vertical, 4)
                    .foregroundColor(Color.primary)
                    .frame(minWidth: column.minWidth, idealWidth: column.idealWidth,  maxWidth: column.maxWidth, alignment: column.alignment)
                    .contentShape(Rectangle())
                    .onTapGesture { toggleColumnSort(column) }
                }
            }
            .frame(height: 20)
            .font(.subheadline)
        }
    }
}

struct TableHeaderPreview: View {
    @State private var sortDescriptors: [SortDescriptor]
    @State private var columns: [ColumnInfo]

    init() {
        let sortDescriptors: [SortDescriptor] = [
            .init(id: 1, comparator: "", ascending: false)
        ]

        let columns: [ColumnInfo] = [
            .init(
                id: 0,
                title: "First Name",
                idealWidth: 130,
                alignment: .trailing,
                sortDescriptor: SortDescriptor(id: 0, comparator: "{ firstName }", ascending: true)
            ),
            .init(
                id: 1,
                title: "Last Name",
                idealWidth: 160,
                alignment: .leading,
                sortDescriptor: SortDescriptor(id: 1, comparator: "lastName", ascending: true)
            ),
            .init(
                id: 2,
                title: "",
                idealWidth: 20,
                alignment: .trailing,
                sortDescriptor: SortDescriptor(id: 2, comparator: "", ascending: true)
            ),
            .init(
                id: 3,
                title: "Address",
                maxWidth: .infinity,
                alignment: .trailing,
                sortDescriptor: SortDescriptor(id: 3, comparator: "address", ascending: true)
            ),
        ]

        self._sortDescriptors = State(initialValue: sortDescriptors)
        self._columns = State(initialValue: columns)
    }
    
    var body: some View {
        TableHeader2(columns: $columns, sortDescriptors: $sortDescriptors)
    }
}

struct TableHeaderPreview_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TableHeaderPreview()
                .frame(minWidth: 480)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(NSColor.windowBackgroundColor))
                .environment(\.colorScheme, .light)
                .padding()
        }
        VStack {
            TableHeaderPreview()
                .frame(minWidth: 480)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(NSColor.windowBackgroundColor))
                .environment(\.colorScheme, .dark)
                .padding()
        }
    }
}
