/**
 Copyright IBM Corporation 2017, 2018, 2019

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

import XCTest

@testable import SwiftKuery
class TestSchema: XCTestCase {

    static var allTests: [(String, (TestSchema) -> () throws -> Void)] {
        return [
            ("testMultipleForeignKeys", testMultipleForeignKeys),
            ("testCreateTable", testCreateTable),
        ]
    }

    class Table1: Table {
        let tableName = "table1"
        let a = Column("a", String.self, primaryKey: true, defaultValue: "qiwi", collate: "en_US")
        let b = Column("b", Int32.self, autoIncrement: true)
        let c = Column("c", Double.self, defaultValue: 4.95, check: "c > 0")
    }

    class Table2: Table {
        let tableName = "table2"
        let a = Column("a", Varchar.self, primaryKey: false, unique: false)
        let b = Column("b", Varchar.self, length: 20, unique: true)
        let c = Column("c", Int16.self, notNull: true)
        let d = Column("d", Int32.self)
        let e = Column("e", SQLDate.self)
        let f = Column("f", Timestamp.self)
        let g = Column("g", MySQLType.self, length: 15)
    }

    struct MySQLType: SQLDataType {
        public static func create(queryBuilder: QueryBuilder) -> String {
            return "mySQLType"
        }
    }

    class Table3: Table {
        let tableName = "table3"
        let a = Column("a", String.self, primaryKey: true, defaultValue: "qiwi", collate: "en_US")
        let b = Column("b", Int32.self, autoIncrement: true, primaryKey: true)
        let c = Column("c", Double.self, defaultValue: 4.95, check: "c > 0")
    }

    class Table4: Table {
        let tableName = "table4"
        let a = Column("a", Char.self, length: 20)
        let b = Column("b", Int64.self)
        let c = Column("c", Float.self)
        let d = Column("d", Bool.self)
        let e = Column("e", Time.self)
    }

    class Table5: Table {
        let tableName = "table5"
        let a = Column("a", Char.self)
        let b = Column("b")
    }

    class Table6: Table {
        let tableName = "table6"
        let a = Column("a", String.self, defaultValue: nil, nullDefaultValue: true)
    }

    func testMultipleForeignKeys() {
        let connection = createConnection()

        var t1 = Table1()
        var t2 = Table2()

        // This tests a one to one foreign key
        var createStmt = createTable(t1.foreignKey(t1.a, references: t2.b), connection: connection)
        var expectedCreateStmt = "CREATE TABLE \"table1\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0), FOREIGN KEY (\"a\") REFERENCES \"table2\"(\"b\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        // Need to reset tables
        t1 = Table1()
        t2 = Table2()

        // This tests that multiple foreign keys can be added for the one to one case
        createStmt = createTable(t1.foreignKey(t1.a, references: t2.b).foreignKey(t1.b, references: t2.a), connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table1\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0), FOREIGN KEY (\"a\") REFERENCES \"table2\"(\"b\"), FOREIGN KEY (\"b\") REFERENCES \"table2\"(\"a\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        // Need to reset tables
        t1 = Table1()
        t2 = Table2()

        // This tests that duplicate foreign keys are ignored for the one to one case
        createStmt = createTable(t1.foreignKey(t1.a, references: t2.b).foreignKey(t1.a, references: t2.b), connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table1\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0), FOREIGN KEY (\"a\") REFERENCES \"table2\"(\"b\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        // Need to reset tables
        t1 = Table1()
        t2 = Table2()

        // This tests a many to many foreign key (composite keys do not support different reference tables)
        createStmt = createTable(t1.foreignKey([t1.a, t1.b], references: [t2.b, t2.a]), connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table1\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0), FOREIGN KEY (\"a\", \"b\") REFERENCES \"table2\"(\"b\", \"a\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        // Need to reset tables
        t1 = Table1()
        t2 = Table2()

        // This tests mulitple foreign keys can be added for the many to many case
        createStmt = createTable(t1.foreignKey([t1.a, t1.b], references: [t2.b, t2.a]).foreignKey([t1.a, t1.c], references: [t2.b, t2.a]), connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table1\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0), FOREIGN KEY (\"a\", \"b\") REFERENCES \"table2\"(\"b\", \"a\"), FOREIGN KEY (\"a\", \"c\") REFERENCES \"table2\"(\"b\", \"a\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        // Need to reset tables
        t1 = Table1()
        t2 = Table2()

        // This tests that duplicate foreign keys are ignored for the many to many case
        createStmt = createTable(t1.foreignKey([t1.a, t1.b], references: [t2.b, t2.a]).foreignKey([t1.a, t1.b], references: [t2.b, t2.a]), connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table1\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0), FOREIGN KEY (\"a\", \"b\") REFERENCES \"table2\"(\"b\", \"a\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        // Need to reset tables
        t1 = Table1()
        t2 = Table2()

        // This tests that duplicate foreign keys are ignored for the many to many case irrespective of key ordering
        createStmt = createTable(t1.foreignKey([t1.a, t1.b], references: [t2.b, t2.a]).foreignKey([t1.b, t1.a], references: [t2.b, t2.a]), connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table1\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0), FOREIGN KEY (\"a\", \"b\") REFERENCES \"table2\"(\"b\", \"a\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")
    }

    func testCreateTable () {
        let connection = createConnection()

        var t1 = Table1()
        var createStmt = createTable(t1, connection: connection)
        var expectedCreateStmt = "CREATE TABLE \"table1\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        t1 = Table1(name: "foobar")
        createStmt = createTable(t1, connection: connection)
        expectedCreateStmt = "CREATE TABLE \"foobar\" (\"a\" text PRIMARY KEY DEFAULT 'qiwi' COLLATE \"en_US\", \"b\" integer AUTO_INCREMENT, \"c\" double DEFAULT 4.95 CHECK (\"c\" > 0))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        let t2 = Table2()
        createStmt = createTable(t2, connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table2\" (\"a\" varchar, \"b\" varchar(20) UNIQUE, \"c\" smallint NOT NULL, \"d\" integer, \"e\" date, \"f\" timestamp, \"g\" mySQLType(15))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        let t3 = Table3()
        var error = createBadTable(t3, connection: connection)
        var expectedError = "Conflicting definitions of primary key. "
        XCTAssertEqual(error, expectedError)

        error = createBadTable(t1.primaryKey(t1.b, t1.c), connection: connection)
        expectedError = "Conflicting definitions of primary key. "
        XCTAssertEqual(error, expectedError)

        createStmt = createTable(t2.primaryKey([t2.b, t2.c]), connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table2\" (\"a\" varchar, \"b\" varchar(20) UNIQUE, \"c\" smallint NOT NULL, \"d\" integer, \"e\" date, \"f\" timestamp, \"g\" mySQLType(15), PRIMARY KEY (\"b\", \"c\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        var t4 = Table4()
        createStmt = createTable(t4.primaryKey(t4.b).foreignKey(t4.a, references: t2.b), connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table4\" (\"a\" char(20), \"b\" bigint, \"c\" real, \"d\" boolean, \"e\" time, PRIMARY KEY (\"b\"), FOREIGN KEY (\"a\") REFERENCES \"table2\"(\"b\"))"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")

        t4 = Table4()
        error = createBadTable(t4.primaryKey(t1.b, t1.c), connection: connection)
        expectedError = "Primary key contains columns from another table. "
        XCTAssertEqual(error, expectedError)

        t1 = Table1()
        t4 = Table4()
        error = createBadTable(t4.foreignKey(t1.b, references: t1.c), connection: connection)
        expectedError = "Foreign key contains columns from another table. "
        XCTAssertEqual(error, expectedError)

        t4 = Table4()
        error = createBadTable(t4.foreignKey([t4.b, t4.a], references: [t2.a, t1.a]), connection: connection)
        expectedError = "Foreign key references columns from more than one table. "
        XCTAssertEqual(error, expectedError)

        t4 = Table4()
        error = createBadTable(t4.foreignKey([t4.b, t4.a], references: [t2.a]), connection: connection)
        expectedError = "Invalid definition of foreign key. "
        XCTAssertEqual(error, expectedError)

        t4 = Table4()
        error = createBadTable(t4.primaryKey([]), connection: connection)
        expectedError = "Empty primary key. "
        XCTAssertEqual(error, expectedError)

        t4 = Table4()
        error = createBadTable(t4.primaryKey(t2.a).foreignKey([], references: [t2.a]), connection: connection)
        expectedError = "Primary key contains columns from another table. Invalid definition of foreign key. "
        XCTAssertEqual(error, expectedError)

        let t5 = Table5()
        error = createBadTable(t5, connection: connection)
        expectedError = "Invalid column attributes for column b. "
        XCTAssertEqual(error, expectedError)

        let nilValueTable = Table6()
        createStmt = createTable(nilValueTable, connection: connection)
        expectedCreateStmt = "CREATE TABLE \"table6\" (\"a\" text DEFAULT NULL)"
        XCTAssertEqual(createStmt, expectedCreateStmt, "\nError in table creation: \n\(createStmt) \ninstead of \n\(expectedCreateStmt)")
    }

    private func createTable(_ table: Table, connection: Connection) -> String {
        do {
            let stmt = try table.description(connection: connection)
            return stmt
        }
        catch let error {
            XCTFail("Failed to create table: \(error)")
            return ""
        }
    }

    private func createBadTable(_ table: Table, connection: Connection) -> String {
        do {
            let stmt = try table.description(connection: connection)
            XCTFail("Table creation should fail, incorrectly generated: \(stmt)")
            return ""
        }
        catch let error {
            return "\(error)"
        }
    }

}
