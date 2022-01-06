//
//  AppState.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Combine
import ComposableArchitecture
import Log4swift
import TableView

/// This is the state for the TableView
struct AppState: Equatable, Identifiable {
    let id = UUID()
    var isAppReady = false
    var files: [File] = []
    @BindableState var selectedFiles: Set<File.ID> = []
    @BindableState var sortDescriptors: [TableColumnSort<File>] = [
        .init(\.physicalSize)
    ]
    
    // To support the pure Table from macOS 12
    @BindableState var sortOrder: [TableColumnSort<File>] = [
        .init(\.physicalSize)
    ]
}

extension File: Comparable {
    static func < (lhs: File, rhs: File) -> Bool {
        false
    }
}

enum AppAction: BindableAction, Equatable {
    case binding(BindingAction<AppState>)
    case appDidStart
    case setFiles([File])
    case selectedFilesDidChange([File])
    case sortFiles(TableColumnSort<File>)
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var uuid: () -> UUID
    
    func fetchFiles(_ url: URL) -> AnyPublisher<[File], Never> {
        let rv = Deferred { Just(url) }
            .map(\.contentsOfDirectory)
            .map { $0.map(File.init) }
            .eraseToAnyPublisher()
        return rv
    }
}

extension AppState {
    static let reducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
        Reducer { state, action, environment in
            switch action {
            case .binding(\.$selectedFiles):
                let files = state.files.filter { state.selectedFiles.contains($0.id) }
                return Effect(value: .selectedFilesDidChange(files))

            case .binding(\.$sortDescriptors):
                return Effect(value: .sortFiles(state.sortDescriptors[0]))
                
            case .binding(\.$sortOrder):
                let sortDescriptor = state.sortDescriptors[0]
                let files = state.files.sorted(by: sortDescriptor.comparator)
                state.files = files
                return .none

            case .binding:
                return .none
                
            case .appDidStart where !state.isAppReady:
                state.isAppReady = true

                /**
                 Start fetching files under ~/Desktop ...
                 This works because we removed entitlements
                 */
                let rv = environment.fetchFiles(URL.iddHomeDirectory.appendingPathComponent("Desktop"))
                    .delay(for: 1, scheduler: environment.mainQueue)
                    .eraseToEffect()
                    .map(AppAction.setFiles)
                // .cancellable(id: FileMonitorID(), cancelInFlight: true)
                return rv
                
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
                Log4swift[Self.self].info("sortDescriptor.ascending: '\(sortDescriptor.ascending)'")
                
                state.files = state.files.sorted(by: sortDescriptor.comparator)
                return .none
            }
        }
            .binding()
    )
    
}

extension AppState {
    static let logFileURLs: [URL] = {
        let root = URL.iddHomeDirectory.appendingPathComponent("Library/Logs")
        let filePaths = FileManager.default.subpaths(atPath: root.path) ?? []
        let logURLs = filePaths
            .map(root.appendingPathComponent)
            .filter { $0.pathExtension == "log" }
        
        let lowerRange = max(0, logURLs.count - 3)
        return Array(logURLs[lowerRange..<logURLs.count])
    }()

    /// This will cause the URLs to reload and thus produce the latest info, such as logicalSize or modificationDate
    static var logFiles: [File] {
        logFileURLs.map(\.path).map(URL.init(fileURLWithPath:)).map(File.init)
    }

    static let liveStore = Store<AppState, AppAction>(
        initialState: .init(),
        reducer: reducer,
        environment: AppEnvironment(
            mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
            uuid: UUID.init
        )
    )
    
    static let mockupStore = {
        Store<AppState, AppAction>(
            initialState: .init(
                files: logFiles,
                selectedFiles: Set([logFiles[0].id])
            ),
            reducer: reducer,
            environment: AppEnvironment(
                mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                uuid: UUID.init
            )
        )
    }()
}
