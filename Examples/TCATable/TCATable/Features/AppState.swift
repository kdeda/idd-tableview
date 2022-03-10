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
import SwiftUI

/// This is the state for the TableView
struct AppState: Equatable, Identifiable {
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

struct FileClient {
    /// Given a url, return all files under it
    let fetchFiles: (_ url: URL) -> AnyPublisher<[File], Never>
}

extension FileClient {
    static var live: Self {
        return Self(
            fetchFiles: { url in
                let rv = Deferred { Just(url) }
                    .map(\.contentsOfDirectory)
                    .map { $0.map(File.init) }
                    .map { files -> [File] in
                        let fileCount = files.count
                        let desiredFinalCount = 100_000 // this is how much we want to end up with
                        // as we increase this number things start to lag ...
                        let multiplier = 1 + desiredFinalCount / fileCount

                        // multiply the initial array by x to generate more value for performance testing
                        let rv = (0 ..< multiplier).reduce(into: [File]()) { partialResult, nextItem in
                            let newValues: [File] = files.map { file in
                                var newCopy = file
                                newCopy.filePath = file.id + "\(nextItem)"
                                newCopy.logicalSize += newCopy.logicalSize * Int64(nextItem)
                                newCopy.physicalSize += newCopy.physicalSize * Int64(nextItem)
                                return newCopy
                            }
                            partialResult.append(contentsOf: newValues)
                        }
                        return rv
                    }
                    .eraseToAnyPublisher()
                return rv
            }
        )
    }
}

extension FileClient {
    static var mock: Self {
        return Self(
            fetchFiles: { url in
                 let logFileURLs: [URL] = {
                    let root = URL.iddHomeDirectory.appendingPathComponent("Library/Logs")
                    let filePaths = FileManager.default.subpaths(atPath: root.path) ?? []
                    let logURLs = filePaths
                        .map(root.appendingPathComponent)
                        .filter { $0.pathExtension == "log" }
                    
                    let lowerRange = max(0, logURLs.count - 3)
                    return Array(logURLs[lowerRange..<logURLs.count])
                }()
                
                let files = logFileURLs
                    .map(\.path)
                    .map(URL.init(fileURLWithPath:))
                // This will cause the URLs to reload fresh and thus produce the latest info, such as logicalSize or modificationDate
                    .map(File.init)

                // there should be at most 3 items here ...
                return Just(files)
                    .eraseToAnyPublisher()
            }
        )
    }
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var uuid: () -> UUID
    var fileClient: FileClient
}

extension AppState {
    static let reducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
        Reducer { state, action, environment in
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

                /**
                 Start fetching files under ~/Desktop ...
                 This works because we removed entitlements
                 */
                let rv = environment
                    .fileClient
                    .fetchFiles(URL(fileURLWithPath: NSHomeDirectory()))
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
                
                return .none
            }
        }
            .binding()
    )
    
}

extension AppState {
    static let live = Store<AppState, AppAction>(
        initialState: .init(),
        reducer: reducer,
        environment: AppEnvironment(
            mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
            uuid: UUID.init,
            fileClient: FileClient.live
        )
    )
    
    static let mock = {
        Store<AppState, AppAction>(
            initialState: .init(),
            reducer: reducer,
            environment: AppEnvironment(
                mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                uuid: UUID.init,
                fileClient: FileClient.mock
            )
        )
    }()
}
