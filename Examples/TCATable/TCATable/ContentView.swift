//
//  ContentView.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Log4swift
import TableView

struct ContentView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        Log4swift[Self.self].info("")
        return WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                Divider()
                TableView.Table(viewStore.files,
                      selection: viewStore.binding(\.$selectedFiles),
                      sortDescriptors: viewStore.binding(\.$sortDescriptors)
                ) {
                    TableColumn("File Size in Bytes", width: 130, alignment: .trailing, sortDescriptor: .init(\File.physicalSize)) { rowValue in
                        Text(rowValue.logicalSize.decimalFormatted)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    TableColumn("On Disk", width: 80, alignment: .trailing, sortDescriptor: .init(\File.logicalSize)) { rowValue in
                        Text(rowValue.physicalSize.compactFormatted)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    TableColumn("", width: 20, alignment: .leading, sortDescriptor: .init(\File.self)) { rowValue in
                        HStack {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color.secondary)
                                .font(.subheadline)
                            //    .onTapGesture {
                            //        // this blocks the row selection ... WTF apple
                            //        Log4swift[Self.self].info("revealInFinder: \(file.filePath)")
                            //    }
                        }
                    }
                    TableColumn("Last Modified", width: 160, alignment: .leading, sortDescriptor: .init(\File.modificationDate)) { rowValue in
                        Text(File.lastModified.string(from: rowValue.modificationDate))
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    TableColumn("File Name", width: 120, alignment: .leading, sortDescriptor: .init(\File.fileName)) { rowValue in
                        Text(rowValue.fileName)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    TableColumn("File Path", width: .infinity, alignment: .leading, sortDescriptor: .init(\File.filePath)) { rowValue in
                        Text(rowValue.filePath)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                }
                
            }
            .onAppear(perform: { viewStore.send(.appDidStart) })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: AppState.mockupStore)
    }
}
