/**
 Copyright IBM Corporation 2016, 2017
 
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
class TestSelect: XCTestCase {
    
    static var allTests: [(String, (TestSelect) -> () throws -> Void)] {
        return [
            ("testSelect", testSelect),
            ("testSelectWith", testSelectWith),
            ("testSelectCount", testSelectCount),
        ]
    }
    
    class MyTable : Table {
        let a = Column("a")
        let b = Column("b")
        
        let tableName = "tableSelect"
    }
    
    class MyTable2 : Table {
        let c = Column("c")
        let b = Column("b")
        
        let tableName = "tableSelect2"
    }
    
    class MyTable3 : Table {
        let d = Column("d")
        let b = Column("b")
        
        let tableName = "tableSelect3"
    }
  
    func testSelect() {
        let t = MyTable()
        let connection = createConnection()
        
        var s = Select(from: t)
        var kuery = connection.descriptionOf(query: s)
        var query = "SELECT * FROM \"tableSelect\""
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        s = Select.distinct(t.a, from: t)
            .where(t.a.notLike("b%").isNotNull())
            .limit(to: 3)
            .offset(2)
        kuery = connection.descriptionOf(query: s)
        query = "SELECT DISTINCT \"tableSelect\".\"a\" FROM \"tableSelect\" WHERE (\"tableSelect\".\"a\" NOT LIKE 'b%') IS NOT NULL LIMIT 3 OFFSET 2"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        s = Select.distinct(t.a, from: t)
            .where(t.a.notLike("b%").isNull())
            .limit(to: 3)
            .offset(2)
        kuery = connection.descriptionOf(query: s)
        query = "SELECT DISTINCT \"tableSelect\".\"a\" FROM \"tableSelect\" WHERE (\"tableSelect\".\"a\" NOT LIKE 'b%') IS NULL LIMIT 3 OFFSET 2"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
 
        s = Select(t.b, t.a, from: t)
            .where(((t.a == "banana") || (ucase(t.a) == "APPLE")) && (t.b == 27 || t.b == -7 || t.b == 17))
            .order(by: [.ASC(t.b), .DESC(t.a)])
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"b\", \"tableSelect\".\"a\" FROM \"tableSelect\" WHERE ((\"tableSelect\".\"a\" = 'banana') OR (UCASE(\"tableSelect\".\"a\") = 'APPLE')) AND (((\"tableSelect\".\"b\" = 27) OR (\"tableSelect\".\"b\" = -7)) OR (\"tableSelect\".\"b\" = 17)) ORDER BY \"tableSelect\".\"b\" ASC, \"tableSelect\".\"a\" DESC"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        s = Select(t.a, from: t)
            .where((t.b >= 0.76).isNotNull())
            .group(by: t.a)
            .order(by: .DESC(t.a))
            .having(sum(t.b) > 3 || t.b.isNull())
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"a\" FROM \"tableSelect\" WHERE (\"tableSelect\".\"b\" >= 0.76) IS NOT NULL GROUP BY \"tableSelect\".\"a\" HAVING (SUM(\"tableSelect\".\"b\") > 3) OR (\"tableSelect\".\"b\" IS NULL) ORDER BY \"tableSelect\".\"a\" DESC"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
 
        s = Select(t.a, from: t)
            .group(by: t.a)
            .having((last(t.b) > 0).isNull())
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"a\" FROM \"tableSelect\" GROUP BY \"tableSelect\".\"a\" HAVING (LAST(\"tableSelect\".\"b\") > 0) IS NULL"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")

        s = Select(t.a, from: t)
            .group(by: t.a)
            .having((last(t.b) > 0).isNotNull())
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"a\" FROM \"tableSelect\" GROUP BY \"tableSelect\".\"a\" HAVING (LAST(\"tableSelect\".\"b\") > 0) IS NOT NULL"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")

        s = Select(t.a, from: t)
            .group(by: [t.a])
            .having(last(t.b).isNull())
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"a\" FROM \"tableSelect\" GROUP BY \"tableSelect\".\"a\" HAVING LAST(\"tableSelect\".\"b\") IS NULL"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")

        s = Select(t.a, from: t)
            .group(by: t.a)
            .having(last(t.b).isNotNull())
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"a\" FROM \"tableSelect\" GROUP BY \"tableSelect\".\"a\" HAVING LAST(\"tableSelect\".\"b\") IS NOT NULL"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")

        s = Select(RawField("left(a, 2) as raw"), from: t)
            .where("b >= 0")
            .group(by: t.a)
            .order(by: .DESC(t.a))
            .having("sum(b) > 3")
        kuery = connection.descriptionOf(query: s)
        query = "SELECT left(a, 2) as raw FROM \"tableSelect\" WHERE b >= 0 GROUP BY \"tableSelect\".\"a\" HAVING sum(b) > 3 ORDER BY \"tableSelect\".\"a\" DESC"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        s = Select(t.a, RawField("b").as("bb"), from: t)
            .limit(to: 2)
            .order(by: .DESC(t.a))
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"a\", b AS \"bb\" FROM \"tableSelect\" ORDER BY \"tableSelect\".\"a\" DESC LIMIT 2"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        s = Select(ucase(t.a).as("case"), t.b, from: t)
            .where(t.a.between("apra", and: "aprt"))
        kuery = connection.descriptionOf(query: s)
        query = "SELECT UCASE(\"tableSelect\".\"a\") AS \"case\", \"tableSelect\".\"b\" FROM \"tableSelect\" WHERE \"tableSelect\".\"a\" BETWEEN 'apra' AND 'aprt'"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        s = Select(from: t)
            .where(t.a.in("apple", "lalala"))
        kuery = connection.descriptionOf(query: s)
        query = "SELECT * FROM \"tableSelect\" WHERE \"tableSelect\".\"a\" IN ('apple', 'lalala')"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        s = Select(from: t)
            .where("a IN ('apple', 'lalala')")
        kuery = connection.descriptionOf(query: s)
        query = "SELECT * FROM \"tableSelect\" WHERE a IN ('apple', 'lalala')"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        let t2 = MyTable2()
        let t3 = MyTable3()
        
        s = Select(from: [t2, t3, t])
            .where((t2.b == t3.b) && (t2.b == t.b))
        kuery = connection.descriptionOf(query: s)
        query = "SELECT * FROM \"tableSelect2\", \"tableSelect3\", \"tableSelect\" WHERE (\"tableSelect2\".\"b\" = \"tableSelect3\".\"b\") AND (\"tableSelect2\".\"b\" = \"tableSelect\".\"b\")"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        s = Select(t.a, from: t)
            .where(len(ucase(t.a)) == 5 || ucase(lcase(t.a)) == "BANANA" || lcase(ucase(t.a)) == "banana")
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"a\" FROM \"tableSelect\" WHERE ((LEN(UCASE(\"tableSelect\".\"a\")) = 5) OR (UCASE(LCASE(\"tableSelect\".\"a\")) = 'BANANA')) OR (LCASE(UCASE(\"tableSelect\".\"a\")) = 'banana')"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")

        s = Select(t.a, from: t)
            .where(len(t.a) >= round(len(t.b), to: 2) && mid(ucase(t.b), start: 3, length: 2) == t.a)
        kuery = connection.descriptionOf(query: s)
        query = "SELECT \"tableSelect\".\"a\" FROM \"tableSelect\" WHERE (LEN(\"tableSelect\".\"a\") >= ROUND(LEN(\"tableSelect\".\"b\"), 2)) AND (MID(UCASE(\"tableSelect\".\"b\"), 3, 2) = \"tableSelect\".\"a\")"
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
    }
    
    func testSelectWith() {
        let t = MyTable()
        let t2 = MyTable2()
        let connection = createConnection()
        
        class AuxTable: AuxiliaryTable {
            let tableName = "aux_table"
            
            let d = Column("d")
            let f = Column("f")
        }
        
        var withTable = AuxTable(as: Select(t2.c.as("d"), t2.b.as("f"), from: t2))
        
        var s = with(withTable, Select(withTable.d, t.a, from: t).join(withTable).on(t.b == withTable.f))
        let kuery = connection.descriptionOf(query: s)
        let query = "WITH \"aux_table\" AS (SELECT \"tableSelect2\".\"c\" AS \"d\", \"tableSelect2\".\"b\" AS \"f\" FROM \"tableSelect2\") SELECT \"aux_table\".\"d\", \"tableSelect\".\"a\" FROM \"tableSelect\" JOIN \"aux_table\" ON \"tableSelect\".\"b\" = \"aux_table\".\"f\""
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
        
        withTable = AuxTable()
        s = with(withTable, Select(withTable.d, t.a, from: t).join(withTable).on(t.b == withTable.f))
        do {
            let _ = try s.build(queryBuilder: connection.queryBuilder)
            XCTFail("No syntax error.")
        } catch QueryError.syntaxError(let error) {
            XCTAssertEqual(error, "With query was not specified. ")
        } catch {
            XCTFail("Other than syntax error.")
        }
        
        s = with(withTable, s)
        do {
            let _ = try s.build(queryBuilder: connection.queryBuilder)
            XCTFail("No syntax error.")
        } catch QueryError.syntaxError(let error) {
            XCTAssertEqual(error, "Multiple with clauses. ")
        } catch {
            XCTFail("Other than syntax error.")
        }
    }

    func testSelectCount() {
        let t = MyTable()
        let connection = createConnection()
        
        var s = Select.count(from: t)
        var kuery = connection.descriptionOf(query: s)
        var query = "SELECT COUNT(id) FROM \"tableSelect\""
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")

        s = Select.count(t.a, from: t)
        kuery = connection.descriptionOf(query: s)
        query = "SELECT COUNT(\"tableSelect\".\"a\") FROM \"tableSelect\""
        XCTAssertEqual(kuery, query, "\nError in query construction: \n\(kuery) \ninstead of \n\(query)")
    }
}
