//
//  ContentView3.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Log4swift

struct RowValueIndex<RowValue>: Identifiable, Equatable where RowValue: Identifiable {
    let id: RowValue.ID
    let bounds: CGRect
}

struct DraggedRow: Equatable {
    enum ScrollDirection: String, Equatable {
        case up
        case down
    }

    var directions: [ScrollDirection] = []
    
    mutating func appendDirection(_ direction: ScrollDirection) {
        if let last = directions.last {
           if last != direction {
               directions.append(direction)
           }
        } else {
            directions.append(direction)
        }
    }
    
    /// as we drag up and down we will accumulate those values here
    /// a row is than selected if the counts on this differ
    /// counts being the same means a zero sum game,
    /// it was selected on the up and than on the down, which annihilate each other
    var isSelected: Bool {
        let ups = (directions.filter { $0 == .up }).count
        let downs = (directions.filter { $0 == .down }).count
        
        return ups != downs
    }
}

/// https://lostmoa.com/blog/AddingMutableStaticPropertiesToGenericsAndProtocolExtensions/
fileprivate var _gValues: [ObjectIdentifier: Any] = [:]

/// https://stackoverflow.com/questions/68785513/how-to-detect-when-swiftui-view-is-being-dragged-over
struct RowValueIndexPreferenceKey<RowValue>: PreferenceKey where RowValue: Identifiable {
    typealias Value = [RowValueIndex<RowValue>]
    
    static var defaultValue: [RowValueIndex<RowValue>] {
        get {
            _gValues[ObjectIdentifier(Self.self)] as? [RowValueIndex<RowValue>] ?? []
        }
        set {
            _gValues[ObjectIdentifier(Self.self)] = newValue
        }
    }
    
    static func reduce(value: inout [RowValueIndex<RowValue>], nextValue: () -> [RowValueIndex<RowValue>]) {
        value.append(contentsOf: nextValue())
    }
}

// https://alejandromp.com/blog/implementing-a-equally-spaced-stack-in-swiftui-thanks-to-tupleview/
//
struct TableViewV2<RowValue, RowView>: View where RowValue: Identifiable, RowView: View {
    struct NameSpaceID: Hashable {}

    enum SelectionType {
        case single
        case multiple
    }

    private var selectedControlColor: Color = Color(NSColor.selectedContentBackgroundColor)
    var rows: [RowValue]
    private var selectionType: SelectionType
    @State private var columns: [ColumnInfo] = []
    @Binding private var singleSelection: RowValue.ID?
    @Binding private var multipleSelection: Set<RowValue.ID>
    @Binding private var sortDescriptors: [SortDescriptor]
    @State private var rowIndex: [RowValueIndex<RowValue>] = []
    @State private var draggedRows: [RowValue.ID: DraggedRow] = [:]
    @State private var textColor: Color?

    var content: (RowValue) -> RowView
    var debugString = ""
    
    private func columnInfoPreferenceKeyDidChange(_ columnInfos: [ColumnInfo]) {
        Log4swift["TableView"].info("columnInfos: \(columnInfos.count)")
        columnInfos.forEach { columnInfo in
            var column = columnInfo
            column.sortDescriptor = columns[columnInfo.id].sortDescriptor
            columns[columnInfo.id] = column
        }
        Log4swift["TableView"].info("columns: \(columns.count)")
    }
    
    private func sortDescriptorPreferenceKeyDidChange(_ sortDescriptors: [SortDescriptor]) {
        Log4swift["TableView"].info("sortDescriptors: \(sortDescriptors.count)")
        sortDescriptors.forEach { sortDescriptor in
            var column = columns[sortDescriptor.id]
            column.sortDescriptor = sortDescriptor
            
            columns[sortDescriptor.id] = column
        }
        Log4swift["TableView"].info("columns: \(columns.count)")
    }

    private func rowValueIndexPreferenceKeyDidChange(_ value: RowValueIndexPreferenceKey<RowValue>.Value) {
        rowIndex = value
    }
    
    init(
        _ rows: [RowValue],
        _ singleSelection: Binding<RowValue.ID?>,
        _ sortDescriptors: Binding<[SortDescriptor]>,
        columnCount: Int,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) {
        self.rows = rows
        self.selectionType = .single
        self._singleSelection = singleSelection
        self._multipleSelection = .constant(Set())

        self._sortDescriptors = sortDescriptors
        // we don't care as these will be replaced on onPreferenceChange...
        let columns = (0 ..< columnCount).map(ColumnInfo.init(id:))
        self._columns = State(initialValue: columns)
        self.content = content

//        Log4swift["View.debug"].info("\(columns)")
//        self.debugString = "\(type(of: content))"
//        Log4swift["View.debug"].info("\(debugString)")
    }

    private  func isSelectedRowID(_ rowID: RowValue.ID) -> Bool {
        switch selectionType {
        case .single: return singleSelection == rowID
        case .multiple: return false // multipleSelection.contains(rowID)
        }
    }
    
    /// if already not selected it will be selected
    /// otherwise noop
    private func selectRowID(_ rowID: RowValue.ID) {
        // Log4swift[Self.self].info("rowID: '\(rowID)'")
        switch selectionType {
        case .single: singleSelection = rowID
        case .multiple:
            if !multipleSelection.contains(rowID) {
                multipleSelection.insert(rowID)
            }
        }
    }
    
    /// if already selected it will be unselected
    /// otherwise noop
    private func unselectRowID(_ rowID: RowValue.ID) {
        // Log4swift[Self.self].info("rowID: '\(rowID)'")
        switch selectionType {
        case .single: singleSelection = .none
        case .multiple:
            if multipleSelection.contains(rowID) {
                multipleSelection.remove(rowID)
            }
        }
    }

    public var body: some View {
        Log4swift["TableView"].info("columns: \(self.columns.count)")

        return VStack(spacing: 0) {
            //    Text(debugString)
            //        .lineLimit(20)
            TableHeader2(columns: $columns, sortDescriptors: $sortDescriptors)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(NSColor.controlBackgroundColor))

            Divider()
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(rows) { row in
                        // debugRow(row)

                        HStack(alignment: .center, spacing: 6) {
                            // content was created from a ViewBuilder so it is going to draw all the columns at once
                            content(row)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(isSelectedRowID(row.id) ? selectedControlColor : Color.clear)
                        .foregroundColor(isSelectedRowID(row.id) ? Color.white : .none)
                        // .border(isSelectedRowID(rowValue.id) ? selectedControlColor : .clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // when selecting one row we remove all other selections
                            // this is called after a resounding click
                            // if we drag the DragGesture.onChange will be stolen
                            //
                            switch selectionType {
                            case .single: singleSelection = .none
                            case .multiple: () // multipleSelection.removeAll()
                            }
                            selectRowID(row.id)
                            draggedRows.removeAll()
                        }
                        .background(
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(Color.clear)
                                    .preference(
                                        key: RowValueIndexPreferenceKey<RowValue>.self,
                                        value: [RowValueIndex(
                                            id: row.id,
                                            bounds: geometry.frame(in: .named(NameSpaceID()))
                                        )]
                                    )
                            }
                        )
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onPreferenceChange(ColumnInfoPreferenceKey.self, perform: columnInfoPreferenceKeyDidChange)
        .onPreferenceChange(SortDescriptorPreferenceKey.self, perform: sortDescriptorPreferenceKeyDidChange)
        .onPreferenceChange(RowValueIndexPreferenceKey<RowValue>.self, perform: rowValueIndexPreferenceKeyDidChange)
        .gesture(
            DragGesture()
                .onChanged { drag in
                    // this can be called directly on drag, before calling onTapGesture ...
                    //
                    guard let row = rowIndex.first(where: { $0.bounds.contains(drag.location) })
                    else {
                        // we might hit here for the pixels in between the rows now hard coded at 2 pixels
                        // LazyVStack(spacing: 2)
                        Log4swift["TableView"].error("onChanged: failed to locate row at bounds: \(drag.location))")
                        return
                    }
                    
                    if selectionType == .single {
                        selectRowID(row.id)
                        return
                    }
                    
                    let scrollDirection: DraggedRow.ScrollDirection = {
                        if drag.location.y > drag.predictedEndLocation.y { return .up }
                        else if drag.location.y < drag.predictedEndLocation.y { return .down }
                        return .up
                    }()
                    
                    // we want to replicate the existing logic in the SwiftUI.List (NSTableView)
                    // use case:
                    // if we are dragging down select rows as we drag mouse over them
                    // if we reverse and drag up unselect all selected until an unselected row and than start selecting them
                    // as we drag mouse up and down the selection toggles to follow the current mouse pointer
                    // tricky
                    
                    if draggedRows.isEmpty {
                        // it means we got here with no selection so this first direction will be the anchor
                        draggedRows[
                            row.id,
                            default: DraggedRow(directions: [scrollDirection])
                        ].appendDirection(scrollDirection)
                    } else {
                        draggedRows[
                            row.id,
                            default: DraggedRow(directions: [])
                        ].appendDirection(scrollDirection)
                    }
                    
                    // debug code ...
                    //                    draggedRows.forEach { element in
                    //                        Log4swift[Self.self].info("onChanged: isSelected: '\(element.value.isSelected)' directions: '\(element.value.directions.map(\.rawValue).joined(separator: ", "))' row.id: '\(element.key)'")
                    //                    }
                    
                    draggedRows.forEach { element in
                        element.value.isSelected
                        ? selectRowID(element.key)
                        : unselectRowID(element.key)
                    }
                }
                .onEnded { value in
                    Log4swift[Self.self].info("onEnded: \(value)")
                    draggedRows.removeAll()
                }
        )
        .coordinateSpace(name: NameSpaceID())
    }
}

extension View {
    public func debug() -> Self {
        let type = type(of: self)
        
        Log4swift["View.debug"].info("\(type)")
        return self
    }
}

struct Row: Identifiable {
    var id: Int
    var column1: String
    var column2: String
    var column3: String
}

extension Row {
    var column2Color: Color? {
        if id % 2 == 0 {
            let index = "Column 2 (row \(id))"
            return (column2 == index) ? Color.pink : .none
        }
        return .none
    }
}

struct ContentView3: View {
    let store: Store<AppState, AppAction>
//    var rows: [Row] = (0 ..< 500_000).map {
//        .init(id: $0, column1: "Column 1 (row \($0))", column2: "Column 2 (row \($0))", column3: "Column 3 (row \($0))")
//    }
    @State private var sortDescriptors: [SortDescriptor] = [
        .init(id: 6, comparator: "column3", ascending: true)
    ]

    private func isSelected(_ selection: File.ID?, file: File) -> Bool {
        let rv = selection == file.id
        
        // Log4swift["ContentView3"].info("selection: '\(selection ?? "")' file: '\(file.id)' rv: '\(rv)'")
        return rv
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                Divider()
                TableViewV2(
                    viewStore.files,
                    singleSelection: viewStore.binding(\.$selection),
                    sortDescriptors: Binding<[SortDescriptor]>(
                        get: {
                            sortDescriptors
                        }, set: { (sortDescriptors: [SortDescriptor]) in
                            self.sortDescriptors = sortDescriptors
                            // let sortDescriptor = sortDescriptors[0]
                            // rows = rows.sorted(by: sortDescriptor.comparator)
                        }
                    )
                ) { row in
                    HStack(spacing: 0) {
                        Text(row.physicalSize.decimalFormatted)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                        Divider()
                    }
                    // .border(.yellow)
                    .columnView(0, title: "File Size in Bytes", idealWidth: 130, alignment: .trailing)
                    .columnViewSort(0, comparator: "{ $0.physicalSize < $1.physicalSize }", ascending: false)

                    HStack(spacing: 0) {
                        Text(row.logicalSize.compactFormatted)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                        Divider()
                    }
                    .columnView(1, title: "On Disk", idealWidth: 70, alignment: .trailing)
                    .columnViewSort(1, comparator: "{ $0.logicalSize < $1.logicalSize }", ascending: false)

                    HStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 12, height: 12, alignment: .center)
                            .foregroundColor(isSelected(viewStore.selection, file: row) ? .white : .pink)
                            .font(.subheadline)
                            .padding(.horizontal, 4)
                        //    .onTapGesture {
                        //        // this blocks the row selection ... WTF apple
                        //        Log4swift[Self.self].info("revealInFinder: \(file.filePath)")
                        //    }
                        Spacer(minLength: 4)
                        Divider()
                    }
                    // .frame(height: 48)
                    .columnView(2, title: "", idealWidth: 24, alignment: .center)
                    .columnViewSort(2, comparator: "", ascending: false)

                    HStack {
                        Text(File.lastModified.string(from: row.modificationDate))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(isSelected(viewStore.selection, file: row) ? .white : .pink)
                        Spacer()
                        Divider()
                    }
                    .columnView(3, title: "Last Modified", idealWidth: 160, alignment: .leading)
                    .columnViewSort(3, comparator: "{ $0.modificationDate < $1.modificationDate }", ascending: false)

                    HStack {
                        Text(row.fileName)
                            .lineLimit(1)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Divider()
                    }
                    .columnView(4, title: "File Name", idealWidth: 160, alignment: .leading)
                    .columnViewSort(4, comparator: "{ $0.fileName < $1.fileName }", ascending: false)

                    Text(row.filePath)
                        .lineLimit(1)
                        .font(.subheadline)
                        .columnView(5, title: "File Name", minWidth: 180, maxWidth: .infinity, alignment: .leading)
                        .columnViewSort(5, comparator: "{ $0.filePath < $1.filePath }", ascending: false)
                }
                // .debug()
                .border(Color.init(NSColor.lightGray), width: 0.5)
            }
            .padding(.all, 24)
            .frame(minWidth: 820, maxWidth: 1280, minHeight: 480, maxHeight: 800)
            .onAppear(perform: { viewStore.send(.appDidStart) })
        }
    }
}

struct ContentView3_Previews: PreviewProvider {
    static var previews: some View {
        ContentView3(store: AppState.mock)
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .light)
        ContentView3(store: AppState.mock)
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .dark)
    }
}
