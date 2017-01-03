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

public class WithTable: Table {
    
    private var query: Query
    
    public required init(as query: Query) {
        self.query = query
        super.init()
    }
    
    public required init() {
        fatalError()
    }
    
    public func buildWith(queryBuilder: QueryBuilder) throws -> String {
        return self.nameInQuery + " AS " + "(" + (try self.query.build(queryBuilder: queryBuilder)) + ")"
    }

}

extension Select {
    
    internal func with(_ tables: [WithTable]) -> Select {
        var new = self
        new.with = tables
        return new
    }
}

public func With(_ table: WithTable, _ query: Select) -> Select {
    return With([table], query)
}

public func With(_ tables: [WithTable], _ query: Select) -> Select {
    return query.with(tables)
}
