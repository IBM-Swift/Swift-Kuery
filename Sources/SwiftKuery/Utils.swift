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

import Foundation

struct Utils {

    static func packType(_ item: Any) -> String {
        switch item {
        case let val as String:
            return "'\(val)'"
        case let value as Date:
            return "'\(String(describing: value))'"
        default:
            return String(describing: item)
        }
    }

    static func packType(_ item: Any, queryBuilder: QueryBuilder) throws -> String {
        switch item {
        case let val as String:
            return "'\(val)'"
        case let val as Bool:
            return val ? queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.booleanTrue.rawValue]
                : queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.booleanFalse.rawValue]
        case let val as Parameter:
            return try val.build(queryBuilder: queryBuilder)
        case let value as Date:
            if let dateFormatter = queryBuilder.dateFormatter {
                return dateFormatter.string(from: value)
            }
            return "'\(String(describing: value))'"
        default:
            let val = String(describing: item)
            return val == "nil" ? "NULL" : val
        }
    }

    static func packName(_ name: String, queryBuilder: QueryBuilder) -> String {
        var result = name
        let identifierQuoteCharacter = queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.identifierQuoteCharacter.rawValue]
        if !result.hasPrefix(identifierQuoteCharacter) {
            result = identifierQuoteCharacter + result + identifierQuoteCharacter
        }
        return result
    }

    static func updateParameterNumbers(query: String, queryBuilder: QueryBuilder) -> String {
        let marker = queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.numberedParameter.rawValue]
        if !queryBuilder.addNumbersToParameters {
            return query.replacingOccurrences(of: Parameter.numberedParameterMarker, with: marker)
        }
        var resultQuery = ""
        var inputQuery = query
        var range = inputQuery.range(of: Parameter.numberedParameterMarker)
        var index = 1
        while let _range = range {
            resultQuery += inputQuery[..<_range.lowerBound] + marker
            resultQuery += "\(index)"
            inputQuery = String(inputQuery[_range.upperBound...])

            index += 1

            range = inputQuery.range(of: Parameter.numberedParameterMarker)
        }
        resultQuery += inputQuery
        return resultQuery
    }

    static func convertNamedParametersToNumbered(query: String, queryBuilder: QueryBuilder) -> (String, [String:[Int]], Int) {
        var resultQuery = ""
        var nameToNumber = [String:[Int]]()
        var index = 1
        let marker = queryBuilder.substitutions[QueryBuilder.QuerySubstitutionNames.numberedParameter.rawValue]
        var inputQuery = query
        var startRange = inputQuery.range(of: Parameter.namedParameterStart)
        var endRange = inputQuery.range(of: Parameter.namedParameterEnd)
        while let _startRange = startRange, let _endRange = endRange {
            resultQuery += inputQuery[..<_startRange.lowerBound] + marker

            if queryBuilder.addNumbersToParameters {
                resultQuery += "\(index)"
            }

            let name = String(inputQuery[_startRange.upperBound..<_endRange.lowerBound])

            if let _ = nameToNumber[name] {
                nameToNumber[name]!.append(index)
            }
            else {
                nameToNumber[name] = [index]
            }

            index += 1

            inputQuery = String(inputQuery[_endRange.upperBound...])

            startRange = inputQuery.range(of: Parameter.namedParameterStart)
            endRange = inputQuery.range(of: Parameter.namedParameterEnd)
        }
        resultQuery += inputQuery
        return (resultQuery, nameToNumber, index - 1)
    }
}
