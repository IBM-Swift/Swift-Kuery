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

import Foundation

// MARK: SQLDataType protocol

/// Defines the protocol for data types to be used as table column types.
public protocol SQLDataType {
    /// Return database specific representation of the type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    static func create(queryBuilder: QueryBuilder) -> String
}

/// SQL varchar type.
public struct Varchar: SQLDataType {
    /// Return database specific representation of the varchar type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return "varchar"
    }
}

/// SQL char/character type.
public struct Char: SQLDataType {
    /// Return database specific representation of the char type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.char.rawValue]
    }
}

/// SQL date type.
public struct SQLDate: SQLDataType {
    /// Return database specific representation of the date type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return "date"
    }
}

/// SQL time type.
public struct Time: SQLDataType {
    /// Return database specific representation of the time type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return "time"
    }
}

/// SQL timestamp type.
public struct Timestamp: SQLDataType {
    /// Return database specific representation of the timestamp type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return "timestamp"
    }
}

extension Int8: SQLDataType {
    /// Return database specific representation of the int8 type using `QueryBuilder`.
    ///
    /// This returns the 'tinyint' value if supported, otherwise, it returns the `Int16` representation.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        if queryBuilder.addTinyIntegers {
            return "tinyint"
        }
        return Int16.create(queryBuilder: queryBuilder)
    }
}

extension Int16: SQLDataType {
    /// Return database specific representation of the int16 type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return "smallint"
    }
}

extension Int32: SQLDataType {
    /// Return database specific representation of the int32 type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.int32.rawValue]
    }
}

extension Int64: SQLDataType {
    /// Return database specific representation of the int64 type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return "bigint"
    }
}

extension QueryBuilder {
    /// Local extension to return the `unsigned` or not suffix when creating the query.
    fileprivate var unsignedSuffix: String {
        self.addUnsignedIntegers ? " unsigned" : ""
    }
}

extension UInt8: SQLDataType {
    /// Return database specific representation of the uint8 type using `QueryBuilder`.
    ///
    /// This returns:
    ///  - the 'tinyint unsigned' value if `addTinyIntegers = true` and `addUnsignedIntegers = true`;
    ///  - the 'smallint unsigned' value if `addTinyIntegers = false` and `addUnsignedIntegers = true`;
    ///  - the 'tinyint' value if `addTinyIntegers = true` and `addUnsignedIntegers = false`;
    ///  - the 'smalint' value if `addTinyIntegers = false` and `addUnsignedIntegers = false`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        if queryBuilder.addTinyIntegers {
            return Int8.create(queryBuilder: queryBuilder) + queryBuilder.unsignedSuffix
        }
        return Int16.create(queryBuilder: queryBuilder) + queryBuilder.unsignedSuffix
    }
}

extension UInt16: SQLDataType {
    /// Return database specific representation of the uint16 type using `QueryBuilder`.
    ///
    /// This returns the `smallint unsigned` if the value is supported otherwise the `Int16` representation.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return Int16.create(queryBuilder: queryBuilder) + queryBuilder.unsignedSuffix
    }
}

extension UInt32: SQLDataType {
    /// Return database specific representation of the uint32 type using `QueryBuilder`.
    ///
    /// This returns the `integer unsigned` if the value is supported otherwise the `Int32` representation.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return Int32.create(queryBuilder: queryBuilder) + queryBuilder.unsignedSuffix
    }
}

extension UInt64: SQLDataType {
    /// Return database specific representation of the uint64 type using `QueryBuilder`.
    ///
    /// This returns the `bigint unsigned` if the value is supported otherwise the `Int64` representation.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return Int64.create(queryBuilder: queryBuilder) + queryBuilder.unsignedSuffix
    }
}

extension String: SQLDataType {
    /// Return database specific representation of the string type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return "text"
    }
}

extension Float: SQLDataType {
    /// Return database specific representation of the float type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.float.rawValue]
    }
}

extension Double: SQLDataType {
    /// Return database specific representation of the double type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.double.rawValue]
    }
}

extension Bool: SQLDataType {
    /// Return database specific representation of the boolean type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return "boolean"
    }
}

extension UUID: SQLDataType {
    /// Return database specific representation of the UUID type using `QueryBuilder`.
    ///
    /// - Parameter queryBuilder: The QueryBuilder to use.
    /// - Returns: A String representation of the type.
    public static func create(queryBuilder: QueryBuilder) -> String {
        return queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.uuid.rawValue]
    }
}



