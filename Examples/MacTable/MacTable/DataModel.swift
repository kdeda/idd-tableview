//
//  DataModel.swift
//  MacTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import TableView

struct Result: Codable {
    var results: [Car]
}

/// Model with data from internet
///
/// From https://www.back4app.com/database/back4app/car-make-model-dataset/get-started/swift/rest-api/urlsession?objectClassSlug=tesla
struct Car: Codable {
    var id: String
    var year: Int
    var make: String
    var model: String
    var category: String
//    var createdAt": "2020-01-27T22:18:08.398Z",
//    var updatedAt": "2020-01-27T22:18:08.398Z"

    private enum CodingKeys: String, CodingKey {
        case id = "objectId"
        case year = "Year"
        case make = "Make"
        case model = "Model"
        case category = "Category"
    }
    
    var extraColumn: String {
        "\(make) - \(model)"
    }
}

extension Car: Equatable {}
extension Car: Identifiable {}
extension Car: Hashable {}
extension Car: Comparable {
    static func < (lhs: Car, rhs: Car) -> Bool {
        false
    }
}

struct Store {
    static var dateFormat: DateFormatter = {
        let rv = DateFormatter.init()
        
        rv.dateFormat = "MM/dd/yyyy"
        return rv
    }()

    static var cars: [Car] {
        guard let url = Bundle.main.url(forResource: "cars", withExtension: "json")
        else {
            Log4swift[Self.self].error("please define the json file 'cars.json'")
            return [] }
        
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            let result = try decoder.decode(Result.self, from: data)
            var initialArray = result.results
            
            let rv = (0 ..< 1).reduce(into: [Car]()) { partialResult, nextItem in
                let newValues: [Car] = initialArray.map { car in
                    var newCar = car
                    newCar.id = car.id + "\(nextItem)"
                    return newCar
                }
                partialResult.append(contentsOf: newValues)
            }
            return rv
        } catch let error {
            Log4swift[Self.self].error("filePath: \(url.path)")
            Log4swift[Self.self].error("error: \(error)")
        }

        return []
    }

    static let car1 = cars[0]
    static let car2 = cars[1]
}
