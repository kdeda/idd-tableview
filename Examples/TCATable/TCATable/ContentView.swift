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
        WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                Divider()
                TableView.Table(viewStore.files,
                      selection: viewStore.binding(\.$selectedFiles),
                      sortDescriptors: viewStore.binding(\.$sortDescriptors)
                ) {
                    TableColumn("File Size in Bytes", alignment: .trailing, sortDescriptor: .init(\File.physicalSize)) { rowValue in
                        Text(rowValue.logicalSize.decimalFormatted)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    .frame(width: 130)
                    TableColumn("On Disk", alignment: .trailing, sortDescriptor: .init(\File.logicalSize)) { rowValue in
                        Text(rowValue.physicalSize.compactFormatted)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    .frame(width: 80)
                    TableColumn("", alignment: .leading, sortDescriptor: .init(\File.self)) { rowValue in
                        HStack {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color.secondary)
                                .font(.subheadline)
                                .padding(.horizontal, 4)
                            //    .onTapGesture {
                            //        // this blocks the row selection ... WTF apple
                            //        Log4swift[Self.self].info("revealInFinder: \(file.filePath)")
                            //    }
                        }
                    }
                    .frame(width: 20)
                    TableColumn("Last Modified", alignment: .leading, sortDescriptor: .init(\File.modificationDate)) { rowValue in
                        Text(File.lastModified.string(from: rowValue.modificationDate))
                            .lineLimit(1)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    .frame(width: 160)
                    TableColumn("File Name", alignment: .leading, sortDescriptor: .init(\File.fileName)) { rowValue in
                        Text(rowValue.fileName)
                            .lineLimit(1)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    TableColumn("File Path", alignment: .leading, sortDescriptor: .init(\File.filePath)) { rowValue in
                        Text(rowValue.filePath)
                            .lineLimit(1)
                            .frame(alignment: .trailing)
                            .font(.subheadline)
                    }
                    .frame(minWidth: 120, maxWidth: .infinity)
                }
            }
            .frame(minWidth: 800, maxWidth: 1280, minHeight: 480, maxHeight: 800)
            .onAppear(perform: { viewStore.send(.appDidStart) })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: AppState.mockupStore)
    }
}
