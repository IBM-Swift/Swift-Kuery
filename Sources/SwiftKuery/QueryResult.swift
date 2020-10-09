/**
 Copyright IBM Corporation 2016
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

// MARK: QueryResult

/// The result of an execution of a query.
public enum QueryResult {
    /// An error occurred while executing the query.
    case error(Error)
    /// The result of the query execution as an a `ResultSet`.
    case resultSet(ResultSet)
    /// Indicates the query executed successfully and returned data.
    case success(Any)
    /// Indicates the query executed successfully and returned no data.
    case successNoData
    
    /// Indicates the query executed successfully.
    public var success: Bool {
        switch self {
        case .error:
            return false
        default:
            return true
        }
    }
        
    /// Data received from the query execution represented as a `ResultSet`.
    public var asResultSet: ResultSet? {
        switch self {
        case .resultSet(let resultSet):
            return resultSet
        default:
            return nil
        }
    }
    
    /// Data received from the query execution represented as a `PreparedStatement`.
    public var asPreparedStatement: PreparedStatement? {
        switch self {
        case .success(let value):
            if let statement = value as? PreparedStatement {
                return statement
            }
            return nil
        default:
            return nil
        }
    }

    /// The error that occurred during query execution.
    public var asError: Error? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
    
    /// The result of the query execution as a single value.
    public var asValue: Any? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }
    
    /// Passes data received from the query execution represented as an array of dictionaries to a user defined completion handler.
    /// Each entry in the array repersents a row in the result with column titles as the keys.
    /// In case there are columns with the same title, we add indices to the keys: for example if
    /// the result contains three columns named 'a', the dictionary will contain the keys: a, a.1 and a.2.
    /// This function will consume the entire set of results and then call done against the result set which will allow the underlying connection to be reused.
    /// When asRows is called a user does not need to explicitly invoke the done method on the result set.
    public func asRows(onCompletion: @escaping (([[String:Any?]]?, Error?)) -> ()) {
        switch self {
        case .resultSet(let resultSet):
            resultSet.getColumnTitles() { titles, error in
                guard let columnTitles = titles else {
                    guard let error = error else {
                        resultSet.done()
                        return onCompletion((nil, QueryError.noResult("Unable to retrieve Column titles")))
                    }
                    resultSet.done()
                    return onCompletion((nil, QueryError.noResult(error.localizedDescription)))
                }
                return self.processRows(resultSet, titles: columnTitles, result: nil, onCompletion: onCompletion)
            }
            return
        case .successNoData:
            return onCompletion((nil, QueryError.noResult("Operation was successful but no results returned.")))
        case .error(let error):
            return onCompletion((nil, QueryError.noResult("Result is an error: \(error.localizedDescription)")))
        case .success:
            return onCompletion((nil, QueryError.noResult("Result not a result set, cannot retrieve rows.")))
        }
    }

    // This function will recursively iterate the rows in the result set and generate a dictionary of tilese:values for each.
    // These dictionaries are appended to to an array which is passed to the users completion handler once all rows have been processed.
    private func processRows(_ resultSet: ResultSet, titles: [String], result: [[String:Any?]]?, onCompletion: @escaping (([[String:Any?]]?, Error?)) -> ()) {
        resultSet.nextRow() { row, error in
            guard let row = row else {
                guard let error = error else {
                    // We have run out of rows so need to return the results and explicitly close the result set allowing the release of the underlying connection.
                    resultSet.done()
                    return onCompletion((result ?? [], nil))
                }
                resultSet.done()
                return onCompletion((nil, QueryError.noResult("Error fetching row: \(error.localizedDescription)")))
            }
            guard row.count == titles.count else {
                // Column titles and value counts do not match
                resultSet.done()
                return onCompletion((nil, QueryError.noResult("Number of titles does not match number of values for row, unable to retrieve rows.")))
            }
            // myTitles will be updated with new column titles when a title collision occurs, for example if a JOIN results in columns from different table with the same name being included in the results. myTitles is then passed into the recursive call of processRows meaning we will only ever run collision handling when processing the first row of the results.
            var myTitles = titles
            var dictionary = [String:Any?]()
            var index = 0
            for title in titles {
                if dictionary[title] == nil {
                    dictionary[title] = row[index]
                } else {
                    // In case we have a collision on key names.
                    var i = 1
                    while (dictionary[title + ".\(i)"] != nil) {
                        i = i + 1
                    }
                    let newTitle = title + ".\(i)"
                    dictionary[newTitle] = row[index]
                    myTitles[index] = newTitle
                }
                index += 1
            }
            var newResult = result != nil ? result : [[String:Any?]]()
            newResult?.append(dictionary)
            return self.processRows(resultSet, titles: myTitles, result: newResult, onCompletion: onCompletion)
        }
    }
}
