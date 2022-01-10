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
                TableColumn("Year", alignment: .trailing, sortDescriptor: .init(\Car.year)) { rowValue in
                    Text("\(rowValue.year)")
                        .frame(alignment: .trailing)
                }
                .frame(width: 130)
                TableColumn("Make", alignment: .trailing, sortDescriptor: .init(\Car.make)) { rowValue in
                    Text(rowValue.make)
                        .frame(alignment: .trailing)
                }
                .frame(width: 80)
                TableColumn("", alignment: .leading, sortDescriptor: .init(\Car.self)) { rowValue in
                    Text("")
                }
                .frame(width: 20)
                TableColumn("Model", alignment: .leading, sortDescriptor: .init(\Car.model)) { rowValue in
                    Text(rowValue.model)
                        .frame(alignment: .trailing)
                }
                .frame(width: 120)
                TableColumn("Category", alignment: .leading, sortDescriptor: .init(\Car.category)) { rowValue in
                    Text(rowValue.category)
                        .frame(alignment: .trailing)
                }
                .frame(minWidth: 120, maxWidth: .infinity)
            }
        }
        .frame(minWidth: 800, maxWidth: 1280, minHeight: 480, maxHeight: 800)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
