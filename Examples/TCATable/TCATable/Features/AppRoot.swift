//
//  AppState.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation
import Combine
import ComposableArchitecture
import Log4swift
import TableView
import SwiftUI

struct AppRoot: ReducerProtocol {
    /// This is the state for the TableView
    struct State: Equatable, Identifiable {
        var id = UUID()
        var isAppReady = false
        var files: [File] = []
        @BindableState var selectedFiles: Set<File.ID> = []
        @BindableState var sortDescriptors: [TableColumnSort<File>] = [
            .init(
                compare: { $0.physicalSize < $1.physicalSize },
                ascending: true,
                columnIndex: 0 // this needs to match to the column index
            )
        ]
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case appDidStart
        case setFiles([File])
        case selectedFilesDidChange([File])
        case sortFiles(TableColumnSort<File>)
    }

    @Dependency(\.fileClient) var fileClient

    init() {
    }

    var body: some ReducerProtocol<State, Action> {
        BindingReducer()

        Reduce { state, action in
            struct FilterLogMessagesID: Hashable {}

            switch action {
            case .binding(\.$selectedFiles):
                Log4swift[Self.self].info("selectedFiles: '\(state.selectedFiles.count)'")
//                let files = state.files.filter { state.selectedFiles.contains($0.id) }
//                return Effect(value: .selectedFilesDidChange(files))
                return .none

            case .binding(\.$sortDescriptors):
                return Effect(value: .sortFiles(state.sortDescriptors[0]))

            case .binding:
                return .none

            case .appDidStart where !state.isAppReady:
                state.isAppReady = true

                return .task {
                    .setFiles(
                        await fileClient.fetchFiles(URL(fileURLWithPath: NSHomeDirectory()))
                    )
                }

            case .appDidStart:
                return .none

            case let .setFiles(newValue):
                Log4swift[Self.self].info("files: '\(newValue.count)'")

                state.files = newValue
                let newSelection = newValue.filter({ state.selectedFiles.contains($0.id) })

                // preserve selection
                state.selectedFiles = Set(newSelection.map(\.id))
                return Effect(value: .sortFiles(state.sortDescriptors[0]))

            case let .selectedFilesDidChange(newValue):
                state.selectedFiles = Set(newValue.map(\.id))
                return .none

            case let .sortFiles(sortDescriptor):
                var startDate = Date()
                Log4swift[Self.self].info("sortDescriptor.ascending: '\(sortDescriptor.ascending)'")

//                var files = state.files
//                files.sort(by: { lhs, rhs in
//                    lhs.physicalSize < rhs.physicalSize
//                })
//                // 1.98 seconds first time, .155 after ...
//                Log4swift[Self.self].info("sortFiles: '\(state.files.count) nodes' in: '\(startDate.elapsedTime) ms'")
//
                startDate = Date()
                var files2 = state.files
                files2.sort(by: { lhs, rhs in
                    let left = lhs[keyPath: \.physicalSize]
                    let right = rhs[keyPath: \.physicalSize]
                    return left < right
                })
                // 2.05 seconds first time, .155 after ...
                // so key path sorting is slightly slower
                Log4swift[Self.self].info("sortFiles: '\(state.files.count) nodes' in: '\(startDate.elapsedTime) ms'")

                startDate = Date()
                state.files.sort(by: sortDescriptor.comparator)
                // 12 seconds first time, 1.5 after ...
                Log4swift[Self.self].info("sortFiles: '\(state.files.count) nodes' in: '\(startDate.elapsedTime) ms'")

                if state.selectedFiles.isEmpty {
                    // add one in here if you can
                    if state.files.count > 2 {
                        state.selectedFiles.insert(state.files[2].id)
                    }
                }
                return .none
            }
        }
    }
}

extension AppRoot.State {
    static var mock: Self {
        let rv = AppRoot.State()

        return rv
    }
}
