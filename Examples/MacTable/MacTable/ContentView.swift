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
    @State var selection: Car.ID?
    @State var sortDescriptors: [TableColumnSort<Car>] = [
        .init(\.make)
    ]
    
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
        HStack {
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
                .frame(minWidth: 180, maxWidth: .infinity)
            }
        }
        .frame(maxWidth: 1280, minHeight: 480, maxHeight: 800)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
