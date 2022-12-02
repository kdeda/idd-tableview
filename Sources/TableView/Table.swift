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

/**
 Used to keep track of each rows bounds
 */
fileprivate struct RowBounds<RowValue>: Identifiable, Equatable where RowValue: Identifiable {
    let id: RowValue.ID
    let bounds: CGRect
}

fileprivate enum ScrollDirection: String, Equatable {
    case up
    case down
}

/**
 For when we click shift click to extend multiple selection.
 We want to do what Finder does on List View.
 */
fileprivate enum MultipleSelectionDirection {
    case none
    case up
    case down
}

fileprivate struct DraggedRowValue: Equatable {
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
fileprivate struct RowValueIndexPreferenceKey<RowValue>: PreferenceKey where RowValue: Identifiable {
    typealias Value = [RowBounds<RowValue>]
    
    static var defaultValue: [RowBounds<RowValue>] {
        get {
            _gValues[ObjectIdentifier(Self.self)] as? [RowBounds<RowValue>] ?? []
        }
        set {
            _gValues[ObjectIdentifier(Self.self)] = newValue
        }
    }
    
    static func reduce(value: inout [RowBounds<RowValue>], nextValue: () -> [RowBounds<RowValue>]) {
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

    private var intraRowSpacing: CGFloat = 2
    private var rows: Array<RowValue>
    private var selectionType: SelectionType
    /// https://www.howtogeek.com/700999/how-to-change-the-accent-and-highlight-colors-on-your-mac/
    /// https://stackoverflow.com/questions/22497938/is-this-possible-to-get-the-users-highlight-colour-on-os-x-using-cocoa/22500939
    ///
    private var selectedControlColor: Color = Color(NSColor.selectedContentBackgroundColor)
    @Binding private var singleSelection: RowValue.ID?
    @Binding private var multipleSelection: Set<RowValue.ID>
    @State private var multipleSelectionDirection: MultipleSelectionDirection = .none
    @Binding private var sortDescriptors: [TableColumnSort<RowValue>]
    @State private var columns: [TableColumn<RowValue>] = []
    @State private var rowIndexes: [RowBounds<RowValue>] = []
    @State private var isDraggSelecting = false
    @State private var singleSelectionInternalChange = false

    public init(
        _ rows: Array<RowValue>,
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>,
        @TableColumnBuilder<RowValue> columns: @escaping () -> [TableColumn<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .single
        self._singleSelection = singleSelection
        self._multipleSelection = .constant(Set())
        self._sortDescriptors = sortDescriptors
        
        let updatedColumns = columns().updateSortDescriptors(sortDescriptors.wrappedValue)
        self._columns = State(initialValue: updatedColumns)
        // Log4swift[Self.self].info("columns: \(self.columns.count)")
    }
    
    public init(
        _ rows: Array<RowValue>,
        multipleSelection: Binding<Set<RowValue.ID>>,
        sortDescriptors: Binding<[TableColumnSort<RowValue>]>,
        @TableColumnBuilder<RowValue> columns: @escaping () -> [TableColumn<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .multiple
        self._singleSelection = .constant(.none)
        self._multipleSelection = multipleSelection
        self._sortDescriptors = sortDescriptors

        let updatedColumns = columns().updateSortDescriptors(sortDescriptors.wrappedValue)
        self._columns = State(initialValue: updatedColumns)
        // Log4swift[Self.self].info("columns: \(self.columns.count)")
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
        case .single:
            singleSelectionInternalChange = true
            singleSelection = rowID
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

    /**
     We are extending the multiple selection.
     Calculate the ranges and select.
     Similar to how List view behaves in Finder.
     rowID is the new row we are going into, this defines the logic, since if we were
     on row 3 and selected row 10, all the rows in between will be selected.
     */
    private func extendMultipleSelection(_ rowID: RowValue.ID) {
        guard let clickIndex = rows.firstIndex(where: { $0.id == rowID })
        else { return }

        let selectedIndexes = multipleSelection.compactMap { rowID in
            rows.firstIndex(where: { $0.id == rowID })
        }

        // the lower and upper are indexes in the array
        // 0 is lower than 1
        var currentLower = selectedIndexes.min() ?? 0
        var currentUpper = selectedIndexes.max() ?? 0
        let newDirection: MultipleSelectionDirection = {
            if multipleSelectionDirection == .up {
                // we were going up, so any click above the upper should be up
                return (clickIndex < currentUpper) ? .up : .down
            } else if multipleSelectionDirection == .down {
                // we were going down, so any click above the lower should be down
                return (clickIndex > currentLower) ? .down : .up
            }
            // initial case
            return (clickIndex > currentLower) ? .down : .up
        }()
        // Log4swift[Self.self].info("newDirection: \(newDirection)")

        if newDirection == .up {
            if multipleSelectionDirection == .down {
                currentUpper = currentLower
            }
            // currentUpper = currentLower
            currentLower = clickIndex
        } else {
            if multipleSelectionDirection == .up {
                currentLower = currentUpper
            }
            currentUpper = clickIndex
            // currentLower = currentLower
        }

        if currentLower > currentUpper {
            // we should not get here
            Log4swift[Self.self].error("bad range: [\(currentLower) ... \(currentUpper)]")
            currentLower = clickIndex
            currentUpper = clickIndex
        }

        let newMultipleSelection = (currentLower ... currentUpper)
            .reduce(into: Set<RowValue.ID>()) { partialResult, nextItem in
                // Log4swift[Self.self].info("next: [\(nextItem)]")
                partialResult.insert(rows[nextItem].id)
            }
        if self.multipleSelection != newMultipleSelection {
            multipleSelection = newMultipleSelection
            // Log4swift[Self.self].info("newMultipleSelection: [\(newMultipleSelection)]")
        }
        self.multipleSelectionDirection = newDirection
    }

    /**
     Return true if we will handle this event
     */
    private func onKeyPressed(_ event: NSEvent) -> Bool {
        // Log4swift[Self.self].info("event: '\(event)'")
        // Log4swift[Self.self].info("rows.count: '\(rows.count)'")

        let selectedRowIndexes: [Int] = {
            switch selectionType {
            case .single:
                if let index = (rows.firstIndex(where: { $0.id == singleSelection } )) {
                    return [index]
                }

            case .multiple:
                return multipleSelection
                    .compactMap { rowID in
                        rows.firstIndex(where: { $0.id == rowID })
                    }
                    .sorted(by: <)
            }
            // no selection present.
            return [Int]()
        }()
        let currentRowIndex: Int = {
            switch selectionType {
            case .single:   return selectedRowIndexes.first ?? 0
            case .multiple:
                if multipleSelectionDirection == .up { return selectedRowIndexes.first ?? 0 }
                else if multipleSelectionDirection == .down { return selectedRowIndexes.last ?? 0 }
                return selectedRowIndexes.first ?? 0
            }
        }()

        switch (event.type, event.keyType) {
        case (.keyDown, .upArrow):
            let nextIndex = currentRowIndex - 1

            if nextIndex >= 0 {
                var modifierFlags = event.modifierFlags
                if modifierFlags.contains(.command) {
                    modifierFlags.remove(.command)
                }

                // Log4swift[Self.self].info("multipleSelectionDirection: [\(multipleSelectionDirection)]")
                // Log4swift[Self.self].info("moveUp, from: '\(currentRowIndex)' to: '\(nextIndex)' ")
                rowView_onTapGesture(rows[nextIndex].id, modifierFlags)
            }
        case (.keyDown, .downArrow):
            let nextIndex = currentRowIndex + 1

            if nextIndex < rows.count {
                var modifierFlags = event.modifierFlags
                if modifierFlags.contains(.command) {
                    modifierFlags.remove(.command)
                }

                // Log4swift[Self.self].info("multipleSelectionDirection: [\(multipleSelectionDirection)]")
                // Log4swift[Self.self].info("moveDown, from: '\(currentRowIndex)' to: '\(nextIndex)' ")
                rowView_onTapGesture(rows[nextIndex].id, modifierFlags)
            }
        default:
            return false
        }

        return true
    }

    /**
     Manage user input for row selection.
     It gets a bit tricky with multiple selections.
     This is called after a resounding click.
     If we drag the DragGesture.onChange will be stolen.
     */
    private func rowView_onTapGesture(_ rowID: RowValue.ID, _ modifierFlags: NSEvent.ModifierFlags?) {
        let flags = modifierFlags ?? NSEvent.ModifierFlags(rawValue: 0)

        switch selectionType {
        case .single:
            singleSelection = .none
            selectRowID(rowID)
        case .multiple:
            if flags.contains([.shift]) {
                // click + shift  extend the selection
                extendMultipleSelection(rowID)
            } else if flags.contains([.command]) {
                // click + command  toggle the extra selection
                if isSelectedRowID(rowID) {
                    unselectRowID(rowID)
                } else {
                    selectRowID(rowID)
                }
            } else {
                multipleSelection.removeAll()
                selectRowID(rowID)
            }
        }
    }

    private func rowView_onDragGesture(_ drag: DragGesture.Value) {
        var location = drag.location

        location.y -= 29
        // even though we think we have the coordinates correct, the location here is 32 pixels off the top of our view.
        // Log4swift[Self.self].info("---- ---- ----")
        // Log4swift[Self.self].info("drag.location: \(location))")

        // this can be called directly on drag, before calling onTapGesture ...
        //
        guard let rowBounds = rowIndexes.first(where: {
            // Log4swift[Self.self].info("rowID: \($0.id) bounds: \($0.bounds)")
            return $0.bounds.contains(drag.location)
        })
        else {
            // should not get here
            Log4swift[Self.self].error("failed to locate row at bounds: \(drag.location))")
            return
        }
        // the id of the row we just dragged over
        // we could have missed others if we drag super fast
        let rowID = rowBounds.id
        // Log4swift[Self.self].info("rowID: \(rowID))")

        switch selectionType {
        case .single:
            selectRowID(rowID)
        case .multiple:
            if !isDraggSelecting {
                // Finder deselects all and start the multiple selection from this point on
                Log4swift[Self.self].info("starting at rowID: \(rowID) ...")
                multipleSelectionDirection = .none
                multipleSelection.removeAll()
                isDraggSelecting = true
                selectRowID(rowID)
            } else {
                extendMultipleSelection(rowID)
            }
        }
    }

    @ViewBuilder
    /**
     This code should follow the logic on the TableHeader.
     So that we can calculate columns in line with the header
     */
    fileprivate func rowView(_ rowValue: RowValue) -> some View {
        HStack(alignment: .top, spacing: TableViewConfig.shared.betweenColumnsPadding) {
            ForEach(columns) { column in
                TableViewColumnView(
                    isSelected: isSelectedRowID(rowValue.id),
                    textColor: column.textColor
                ) {
                    column.createColumnView(rowValue)
                }
                // .border(Color.yellow)
                // .debug()
                if !columns.isLastColumn(column) {
                    Divider()
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, TableViewConfig.shared.horizontalPadding)
        .background(isSelectedRowID(rowValue.id) ? selectedControlColor : Color.clear)
        // .border(Color.yellow)
        .contentShape(Rectangle())
        .onTapGesture(count: 1, perform: {
            rowView_onTapGesture(rowValue.id, NSApp.currentEvent?.modifierFlags)
        })
        .focusable()
        //        .onHover(perform: { value in
        //            // DEDA DEBUG
        //            // Swift is adding some cool call backs ...
        //            Log4swift[Self.self].error("onHover: \(value) row: '\(rowValue.id)'")
        //        })
    }
    
    public var body: some View {
        // Log4swift[Self.self].info("columns: \(self.columns.count)")
        // Log4swift[Self.self].info("rows.count: '\(self.rows.count)'")

        return VStack(spacing: 0) {
            TableHeader(columns: $columns, sortDescriptors: $sortDescriptors)
            Divider()
            ScrollView {
                ScrollViewReader { value in
                    LazyVStack(spacing: intraRowSpacing) {
                        ForEach(rows) { rowValue in
                            rowView(rowValue)
                                .background(
                                    GeometryReader { geometry in
                                        // To understand the CoordinateSpace
                                        // https://www.hackingwithswift.com/books/ios-swiftui/understanding-frames-and-coordinates-inside-geometryreader
                                        // since the CoordinateSpace TableView is defined for this view
                                        // the first row starts at a location 0, 29 !!
                                        // we will offset this 29 during our rowView_onDragGesture
                                        Color.clear.preference(
                                            key: RowValueIndexPreferenceKey<RowValue>.self,
                                            value: [RowBounds(
                                                id: rowValue.id,
                                                bounds: {
                                                    var frame = geometry.frame(in: .named("TableView"))
                                                    frame.size.height += intraRowSpacing
                                                    return frame
                                                }()
                                            )]
                                        )
                                    }
                                )
                        }
                    }
                    .onAppear {
                        // make sure to scroll to visible if our single selection is not
                        Log4swift[Self.self].info("onAppear")
                        guard let honestValue = self.singleSelection
                        else { return }
                        
                        Log4swift[Self.self].info("onAppear singleSelection: '\(honestValue)'")
                        value.scrollTo(honestValue, anchor: .top)
                    }
                    .onChange(of: self.singleSelection) { newValue in
                        // make sure to scroll to visible when the single selection is modified
                        // ignore this if we modify it during internal selection
                        defer { self.singleSelectionInternalChange = false }

                        guard !singleSelectionInternalChange,
                              let honestValue = self.singleSelection
                        else { return }

                        value.scrollTo(honestValue, anchor: .top)
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            // .border(Color.green)
        }
        .onPreferenceChange(RowValueIndexPreferenceKey<RowValue>.self) { value in
            // TODO: kdeda
            // July 2022
            // for some reason i do get a warning in the console
            // 'Bound preference RowValueIndexPreferenceKey<Car> tried to update multiple times per frame'
            // it does not affect the workings but after a few hours of digging i gave up as to why
            // in theory we are experiencing an update cycle, but no idea why
            //            let rows = value.map(\.id)
            //            let newValues = value.filter { newValue in
            //                let match = rowIndexes.first { existing in
            //                    existing == newValue
            //                }
            //                return match == .none
            //            }
            //            Log4swift[Self.self].info("onPreferenceChange newValues: '\(newValues.count)' rowIndexes: '\(rows.count)'")
            rowIndexes = value
        }
        .gesture(
            DragGesture(minimumDistance: 2, coordinateSpace: CoordinateSpace.named("TableView"))
                .onChanged(rowView_onDragGesture)
                .onEnded { value in
                    Log4swift[Self.self].info("onEnded: \(value)")
                    isDraggSelecting = false
                }
        )
        .onKeyPressed(onKeyPressed)
        .coordinateSpace(name: "TableView")
//        .id(self.columns.count)
//        .dump()
    }

    public func setIntraRowSpacing(_ newValue: Double) -> Self {
        var rv = self

        rv.intraRowSpacing = newValue
        return rv
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
    @State var selection: Person.ID? = Person.testArray1[1].id
    @State private var sortDescriptors: [TableColumnSort<Person>] = [
        .init(compare: { $0.firstName < $1.firstName }, ascending: true, columnIndex: 1)
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
            TableColumn<Person>("First Name", alignment: .trailing) { rowValue in
                Text(rowValue.firstName)
                    .font(.subheadline)
            }
            .frame(width: 130)
            .sortDescriptor(compare: { $0.firstName < $1.firstName })

            TableColumn<Person>("Last Name", alignment: .trailing) { rowValue in
                Text(rowValue.lastName)
                    .textColor(Color.red)
                    .font(.subheadline)
            }
            .frame(width: 80)
            .sortDescriptor(compare: { $0.lastName < $1.lastName })

            TableColumn<Person>("", alignment: .leading) { rowValue in
                Text("")
                    .font(.subheadline)
            }
            .frame(width: 20)
            
            TableColumn<Person>("Address", alignment: .leading) { rowValue in
                Text(rowValue.address + " " + rowValue.address)
                    .font(.subheadline)
            }
            .frame(minWidth: 180, maxWidth: .infinity)
            .sortDescriptor(compare: { $0.address < $1.address })
        }
        .id(UUID())
    }
}

struct TablePreview_Previews: PreviewProvider {
    static var previews: some View {
        TablePreview()
            .frame(width: 655)
            .frame(height: 800)
            .padding()
        // setting a frame does cause some problems if the frame is smaller than the intrinsic size
        // from TableHeader.body tips
        // the intrinsic size should be 130 + 80 + 20 + 180 + (4 + 3) * betweenColumnsPadding + 2 + horizontalPadding or 455
            // .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .light)

        TablePreview()
            .frame(minWidth: 480)
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .dark)
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

/// Internal type so we can swing the ForegroundColorPreferenceKey
/// 
fileprivate struct TableViewColumnView<Content>: View where Content: View {
    /// this got introduced for debuging
    var title: String
    var isSelected: Bool
    @State private var textColor: Color?
    private let content: () -> Content

    public init(
        title: String = "",
        isSelected: Bool,
        textColor: Color?,
        @ViewBuilder content: @escaping () -> Content
    ) {
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
