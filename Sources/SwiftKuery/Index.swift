/**
 Copyright IBM Corporation 2017
 
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

// MARK: Index

/// The SQL INDEX.
public struct Index {
    private var name: String
    private var isUnique: Bool
    private var table: Table
    private var columns: [IndexColumn]
    
    
    /// Initialize an instance of Index.
    ///
    /// - Parameter name: The name of the index.
    /// - Parameter isUnique: An indication whether the index has to be unique.
    /// - Parameter on table: The table of the index.
    /// - Parameter columns: An array of columns of the index.
    public init(_ name: String, isUnique: Bool = false, on table: Table, columns: [IndexColumn]) {
        self.name = name
        self.isUnique = isUnique
        self.table = table
        self.columns = columns
    }
    
    /// Create the index in the database.
    ///
    /// - Parameter connection: The connection to the database.
    /// - Parameter onCompletion: The function to be called when the execution of the query has completed.
    public func create(connection: Connection, onCompletion: @escaping ((QueryResult) -> ())) {
        var query = "CREATE INDEX "
        
        if isUnique {
            query += " UNIQUE "
        }
        
        let queryBuilder = connection.queryBuilder
        query += Utils.packName(name, queryBuilder: queryBuilder) + " ON " +  Utils.packName(table._name, queryBuilder: queryBuilder) + " ("
        query += columns.map { $0.buildIndex(queryBuilder: queryBuilder) }.joined(separator: ", ") + ")"

        connection.execute(query, onCompletion: onCompletion)
    }
    
    /// Drop the index from the database.
    ///
    /// - Parameter connection: The connection to the database.
    /// - Parameter onCompletion: The function to be called when the execution of the query has completed.
    public func drop(connection: Connection, onCompletion: @escaping ((QueryResult) -> ())) {
        var query = "DROP INDEX "
        query += Utils.packName(name, queryBuilder: connection.queryBuilder)
        connection.execute(query, onCompletion: onCompletion)
    }
}
