//
//  TableColumn.swift
//  TCATable
//
//  Created by Klajd Deda on 3/13/22.
//

import SwiftUI
import Log4swift

public struct SortDescriptor: Equatable, Identifiable {
    public var id: Int = 0
    var comparator: String = ""
    var ascending: Bool = false
}

public struct ColumnInfo: Equatable, Identifiable {
    public var id: Int // the column index
    public var isDivider = false
    public var title = ""
    public var minWidth: CGFloat?
    public var idealWidth: CGFloat?
    public var maxWidth: CGFloat?
    public var alignment: Alignment = .center
    public var sortDescriptor: SortDescriptor = .init(id: 0, comparator: "", ascending: false)

    init(id: Int) {
        self.id = id
    }

    init(
        id: Int,
        isDivider: Bool = false,
        title: String = "",
        minWidth: CGFloat? = nil,
        idealWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .center,
        sortDescriptor: SortDescriptor = .init(id: 0, comparator: "", ascending: false)
    ) {
        self.id = id
        self.isDivider = isDivider
        self.title = title
        self.minWidth = minWidth
        self.idealWidth = idealWidth
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.sortDescriptor = sortDescriptor
        self.sortDescriptor.id = self.id
        
        idealWidth.map {
            self.minWidth = $0
            self.maxWidth = $0
        }
        maxWidth.map { _ in
            self.idealWidth = nil
        }
        // Log4swift[Self.self].info("column: \(self)")
    }
    
    init(
        id: Int,
        title: String = "",
        width: CGFloat = 120,
        alignment: Alignment = .center
    ) {
        self.id = id
        self.isDivider = false
        self.title = title
        self.minWidth = width
        self.idealWidth = width
        self.maxWidth = width
        self.alignment = alignment
    }
    
    public var iconName: String {
        sortDescriptor.ascending ? "chevron.up" : "chevron.down"
    }
}

extension Array where Element == ColumnInfo {
    func isLastColumn(_ column: Element) -> Bool {
        let index = firstIndex(where: { $0.id == column.id }) ?? 0
        return index == count - 1
    }
}

struct ColumnInfoPreferenceKey: PreferenceKey {
    static var defaultValue: [ColumnInfo] = []
    
    static func reduce(value: inout [ColumnInfo], nextValue: () -> [ColumnInfo]) {
        value.append(contentsOf: nextValue())
    }
}

struct SortDescriptorPreferenceKey: PreferenceKey {
    static var defaultValue: [SortDescriptor] = []
    
    static func reduce(value: inout [SortDescriptor], nextValue: () -> [SortDescriptor]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    public func columnView(
        _ id: Int,
        title: String = "",
        minWidth: CGFloat? = nil,
        idealWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        let column = ColumnInfo(
            id: id,
            isDivider: false,
            title: title,
            minWidth: minWidth,
            idealWidth: idealWidth,
            maxWidth: maxWidth,
            alignment: alignment
        )

        return self
            .frame(minWidth: column.minWidth, idealWidth: column.idealWidth, maxWidth: column.maxWidth, alignment: alignment)
            .preference(
                key: ColumnInfoPreferenceKey.self,
                value: [column]
            )
    }
    
    public func columnViewDivider(
        _ id: Int
    ) -> some View {
        let column = ColumnInfo(
            id: id,
            isDivider: true,
            title: "",
            minWidth: nil,
            idealWidth: 2,
            maxWidth: nil
        )

        return self
            .preference(
            key: ColumnInfoPreferenceKey.self,
            value: [column]
        )
    }
    
    public func columnViewSort(
        _ id: Int,
        comparator: String = "none", // for now
        ascending: Bool = false
    ) -> some View {
        let sortDescriptor = SortDescriptor(
            id: id,
            comparator: comparator,
            ascending: ascending
        )

        return self.preference(
            key: SortDescriptorPreferenceKey.self,
            value: [sortDescriptor]
        )
    }
}
