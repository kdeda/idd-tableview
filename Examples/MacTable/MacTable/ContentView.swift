//
//  ContentView.swift
//  MacTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import SwiftUI
import TableView
import Log4swift

struct ContentView: View {
    var cars = Store.cars
    @State var rows = Store.cars
    @State var selection: Car.ID?
    @State var sortDescriptors: [TableColumnSort<Car>] = [
        .init(
            compare: { $0.year < $1.year },
            ascending: true,
            columnIndex: 0 // this needs to match to the column index
        )
    ]
    @State var showExtraColumn = false
    
    fileprivate func selectionString() -> String {
        switch selection {
        case .none:
            return "empty"
        case let .some(carID):
            guard let car = rows.first(where: { $0.id == carID })
            else { return "empty"}
            return "\(car.make), \(car.model), \(car.year)"
        }
    }

    @ViewBuilder
    fileprivate func headerView() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("This is the MacTable demo of the TableView package.")
                    .font(.headline)
                Text("It shows support for single row selection and vanilla swift bindings")
                    .font(.subheadline)
                Text("Selection: ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                +
                Text(selectionString())
                    .font(.subheadline)
            }
            Spacer()
            VStack {
                Button(action: {
                    showExtraColumn.toggle()
                }) {
                    Text(showExtraColumn ? "Hide The Extra Column" : "Show The Extra Column")
                        .fontWeight(.semibold)
                }
                Button(action: {
                    let count = cars.count - 4
                    self.selection = cars[count].id
                }) {
                    Text("Scroll Selection To Visible")
                        .fontWeight(.semibold)
                }
                // .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.all, 18)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView()
            Divider()
            TableView.Table(
                rows,
                singleSelection: $selection,
                sortDescriptors: Binding<[TableColumnSort<Car>]>(
                    get: {
                        sortDescriptors
                    }, set: { (sortDescriptors: [TableColumnSort<Car>]) in
                        self.sortDescriptors = sortDescriptors
                        
                        let sortDescriptor = sortDescriptors[0]
                        rows = rows.sorted(by: sortDescriptor.comparator)
                        Log4swift[Self.self].info("sorted.rows: \(rows.count)")
                    }
                )
            ) {
                TableColumn("Year", alignment: .trailing) { rowValue in
                    Text("\(rowValue.year)")
                        .textColor(.secondary)
                }
                .sortDescriptor(compare: { $0.year < $1.year })
                .frame(width: 60)
                
                TableColumn("Make", alignment: .trailing) { rowValue in
                    Text(rowValue.make)
                }
                .sortDescriptor(compare: { $0.make < $1.make })
                .frame(width: 80)
                
                TableColumn("", alignment: .leading) { rowValue in
                    Text("")
                }
                .sortDescriptor(compare: { _, _ in false })
                .frame(width: 20)
                
                TableColumn("Model", alignment: .leading) { rowValue in
                    Text(rowValue.model)
                }
                .sortDescriptor(compare: { $0.model < $1.model })
                .textColor(Color.yellow)
                .frame(width: 80)
                
                if showExtraColumn {
                    TableColumn("Extra", alignment: .leading) { rowValue in
                        Text(rowValue.extraColumn)
                    }
                    .sortDescriptor(compare: { $0.extraColumn < $1.extraColumn })
                    .frame(width: 160)
                }
                
                TableColumn("Category", alignment: .leading) { rowValue in
                    Text(rowValue.category)
                }
                .sortDescriptor(compare: { $0.category < $1.category })
                .frame(minWidth: 180, maxWidth: .infinity)
            }
            .id(showExtraColumn ? "showExtraColumn=true" : "showExtraColumn=false")
        }
        .frame(minWidth: 680, maxWidth: 1280, minHeight: 480, maxHeight: 800)
        // .debug()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .light)
        ContentView()
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .dark)
    }
}
