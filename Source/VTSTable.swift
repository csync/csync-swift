/*
* Copyright IBM Corporation 2016-2017
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
*/

import Foundation
import SQLite

class VTSTable
{
	static private let vtsTable = Table("vts")

	static private let lvts = Expression<Int64>("lvts")
	static private let rvts = Expression<Int64>("rvts")
	static private let pattern = Expression<String>("key")

	class func createTable(_ db : Database) throws
	{
		let stmt = vtsTable.create(ifNotExists: true) { t in
			t.column(lvts, primaryKey: true)
			t.column(rvts)
			t.column(pattern)
			t.unique(pattern)			// Only one entry per pattern
		}

		return try db.run(stmt)
	}

	class func insert(_ db : Database, value : VTSSet, pattern: String) throws -> Int64
	{
		guard let lvts = value.lvts, let rvts = value.rvts else {
			print("really big problem") // TODO: error handle
			return 0
		}
		let setters = [self.lvts <- lvts,
		               self.rvts <- rvts,
		               self.pattern <- pattern]

		let insert = vtsTable.insert(or: .replace, setters)

		return try db.run(insert)
	}

	class func vts(in db: Database, for patternString: String) throws -> VTSSet?
	{
		let query = vtsTable.select(lvts,rvts)       // SELECT "lvts,rvts" FROM "vts"
			.filter(pattern == patternString)    // WHERE "pattern" = patternString
		let items = try db.prepare(query)
		for item in items {
			return (item[lvts],item[rvts])
		}
		return nil
	}
}
