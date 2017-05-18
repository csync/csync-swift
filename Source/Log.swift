/*
 * Copyright IBM Corporation 2016
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

class Log
{
	static private let log = Table("log")

	static private let vts = Expression<Int64>("vts")
	static private let key = Expression<String>("key")
	static private let keys = Array(1...16).map{Expression<String?>("key\($0)")}

	class func createTable(_ db : Database) throws
	{
		let stmt = log.create(ifNotExists: true) { t in
			t.column(vts, primaryKey: true)
			t.column(key)
			for k in keys { t.column(k) }  // Default value is NULL
		}
		return try db.run(stmt)
	}

	class func insert(_ db : Database, value : Value) throws -> Int64
	{
		guard value.acl != nil else {
			return 0
		}

		var setters = [vts <- value.vts,
			key <- value.key]

		for (i, k) in Key.components(value.key).enumerated() {
			setters.append(keys[i] <- k)
		}

		// Ignore conflict on insert because that just means this log record
		// was already inserted into the log
		let insert = log.insert(or: .ignore, setters)

		return try db.run(insert)
	}

	class func vts(in db: Database, for keyObj: Key, after rvts: VTS) throws -> [VTS]
	{
		var query = log.select(vts, key)      // SELECT vts,key FROM latest
			.filter(vts > rvts)		 // WHERE vts > rvts
		// restrict query to match all leading non-wildcard key components
		for (i, k) in keyObj.components.enumerated() {
			if k == "*" || k == "#" {
				break
			}
			query = query.filter(keys[i] == k)
		}
		let items = try db.prepare(query)
		let dbVts = items.filter { item in keyObj.matches(item[key]) }.map { item in item[vts] }
		return dbVts
	}

	class func vts(in db: Database, for keyObj: Key, before lvts: VTS) throws -> [VTS]
	{
		var query = log.select(vts, key)      // SELECT vts,key FROM latest
			.filter(vts < lvts)		 // WHERE vts < lvts
		// restrict query to match all leading non-wildcard key components
		for (i, k) in keyObj.components.enumerated() {
			if k == "*" || k == "#" {
				break
			}
			query = query.filter(keys[i] == k)
		}
		let items = try db.prepare(query)
		let dbVts = items.filter { item in keyObj.matches(item[key]) }.map { item in item[vts] }
		return dbVts
	}
}
