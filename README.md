<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://ibm-swift.github.io/Swift-Kuery/index.html">
    <img src="https://img.shields.io/badge/apidoc-SwiftKuery-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/Swift-Kuery">
    <img src="https://travis-ci.org/IBM-Swift/Swift-Kuery.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# Swift-Kuery

`Swift-Kuery` is a pluggable SQL database driver/SDK abstraction layer. Its main idea is to unify the APIs to the various relational databases, providing a Swifty yet SQL-like API. This allows easy switching between databases and forms the basis for an Object-Relational Mapping (ORM) framework.

[Swift-Kuery-ORM](https://github.com/IBM-Swift/Swift-Kuery-ORM) is an ORM, built on top of Swift-Kuery, which allows you to simplify the persistence of model objects with your server.

`Swift-Kuery` is an easy to learn, consumable framework that comes with a set of [implemented plugins](#list-of-plugins).

## Table of Contents
* [Swift version](#swift-version)
* [Usage](#usage)
* [SQL Injection Prevention using Parameterization](#sql-injection-prevention-using-parameterization)
* [Prepared Statements](#prepared-statements)
* [Schema Management](#schema-management)
* [Query Examples](#query-examples)
* [List of plugins](#list-of-plugins)
* [API Reference](#api-reference)
* [Community](#community)
* [License](#license)

## Swift version
The latest version of Swift-Kuery requires **Swift 4.0** or newer. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Usage
This example demonstrates how to execute an SQL query using `Swift-Kuery` with the [Swift-Kuery-PostgreSQL](https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL) plugin.

The starting point for this example is an existing Swift package. If you don't have one already, create and enter a directory named e.g. `SwiftKueryExample`. Now run the swift package's init command, to create an executable type, by running `swift package init --type executable`.

### Creating A PostgreSQL Database

1. Install PostgreSQL
#### Mac
`brew install postgresql`
#### Ubuntu Linux
`sudo apt-get install postgresql postgresql-contrib`

2. Create a `school` database
    ```
    createdb school
    psql school
    ```

3. Create a `grades` table
    ```
    CREATE TABLE "Grades" (
        id varchar(100) PRIMARY KEY,
        course text NOT NULL,
        grade integer
    );  
    ```

### Update your Package.swift file
Add Swift-Kuery and your Kuery plugin, in this case Swift-Kuery-PostgreSQL, to the dependencies within your application's `Package.swift` file. Substitute `"x.x.x"` with the latest `Swift-Kuery` [release](https://github.com/IBM-Swift/Swift-Kuery/releases) and `"y.y.y"` with the latest plugin [release](https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL/releases).

```swift
dependencies: [
    ...
    // Add this line
    .package(url: "https://github.com/IBM-Swift/Swift-Kuery.git", from: "x.x.x"),
    .package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL.git", from: "y.y.y"),
  ],
  targets: [
    .target(
      name: ...
      // Add the module to your target(s)
      dependencies: [..., "SwiftKuery", "SwiftKueryPostgreSQL"]),
  ]
```

### Executing SQL queries
Inside the `main.swift` file:

1. Add SwiftKuery and SwiftKueryPostgreSQL to your import statements:
```swift
import SwiftKuery
import SwiftKueryPostgreSQL
```

2. Create a `Table` class, which matches the `grades` table you created in the database:
```swift
class Grades: Table {
    let tableName = "Grades"
    let id = Column("id", Int32.self, primaryKey: true)
    let course = Column("course", String.self)
    let grade = Column("grade", Int32.self)
}
let grades = Grades()
```

3. Create a pool of connections to PostgreSQL:
```swift
let pool = PostgreSQLConnection.createPool(host: "localhost", port: 5432, options: [.databaseName("school")], poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50))
```

4. Create some example students:
```swift
let students: [[Any]] = [[0, "computing", 92], [1, "physics", 75], [2, "history", 83]]
```

5. Connect to database and perform an SQL query:
```swift
pool.getConnection() { connection, error in
    guard let connection = connection else {
        guard let error = error else {
            return print("Unknown error")
        }
        return print("Error when getting connection from pool: \(error.localizedDescription)")
    }
    let insertQuery = Insert(into: grades, rows: students)
    connection.execute(query: insertQuery) { insertResult in
        connection.execute(query: Select(from: grades)) { selectResult in
            guard let resultSet = selectResult.asResultSet else {
                return print("No result set returned from query")
            }
            resultSet.forEach() { row, error in
                guard let row = row else {
                    guard let error = error else {
                        // Processed all results
                        return
                    }
                    // Handle error
                    return
                }
                guard row.count == 3 else {
                    // Expecting three elements per row
                    return print("Row has wrong number of elements. Expecting 3, returned: \(row.count)")
                }
                print("Student \(row[0] ?? ""), studying \(row[1] ?? ""), scored \(row[2] ?? "")")
            }
        }
    }
}
```
6. If you were to run the application at this point it would execute immediately because the SwiftKuery API behaves asynchronously. In the case of this simple executable you can add a Dispatch Semaphore to force the application to wait for the asynchronous callbacks to complete:
```swift
// Add the following after the existing imports:
import Dispatch
let waitSemaphore = DispatchSemaphore(value: 0)

// Update the forEach callback to look like:
resultSet.forEach() { row, error in
    guard let row = row else {
        // Processed all results
        waitSemaphore.signal()
        return
    }
    print("Student \(row[0] ?? ""), studying \(row[1] ?? ""), scored \(row[2] ?? "")")
}

// Add the following line at the end of the main.swift file
waitSemaphore.wait()
```
            
7. Save the `main.swift` file. Run `swift build` to build the executable.
8. Run the executable `.build/debug/<yourPackageName>.`

This will print the `id`, `course` and `grade` for each student, which are queried from the database:
```
Student 0, studying computing, scored 92
Student 1, studying physics, scored 75
Student 2, studying history, scored 83
```
If you go to your database with `psql school` and enter `TABLE grades;` you can see that the table has been populated with the student data.

## SQL Injection Prevention using Parameterization

Unsanitized data that is used in dynamic queries is one of the most common causes of SQL injection vulnerabilities. Parameterizing queries can help to prevent SQL injection attacks.

The following code is vulnerable to SQL injection if `supplied_key1` or `supplied_key2` contain untrusted data (that is, data which has not been validated):
```swift
let query = Select(from: confidential)
  .where(confidential.key1 == supplied_key1 || confidential.key2 == supplied_key2)

connection.execute(query: query) { queryResult in
  ...
}
```

To guard against SQL Injection attacks, use the following parameterized version of the code:
```swift
let query = Select(from: confidential)
  .where(confidential.key1 == Parameter() || confidential.key2 == Parameter())

connection.execute(query: query, parameters: supplied_key1, supplied_key2) { queryResult in
  ...
}
```

## Prepared Statements

If your application executes the same (or similar) SQL statements repeatedly with different parameters you may improve the performance of the application by using a prepared statement. Prepared statements can reduce parsing time as the database parses and compiles the statement template only once and then stores the result but doesn’t execute it. Later, the application supplies values for the parameters of the statement template and the database executes the statement.

For example, suppose our application needs to retrieve the average grade for courses with an average above a given value; a value which we want to vary. Let’s change our query to use a parameter instead of a predefined value:

```swift
let query = Select(grades.course, round(avg(grades.grade), to: 1).as("average"), from: grades)
            .group(by: grades.course)
            .having(avg(grades.grade) > Parameter())
            .order(by: .ASC(avg(grades.grade)))
```

Now, prepare the statement and execute as many times as required with different parameter values. Use the `release` function to free the prepared statement:

```swift
connection.prepareStatement(query) { result in
    guard let statement = result.asPreparedStatement else {
        // Handle error
        return
    }
    // Execute the statement
    connection.execute(preparedStatement: preparedStatement, parameters: [70]) { result in
        ...
        connection.execute(preparedStatement: preparedStatement, parameters: [25]) { result in
            ...
            connection.release(preparedStatement: preparedStatement) { result in
                ...
            }
        }
    }
}
```

**Note**: `preparedStatement` is a plugin-specific handle for the prepared statement.

## Schema Management

### Table creation
Swift-Kuery enables you to create tables on the database server.

Let's revisit the Grades table, which we used in our Example above:

```swift
class Grades: Table {
    let tableName = "Grades"
    let id = Column("id", Int32.self, primaryKey: true)
    let course = Column("course", String.self)
    let grade = Column("grade", Int32.self)
}
```

We will add a second table called `courses`:
```swift
class Courses: Table {
    let tableName = "Courses"
    let name = Column("name", String.self, primaryKey: true)
    let credit = Column("credit", Int32.self)
    let teacher = Column("teacher", String.self)
}
let courses = Courses()
```

We can add a foreign key to `Grades` that references a column in another table:

```swift
let grades = Grades().foreignKey(grades.course, references: courses.name)
```

Create a multi-column primary key (if not set in the column as for `Grades.id`)

```swift
grades.primaryKey(grades.id, grades.course)
```

Create the table in the database:

```swift

courses.create(connection: connection) { result in
     guard result.success else {
        print("Failed to create table: \(result.asError?)")
     }
    ...
}
```

### Indices

You can manage indices with Swift-Kuery in the following way:

```swift
let index = Index("index", on: grades, columns: [grades.id, desc(grades.grade)])
index.create(connection: connection) { result in ... }
...
index.drop(connection: connection) { result in ... }
```

### Migration
Swift-Kuery has a class `Migration` to help with migrations between two versions of a table.

Suppose we have a table `MyTable` in our application. The suggested usage is to keep versions of the table classes somewhere in the application code:

```swift
public class MyTable_v0: Table {
    let a = Column("a", ...)
    let b = Column("b", ...)
    let tableName = "MyTable"
}

public class MyTable_v1: Table {
    let b = Column("b", ...)
    let c = Column("c", ...)
    let tableName = "MyTable"
}
```

Use a typealias to refer to the current version of the table class in the application:

```swift
typealias MyTable = MyTable_v0
let t = MyTable()
let q = Select(from t)
...
```

The migration code from v0 to v1 should be something like this:

```swift
let t0 = MyTable_v0()
let t1 = MyTable_v1()
let migration0 = Migration(from: t0, to: t1, using: connection)
migration0.alterTableAdd(column: t1.c) { result in ... }
```

You can also execute raw alterations, if needed:

```swift
let dropColumnQuery = "ALTER TABLE " + t1.tableName + " DROP COLUMN " + t0.a.name
connection.execute(dropColumnQuery) { result in ... }
```

## Query Examples
In the following section, we will provide an example SQL query and show you how to build and execute the same query in Swift using Swift-Kuery.

#### Classes used in the examples:
These examples we will use the following two tables:

```swift
class T1 {
  let tableName = "t1"
  let a = Column("a")
  let b = Column("b")
}

class T2 {
  let tableName = "t2"
  let c = Column("c")
  let b = Column("b")
}
```

&nbsp;

__SELECT * FROM t1;__

This query will select all results from the table. The example below shows how to execute this query including the boilerplate code:

```swift
let t1 = T1()

let query = Select(from: t1)

pool.getConnection() { connection, error in
    guard let connection = connection else {
        // Handle error
        return
    }
    query.execute(connection) { queryResult in
        guard let resultSet = queryResult.asResultSet else {
            // Handle error
            return
        }
        resultSet.getColumnTitles() { titles, error in
            guard let titles = titles else {
                // Handle error
                return
            }
            //Process titles
            resultSet.forEach() { row, error in
                guard let row = row else {
                    // Processed all results
                    return
                }
                // Process row
            }
        }
    }
}


```

The following examples show more complex queries, which can be substituted into the the above boilerplate.
&nbsp;

__SELECT a, b FROM t1      
   WHERE (a LIKE '%b' OR a = 'apple') AND b > 5  
   ORDER BY b ASC, a DESC       
   OFFSET 5;__

```swift
let query = Select(t1.a, t1.b, from: t1)
  .where((t1.a.like("b%") || t1.a == "apple") && t1.b > 5)
  .order(by: .ASC(t1.b), .DESC(t1.a))
  .offset(5)
```

&nbsp;

__SELECT UCASE(a) AS name FROM t1    
 WHERE b >= 0         
 GROUP BY a         
 HAVING SUM(b) > 3        
 ORDER BY a DESC;__

```swift
let query = Select(ucase(t1.a).as("name"), from: t1)
  .where(t1.b >= 0)
  .group(by: t1.a)
  .having(sum(t1.b) > 3)
  .order(by: .DESC(t1.a))
```

&nbsp;

__INSERT INTO t1             
VALUES ('apple', 10), ('apricot', 3), ('banana', 17);__

```swift
let query = Insert(into: t1, rows: [["apple", 10], ["apricot", 3], ["banana", 17]])
```

&nbsp;

__INSERT INTO t1             
VALUES ('apple', 10);__

```swift
let query = Insert(into: t1, values: "apple", 10)
```

&nbsp;


__INSERT INTO t1 (a, b)              
VALUES ('apricot', '3');__

```swift
let query = Insert(into: t1, valueTuples: (t1.a, "apricot"), (t1.b, "3"))
```

&nbsp;

__INSERT INTO t1 (a, b)              
VALUES ('apricot', '3');__

```swift
let query = Insert(into: t1, columns: [t1.a, t1.b], values: ["apricot", 3])
```

&nbsp;

__UPDATE t1 SET a = 'peach', b = 2            
WHERE a = 'banana';__

```swift
let query = Update(t1, set: [(t1.a, "peach"), (t1.b, 2)])
  .where(t1.a == "banana")
```

&nbsp;

__SELECT * FROM t1 AS left            
LEFT JOIN t2 AS right           
ON left.b = right.b;__

```swift
let t1 = T1()
let t2 = T2()

let leftTable = t1.as("left")
let rightTable = t2.as("right")
let query = Select(from: leftTable)
  .leftJoin(rightTable)
  .on(leftTable.b == rightTable.b)
```

&nbsp;

__SELECT * FROM t1           
JOIN t2           
USING (b);__

```swift
let query = Select(from: t1)
  .join(t2)
  .using(t1.b)
```

&nbsp;

__SELECT COUNT(t1.a) FROM t1;__

```swift
let query = Select.count(t1.a, from: t1)
```

&nbsp;

#### Queries with parameters:                         
**Note**: Named parameters are supported for all databases, even for those that do not support named parameters (e.g. PostgreSQL).


__INSERT INTO t1             
VALUES (@0,@1);__

```swift
let query = Insert(into: t1, values: Parameter(), Parameter())

connection.execute(query: query, parameters: "banana", 28) { queryResult in
  // Process result
}
```

&nbsp;

__INSERT INTO t1             
VALUES (@fruit,@number);__

```swift
let query = Insert(into: t1, values: Parameter("fruit"), Parameter("number"))

connection.execute(query: query, parameters: ["number" : 28, "fruit" : "banana"]) { queryResult in
  // Process result
}
```

&nbsp;

It is possible to insert NULL values using parameters:
&nbsp;

```swift
connection.execute(query: query, parameters: ["number" : 28, "fruit" : nil]) { queryResult in
  // Process result
}
```

&nbsp;

__Raw query:__

```swift
connection.execute("CREATE TABLE myTable (a varchar(40), b integer)") {  queryResult in
  // Process result
}
```

&nbsp;

__SELECT LEFT(a, 2) as raw FROM t1     
 WHERE b >= 0
 GROUP BY a         
 HAVING sum(b) > 3               
 ORDER BY a DESC;__

```swift
let query = Select(RawField("LEFT(a, 2) as raw"), from: t1)
  .where("b >= 0")
  .group(by: t1.a)
  .having("sum(b) > 3")
  .order(by: .DESC(t1.a))
```

&nbsp;

__SELECT * FROM t1     
WHERE b >= ANY (SELECT b FROM t2);__

```swift
let query = Select(from: t1)
  .where(t1.b >= any(Select(t2.b, from: t2)))
```

&nbsp;

__SELECT * FROM t1     
WHERE NOT EXISTS (SELECT * FROM t2 WHERE b < 8);__

```swift
let query = Select(from: t1)
  .where(notExists(Select(from: t2).where(t2.b < 8)))
```

&nbsp;

__SELECT c FROM t2
GROUP BY c     
HAVING SUM(b) NOT IN (SELECT b FROM t1 WHERE a = 'apple');__

```swift
let query = Select(t2.c, from: t2)
    .group(by: t2.c)
    .having(sum(t2.b).notIn(Select(t1.b, from: t1).where(t1.a == "apple")))
```

## List of plugins

* [PostgreSQL](https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL)

* [SQLite](https://github.com/IBM-Swift/Swift-Kuery-SQLite)

* [MySQL](https://github.com/IBM-Swift/SwiftKueryMySQL)

## API Documentation
For more information visit our [API reference](https://ibm-swift.github.io/Swift-Kuery/index.html).

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/Swift-Kuery/blob/master/LICENSE.txt).
