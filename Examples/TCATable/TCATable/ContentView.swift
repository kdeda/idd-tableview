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

    fileprivate func selectionString(count: Int) -> String {
        switch count {
        case 0:
            return "empty"
        case 1:
            return "one file"
        case _ where count > 1:
            return "\(count) files"
        default:
            return ""
        }
    }
    
    @ViewBuilder
    fileprivate func headerView() -> some View {
        WithViewStore(store) { viewStore in
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This is the TCATable demo of the TableView.")
                        .font(.headline)
                    Text("It shows support for multiple row selection and TCA")
                        .font(.subheadline)
                    Text("Selection: ")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    +
                    Text(selectionString(count: viewStore.selectedFiles.count))
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.all, 18)
        }
    }
    
    private func isSelected(_ selectedFiles: Set<File.ID>, file: File) -> Bool {
        let rv = selectedFiles.contains(file.id)
        
        // Log4swift["ContentView3"].info("selection: '\(selection ?? "")' file: '\(file.id)' rv: '\(rv)'")
        return rv
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                headerView()
                Divider()
                TableView.Table(
                    viewStore.files,
                    multipleSelection: viewStore.binding(\.$selectedFiles),
                    sortDescriptors: viewStore.binding(\.$sortDescriptors)
                ) {
                    TableColumn("File Size in Bytes", alignment: .trailing) { row in
                        Text(row.physicalSize.decimalFormatted)
                            .font(.subheadline)
                    }
                    .frame(width: 130)
                    .sortDescriptor(compare: { $0.physicalSize < $1.physicalSize })

                    TableColumn("On Disk", alignment: .trailing) { row in
                        Text(row.logicalSize.compactFormatted)
                            .font(.subheadline)
                    }
                    .frame(width: 70)
                    .sortDescriptor(compare: { $0.logicalSize < $1.logicalSize })

                    TableColumn("", alignment: .leading) { row in
                        HStack {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 12, height: 12, alignment: .center)
                                .foregroundColor(isSelected(viewStore.selectedFiles, file: row) ? .white : .pink)
                                .font(.subheadline)
                                .padding(.horizontal, 4)
                                .frame(width: 20)
                            //    .onTapGesture {
                            //        // this blocks the row selection ... WTF apple
                            //        Log4swift[Self.self].info("revealInFinder: \(file.filePath)")
                            //    }
                        }
                        // .frame(height: 48)
                    }
                    .frame(width: 20)

                    TableColumn("Last Modified", alignment: .leading) { row in
                        Text(File.lastModified.string(from: row.modificationDate))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(isSelected(viewStore.selectedFiles, file: row) ? .white : .pink)
                    }
                    .frame(width: 160)
                    .sortDescriptor(compare: { $0.modificationDate < $1.modificationDate })

                    TableColumn("File Name", alignment: .leading) { row in
                        Text(row.fileName)
                            .lineLimit(1)
                            .font(.subheadline)
                    }
                    .frame(width: 160)
                    .sortDescriptor(compare: { $0.fileName < $1.fileName })

                    TableColumn("File Path", alignment: .leading) { row in
                        Text(row.filePath)
                            .lineLimit(1)
                            .font(.subheadline)
                    }
                    .frame(minWidth: 180, maxWidth: .infinity)
                    .sortDescriptor(compare: { $0.filePath < $1.filePath })
                }
                Divider()
                HStack {
                    Spacer()
                    Text("displaying \(viewStore.files.count) files and \(viewStore.selectedFiles.count) selected files")
                        .lineLimit(1)
                        .font(.subheadline)
                        .padding(.all, 8)
                }
            }
            .frame(minWidth: 820, maxWidth: 1280, minHeight: 480, maxHeight: 800)
            .onAppear(perform: { viewStore.send(.appDidStart) })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: AppState.mock)
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .light)
        ContentView(store: AppState.mock)
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .dark)
    }
}
