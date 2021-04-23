/**
 * Copyright IBM Corporation 2016, 2017, 2018, 2019
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

#if os(Linux)
    import Glibc
#elseif os(OSX)
    import Darwin
#endif

import XCTest
import Foundation
import Dispatch

@testable import SwiftKuery

class TestConnection: Connection {

    var connectionPoolConnection: ConnectionPoolConnection?

    let queryBuilder: QueryBuilder
    let result: Result

    enum Result {
        case returnEmpty
        case returnOneRow
        case returnThreeRows
        case returnError
        case returnValue
    }

    init(result: Result,
         withDeleteRequiresUsing: Bool = false,
         withUpdateRequiresFrom: Bool = false,
         createAutoIncrement: ((String, Bool) -> String)? = nil,
         addUnsignedIntegers: Bool = false,
         addTinyIntegers: Bool = false) {
        self.queryBuilder = QueryBuilder(withDeleteRequiresUsing: withDeleteRequiresUsing,
                                         withUpdateRequiresFrom: withUpdateRequiresFrom,
                                         columnBuilder: TestColumnBuilder(),
                                         addUnsignedIntegers: addUnsignedIntegers,
                                         addTinyIntegers: addTinyIntegers)
        self.result = result
    }

    func connect(onCompletion: @escaping (QueryResult) -> ()) {}

    func connectSync() -> QueryResult { return .successNoData }

    public var isConnected: Bool { return true }

    func closeConnection() {}

    func execute(query: Query, onCompletion: @escaping ((QueryResult) -> ())) {
        returnResult(onCompletion)
    }

    func execute(_ raw: String, onCompletion: @escaping ((QueryResult) -> ())) {
        returnResult(onCompletion)
    }

    func execute(query: Query, parameters: [Any?], onCompletion: @escaping ((QueryResult) -> ())) {
        returnResult(onCompletion)
    }

    func execute(_ raw: String, parameters: [Any?], onCompletion: @escaping ((QueryResult) -> ())) {
        returnResult(onCompletion)
    }

    func execute(query: Query, parameters: [String:Any?], onCompletion: @escaping ((QueryResult) -> ())) {
        returnResult(onCompletion)
    }

    func execute(_ raw: String, parameters: [String:Any?], onCompletion: @escaping ((QueryResult) -> ()))  {
        returnResult(onCompletion)
    }

    func descriptionOf(query: Query) -> String {
        do {
            let kuery = try query.build(queryBuilder: queryBuilder)
            return kuery
        }
        catch let error {
            XCTFail("Failed to build query: \(error)")
            return ""
        }
    }

    private func returnResult(_ onCompletion: @escaping ((QueryResult) -> ())) {
        DispatchQueue.global().async {
            switch self.result {
            case .returnEmpty:
                onCompletion(.successNoData)
            case .returnOneRow:
                onCompletion(.resultSet(ResultSet(TestResultFetcher(numberOfRows: 1), connection: TestConnection(result: .returnOneRow))))
            case .returnThreeRows:
                onCompletion(.resultSet(ResultSet(TestResultFetcher(numberOfRows: 3), connection: TestConnection(result: .returnThreeRows))))
            case .returnError:
                onCompletion(.error(QueryError.noResult("Error in query execution.")))
            case .returnValue:
                onCompletion(.success(5))
            }
        }
    }

    func startTransaction(onCompletion: @escaping ((QueryResult) -> ())) {}

    func commit(onCompletion: @escaping ((QueryResult) -> ())) {}

    func rollback(onCompletion: @escaping ((QueryResult) -> ())) {}

    func create(savepoint: String, onCompletion: @escaping ((QueryResult) -> ())) {}

    func rollback(to savepoint: String, onCompletion: @escaping ((QueryResult) -> ())) {}

    func release(savepoint: String, onCompletion: @escaping ((QueryResult) -> ())) {}

    struct TestPreparedStatement: PreparedStatement {}

    func prepareStatement(_ query: Query, onCompletion: @escaping ((QueryResult) -> ())) {
        onCompletion(.success(TestPreparedStatement()))
    }

    func prepareStatement(_ raw: String, onCompletion: @escaping ((QueryResult) -> ())) {
        onCompletion(.success(TestPreparedStatement()))
    }

    func execute(preparedStatement: PreparedStatement, onCompletion: @escaping ((QueryResult) -> ())) {}

    func execute(preparedStatement: PreparedStatement, parameters: [Any?], onCompletion: @escaping ((QueryResult) -> ())) {}

    func execute(preparedStatement: PreparedStatement, parameters: [String:Any?], onCompletion: @escaping ((QueryResult) -> ())) {}

    func release(preparedStatement: PreparedStatement, onCompletion: @escaping ((QueryResult) -> ())) {}
}

class TestResultFetcher: ResultFetcher {
    let numberOfRows: Int
    let rows = [["banana", 38, "apple"], ["apple", -8, "peach"], ["plum", 7, "plum"]]
    let titles = ["fruit", "number", "fruit"]
    var fetched = 0

    init(numberOfRows: Int) {
        self.numberOfRows = numberOfRows
    }

    func fetchNext(callback: @escaping (([Any?]?, Error?)) -> ()) {
        DispatchQueue.global().async {
            if self.fetched < self.numberOfRows {
                self.fetched += 1
                return callback((self.rows[self.fetched - 1], nil))
            }
            return callback((nil,nil))
        }
    }

    func done() {
        return
    }

    func fetchTitles(callback: @escaping (([String]?, Error?)) -> ()) {
        DispatchQueue.global().async {
            callback((self.titles, nil))
        }
    }
}

func createConnection(_ result: TestConnection.Result) -> TestConnection {
    return TestConnection(result: result)
}

func createConnection(withDeleteRequiresUsing: Bool = false,
                      withUpdateRequiresFrom: Bool = false,
                      createAutoIncrement: ((String, Bool) -> String)? = nil,
                      addUnsignedIntegers: Bool = false,
                      addTinyIntegers: Bool = false) -> TestConnection {
    return TestConnection(result: .returnEmpty,
                          withDeleteRequiresUsing: withDeleteRequiresUsing,
                          withUpdateRequiresFrom: withUpdateRequiresFrom,
                          createAutoIncrement: createAutoIncrement,
                          addUnsignedIntegers: addUnsignedIntegers,
                          addTinyIntegers: addTinyIntegers)
}

// Dummy class for test framework
class CommonUtils {

    // Utility method that returns the column titles from a ResultSet in a synchronous manner
    static func getTitles(resultSet: ResultSet) -> [String] {
        var titles = [String]()
        let waitLock = DispatchSemaphore(value: 0)
        resultSet.getColumnTitles() { columnTitles, error in
            guard let columnTitles = columnTitles else {
                waitLock.signal()
                return
            }
            titles = columnTitles
            waitLock.signal()
            return
        }
        waitLock.wait()
        return titles
    }

    // Utility method that returns all rows of a ResultSet in a synchronous manner
    static func getRows(queryResult: QueryResult) -> [[String: Any?]]? {
        var rows: [[String: Any?]]? = nil
        guard let _ = queryResult.asResultSet else {
            return rows
        }
        let waitLock = DispatchSemaphore(value: 0)
        queryResult.asRows() { result, error in
            guard let result = result else {
                waitLock.signal()
                return
            }
            rows = result
            waitLock.signal()
            return
        }
        waitLock.wait()
        return rows
    }
}

class TestColumnBuilder : ColumnCreator {
    public func buildColumn(for column: Column, using queryBuilder: QueryBuilder) -> String? {
        guard let type = column.type else {
            return nil
        }

        var result = Utils.packName(column.name, queryBuilder: queryBuilder) + " "

        var typeString = type.create(queryBuilder: queryBuilder)
        if let length = column.length {
            typeString += "(\(length))"
        }
        if column.autoIncrement {
            result += typeString + " AUTO_INCREMENT"
        } else {
            result += typeString
        }

        if column.isPrimaryKey {
            result += " PRIMARY KEY"
        }
        if column.isNotNullable {
            result += " NOT NULL"
        }
        if column.isUnique {
            result += " UNIQUE"
        }
        if let defaultValue = getDefaultValue(for: column, queryBuilder: queryBuilder) {
            result += " DEFAULT " + defaultValue
        }
        if let checkExpression = column.checkExpression {
            result += checkExpression.contains(column.name) ? " CHECK (" + checkExpression.replacingOccurrences(of: column.name, with: "\"\(column.name)\"") + ")" : " CHECK (" + checkExpression + ")"
        }
        if let collate = column.collate {
            result += " COLLATE \"" + collate + "\""
        }
        return result
    }
}
