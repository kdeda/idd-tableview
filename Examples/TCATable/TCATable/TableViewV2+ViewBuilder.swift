//
//  TableViewV2+ViewBuilder.swift
//  TCATable
//
//  Created by Klajd Deda on 3/14/22.
//

import SwiftUI
import Log4swift

// https://stackoverflow.com/questions/65984609/how-can-i-access-to-tupleview-through-viewbuilder-in-swiftui
extension TableViewV2 {
    // This will barf when there is just one column !!!
//    init(
//        _ rows: [RowValue],
//        @ViewBuilder content: @escaping (RowValue) -> RowView
//    ) {
//        let row: RowValue = Row(id: 0, column1: "Column 1 (row 0)", column2: "Column 2 (row 0)") as! RowValue
//        let view = content(row)
//
//        Log4swift["View.debug"].info("\(type(of: content))")
//        Log4swift["View.debug"].info("\(type(of: view))")
//        let columnViews = [view as? ColumnViewProtocol]
//        // let columns = columnViews.columns
//
//        var columnInfo = ColumnInfo()
//
//        columnInfo.title = "\(type(of: view))"
//        columnInfo.id = 0
//
//        let columns = [columnInfo]
//        self.init(rows, columns: columns, content: content)
//    }

    init<V1: View, V2: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2)> {
        self.init(rows, singleSelection, sortDescriptors, columnCount: 2, content: content)
    }
    
    init<V1: View, V2: View, V3: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2, V3)> {
        self.init(rows, singleSelection, sortDescriptors, columnCount: 3, content: content)
    }
    
    init<V1: View, V2: View, V3: View, V4: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2, V3, V4)> {
        self.init(rows, singleSelection, sortDescriptors, columnCount: 4, content: content)
    }
    
    init<V1: View, V2: View, V3: View, V4: View, V5: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2, V3, V4, V5)> {
        self.init(rows, singleSelection, sortDescriptors, columnCount: 5, content: content)
    }

    init<V1: View, V2: View, V3: View, V4: View, V5: View, V6: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2, V3, V4, V5, V6)> {
        self.init(rows, singleSelection, sortDescriptors, columnCount: 6, content: content)
    }

    init<V1: View, V2: View, V3: View, V4: View, V5: View, V6: View, V7: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2, V3, V4, V5, V6, V7)> {
//        // DEDA DEBUG
//        let row: RowValue = Row(id: 0, column1: "Column 1 (row 0)", column2: "Column 2 (row 0)", column3: "Column 3 (row 0)") as! RowValue
//        let views = content(row).value
//
//        Log4swift["View.debug"].info("\(type(of: content))")
//        Log4swift["View.debug"].info("\(type(of: views))")
//        let columnViews = [views.0 as? ColumnViewProtocol, views.1 as? ColumnViewProtocol]
        
        self.init(rows, singleSelection, sortDescriptors, columnCount: 7, content: content)
    }

    init<V1: View, V2: View, V3: View, V4: View, V5: View, V6: View, V7: View, V8: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2, V3, V4, V5, V6, V7, V8)> {
        self.init(rows, singleSelection, sortDescriptors, columnCount: 8, content: content)
    }
    
    init<V1: View, V2: View, V3: View, V4: View, V5: View, V6: View, V7: View, V8: View, V9: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2, V3, V4, V5, V6, V7, V8, V9)> {
        self.init(rows, singleSelection, sortDescriptors, columnCount: 9, content: content)
    }

    init<V1: View, V2: View, V3: View, V4: View, V5: View, V6: View, V7: View, V8: View, V9: View, V10: View>(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        sortDescriptors: Binding<[SortDescriptor]>,
        @ViewBuilder content: @escaping (RowValue) -> RowView
    ) where RowView == TupleView<(V1, V2, V3, V4, V5, V6, V7, V8, V9, V10)> {
        self.init(rows, singleSelection, sortDescriptors, columnCount: 10, content: content)
    }
}
