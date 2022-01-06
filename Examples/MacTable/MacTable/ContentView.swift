//
//  ContentView.swift
//  MacTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import SwiftUI
import TableView

struct ContentView: View {
    var cars = Store.cars
    @State var rows = Store.cars
    @State var selection = Set<Car.ID>()
    @State var sortDescriptors: [TableColumnSort<Car>] = [
        .init(\.make)
    ]

    var body: some View {
        VStack(spacing: 0) {
            TableView.Table(rows,
                  selection: $selection,
                  sortDescriptors: Binding<[TableColumnSort<Car>]>(
                    get: {
                        sortDescriptors
                    }, set: { (sortDescriptors: [TableColumnSort<Car>]) in
                        self.sortDescriptors = sortDescriptors
                        
                        let sortDescriptor = sortDescriptors[0]
                        rows = rows.sorted(by: sortDescriptor.comparator)
                    }
                  )
            ) {
                TableColumn("Year", width: 130, alignment: .trailing, sortDescriptor: .init(\Car.year)) { rowValue in
                    Text("\(rowValue.year)")
                        .frame(alignment: .trailing)
                }
                TableColumn("Make", width: 80, alignment: .trailing, sortDescriptor: .init(\Car.make)) { rowValue in
                    Text(rowValue.make)
                        .frame(alignment: .trailing)
                }
                TableColumn("", width: 20, alignment: .leading, sortDescriptor: .init(\Car.self)) { rowValue in
                    Text("")
                }
                TableColumn("Model", width: 120, alignment: .leading, sortDescriptor: .init(\Car.model)) { rowValue in
                    Text(rowValue.model)
                        .frame(alignment: .trailing)
                }
                TableColumn("Category", width: 160, alignment: .leading, sortDescriptor: .init(\Car.category)) { rowValue in
                    Text(rowValue.category)
                        .frame(alignment: .trailing)
                }
            }
        }
        .frame(minWidth: 640, maxWidth: 1080, minHeight: 480, maxHeight: 800)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
