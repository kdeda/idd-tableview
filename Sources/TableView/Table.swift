//
//  Table.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI
import Log4swift

struct RowValueIndex<RowValue>: Identifiable, Equatable where RowValue: Identifiable {
    let id: RowValue.ID
    let bounds: CGRect
}

enum ScrollDirection: String, Equatable {
    case up
    case down
}

struct DraggedRowValue: Equatable {
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
    /// https://www.howtogeek.com/700999/how-to-change-the-accent-and-highlight-colors-on-your-mac/
    /// https://stackoverflow.com/questions/22497938/is-this-possible-to-get-the-users-highlight-colour-on-os-x-using-cocoa/22500939
    ///
    private var selectedControlColor: Color = Color(NSColor.selectedContentBackgroundColor)
    @Binding private var singleSelection: RowValue.ID?
    @Binding private var multipleSelection: Set<RowValue.ID>
    @Binding private var sortDescriptors: [TableColumnSort<RowValue>]
    @State private var columns: [TableColumn<RowValue>] = []
    @State private var rowIndex: [RowValueIndex<RowValue>] = []
    @State private var draggedRows: [RowValue.ID: DraggedRowValue] = [:]

    public init(
        _ rows: Array<RowValue>,
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>,
        @TableColumnBuilder columns: @escaping () -> [TableColumn<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .single
        self._singleSelection = singleSelection
        self._multipleSelection = .constant(Set())
        self._sortDescriptors = sortDescriptors
        
        let columns = columns().updateSortDescriptors(sortDescriptors.wrappedValue)
        self._columns = State(initialValue: columns)
        Log4swift[Self.self].info("columns: \(self.columns.count)")
    }

    public init(
        _ rows: Array<RowValue>,
        multipleSelection: Binding<Set<RowValue.ID>>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>,
        @TableColumnBuilder columns: @escaping () -> [TableColumn<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .multiple
        self._singleSelection = .constant(.none)
        self._multipleSelection = multipleSelection
        self._sortDescriptors = sortDescriptors

        let columns = columns().updateSortDescriptors(sortDescriptors.wrappedValue)
        self._columns = State(initialValue: columns)
        Log4swift[Self.self].info("columns: \(self.columns.count)")
    }

    private  func isSelectedRowID(_ rowID: RowValue.ID) -> Bool {
        switch selectionType {
        case .single: return singleSelection == rowID
        case .multiple: return multipleSelection.contains(rowID)
        }
    }
    
    /// if already not selected it will be selected
    /// otherwise noop
    private func selectRowID(_ rowID: RowValue.ID) {
        // Log4swift[Self.self].info("rowID: '\(rowID)'")
        switch selectionType {
        case .single: singleSelection = rowID
        case .multiple: multipleSelection.insert(rowID)
        }
    }
    
    /// if already selected it will be unselected
    /// otherwise noop
    private func unselectRowID(_ rowID: RowValue.ID) {
        // Log4swift[Self.self].info("rowID: '\(rowID)'")
        switch selectionType {
        case .single: singleSelection = .none
        case .multiple: multipleSelection.remove(rowID)
        }
    }
    
    @ViewBuilder
    fileprivate func rowView(_ rowValue: RowValue) -> some View {
        HStack(alignment: .center, spacing: 6) {
            ForEach(columns) { column in
                TableViewColumnView(title: column.title, isSelected: isSelectedRowID(rowValue.id), textColor: column.textColor) {
                    column.createColumnView(rowValue)
                        .frame(minWidth: column.minWidth, maxWidth: column.maxWidth, alignment: column.alignment)
                }
                // .debug()
                if !columns.isLastColumn(column) {
                    Divider()
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            // when selecting one row we remove all other selections
            // this is called after a resounding click
            // if we drag the DragGesture.onChange will be stolen
            //
            switch selectionType {
            case .single: singleSelection = .none
            case .multiple: multipleSelection.removeAll()
            }
            selectRowID(rowValue.id)
            draggedRows.removeAll()
        }
        //        .onHover(perform: { value in
        //            // DEDA DEBUG
        //            // Swift is adding some cool call backs ...
        //            Log4swift[Self.self].error("onHover: \(value) row: '\(rowValue.id)'")
        //        })
    }
    
    public var body: some View {
        Log4swift[Self.self].info("columns: \(self.columns.count)")

        return VStack(spacing: 0) {
            TableHeader(columns: $columns, sortDescriptors: $sortDescriptors)
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(rows) { rowValue in
                        rowView(rowValue)
                            .padding(.leading, 8)
                            .background(isSelectedRowID(rowValue.id) ? selectedControlColor : Color.clear)
                            // .border(isSelectedRowID(rowValue.id) ? selectedControlColor : .clear)
                            .background(
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .preference(
                                            key: RowValueIndexPreferenceKey<RowValue>.self,
                                            value: [RowValueIndex(
                                                id: rowValue.id,
                                                bounds: geometry.frame(in: .named("TableView"))
                                            )]
                                        )
                                }
                            )
                    }
                }
            }
        }
        .onPreferenceChange(RowValueIndexPreferenceKey<RowValue>.self) { value in
            rowIndex = value
        }
        .gesture(
            DragGesture()
                .onChanged { drag in
                    // this can be called directly on drag, before calling onTapGesture ...
                    //
                    guard let row = rowIndex.first(where: { $0.bounds.contains(drag.location) })
                    else {
                        // we might hit here for the pixels in between the rows now hard coded at 2 pixels
                        // LazyVStack(spacing: 2)
                        Log4swift[Self.self].error("onChanged: failed to locate row at bounds: \(drag.location))")
                        return
                    }
                    
                    if selectionType == .single {
                        selectRowID(row.id)
                        return
                    }
                    
                    let newScrollDirection: ScrollDirection = {
                        if drag.location.y > drag.predictedEndLocation.y { return .up }
                        else if drag.location.y < drag.predictedEndLocation.y { return .down }
                        return .up
                    }()
                    
                    // we want to replicate the existing logic in the TableView
                    // use case:
                    // if we are dragging down and than reverse direction to drag up
                    // the selection is whiped and than back down the selection appears and so forth
                    
                    if draggedRows.isEmpty {
                        // it means we got here with no selection so that first selecting will be the anchor
                        draggedRows[
                            row.id,
                            default: DraggedRowValue(directions: [newScrollDirection, newScrollDirection])
                        ].appendDirection(newScrollDirection)
                    } else {
                        draggedRows[
                            row.id,
                            default: DraggedRowValue(directions: [])
                        ].appendDirection(newScrollDirection)
                    }
                    
                    // debug code ...
                    //    draggedRows.forEach { element in
                    //        Log4swift[Self.self].info("onChanged: isSelected: '\(element.value.isSelected)' directions: '\(element.value.directions.map(\.rawValue).joined(separator: ", "))' row.id: '\(element.key)'")
                    //    }

                    draggedRows.forEach { element in
                        !element.value.isSelected
                        ? unselectRowID(element.key)
                        :  selectRowID(element.key)
                    }
                }
                .onEnded { value in
                    Log4swift[Self.self].info("onEnded: \(value)")
                    draggedRows.removeAll()
                }
        )
        .coordinateSpace(name: "TableView")
//        .id(self.columns.count)
//        .dump()
    }
}

struct Person {
    var id: String = UUID().uuidString
    var firstName: String
    var lastName: String
    var address: String
}
extension Person: Equatable {}
extension Person: Identifiable {}
extension Person: Hashable {}
extension Person: Comparable {
    static func < (lhs: Person, rhs: Person) -> Bool {
        false
    }
}
extension Person {
    // https://www.fakepersongenerator.com/random-address
    static let testArray1: [Person] = [
        .init(firstName: "Lincoln", lastName: "Smith", address: "1461 Lincoln Drive, Hummelstown, PA"),
        .init(firstName: "Meadow", lastName: "Smith", address: "4586 Meadow Lane, Santa Rosa, CA"),
        .init(firstName: "Pike", lastName: "Smith", address: "4994 Pike Street, Del Mar, CA"),
//        .init(firstName: "John", lastName: "Smith", address: "1461 Lincoln Drive, Hummelstown, PA"),
//        .init(firstName: "John", lastName: "Smith", address: "4586 Meadow Lane, Santa Rosa, CA"),
//        .init(firstName: "John", lastName: "Smith", address: "1461 Lincoln Drive, Hummelstown, PA"),
//        .init(firstName: "John", lastName: "Smith", address: "4586 Meadow Lane, Santa Rosa, CA"),
//        .init(firstName: "John", lastName: "Smith", address: "1461 Lincoln Drive, Hummelstown, PA"),
//        .init(firstName: "John", lastName: "Smith", address: "4586 Meadow Lane, Santa Rosa, CA"),
//        .init(firstName: "John", lastName: "Smith", address: "1461 Lincoln Drive, Hummelstown, PA"),
//        .init(firstName: "John", lastName: "Smith", address: "4586 Meadow Lane, Santa Rosa, CA"),
//        .init(firstName: "John", lastName: "Smith", address: "1461 Lincoln Drive, Hummelstown, PA"),
//        .init(firstName: "John", lastName: "Smith", address: "4586 Meadow Lane, Santa Rosa, CA"),
//        .init(firstName: "John", lastName: "Smith", address: "1461 Lincoln Drive, Hummelstown, PA"),
//        .init(firstName: "John", lastName: "Smith", address: "4586 Meadow Lane, Santa Rosa, CA"),
//        .init(firstName: "John", lastName: "Smith", address: "1461 Lincoln Drive, Hummelstown, PA"),
//        .init(firstName: "John", lastName: "Smith", address: "4586 Meadow Lane, Santa Rosa, CA"),
    ]
}

struct TablePreview: View {
    @State var rows: [Person] = Person.testArray1
    @State var selection: Person.ID? = Person.testArray1[0].id
    @State private var sortDescriptors: [TableColumnSort<Person>] = [
        .init(\.firstName)
    ]
    
    var body: some View {
        TableView.Table(
            rows,
            singleSelection: $selection,
            sortDescriptors: Binding<[TableColumnSort<Person>]>(
                get: {
                    sortDescriptors
                }, set: { (sortDescriptors: [TableColumnSort<Person>]) in
                    self.sortDescriptors = sortDescriptors
                    
                    let sortDescriptor = sortDescriptors[0]
                    rows = rows.sorted(by: sortDescriptor.comparator)
                }
            )
        ) {
            TableColumn("First Name", alignment: .trailing, sortDescriptor: .init(\Person.firstName)) { rowValue in
                Text(rowValue.firstName)
            }
            .frame(width: 130)
            TableColumn("Last Name", alignment: .trailing, sortDescriptor: .init(\Person.lastName)) { rowValue in
                Text(rowValue.lastName)
                    .textColor(Color.red)
            }
            .frame(width: 80)
            TableColumn("", alignment: .leading, sortDescriptor: .init(\Person.self)) { rowValue in
                Text("")
            }
            .frame(width: 20)
            TableColumn("Address", alignment: .leading, sortDescriptor: .init(\Person.address)) { rowValue in
                Text(rowValue.address)
            }
            .frame(minWidth: 180, maxWidth: .infinity)
        }
        .id(UUID())
    }
}

struct TablePreview_Previews: PreviewProvider {
    static var previews: some View {
        TablePreview()
            .frame(minWidth: 480)
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .light)
        TablePreview()
            .frame(minWidth: 480)
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .dark)
    }
}

extension View {
    public func debug() -> Self {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children
        
        Log4swift["View.debug"].info("\(mirror.subjectType)")
        children.forEach { child in
            Log4swift["View.debug"].info("\(child)")
        }
        return self
    }
}

struct ForegroundColorPreferenceKey: PreferenceKey {
    static var defaultValue: Color = .clear

    static func reduce(value: inout Color, nextValue: () -> Color) {
        value = nextValue()
    }
}

extension View {
    public func textColor(_ color: Color) -> some View {
        self.preference(key: ForegroundColorPreferenceKey.self, value: color)
    }
}

fileprivate struct TableViewColumnView<Content>: View where Content: View {
    var title: String
    var isSelected: Bool
    @State private var textColor: Color?
    private let content: () -> Content

    public init(title: String, isSelected: Bool, textColor: Color?, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.isSelected = isSelected
        self.textColor = textColor
        self.content = content
    }
    
    var body: some View {
        // Log4swift[Self.self].info("column: '\(title)' isSelected: '\(isSelected)' textColor: '\(textColor)'")
        return content()
            .foregroundColor(isSelected ? Color.white : textColor)
            .onPreferenceChange(ForegroundColorPreferenceKey.self) { textColor in
                self.textColor = textColor
            }
    }
}
