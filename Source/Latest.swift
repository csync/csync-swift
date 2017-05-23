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

class Latest
{
	static private let latest = Table("latest")

	static private let vts = Expression<Int64>("vts")
	static private let cts = Expression<Int64>("cts")
	static private let key = Expression<String>("key")
	static private let aclid = Expression<String>("aclid")
	static private let creatorid = Expression<String>("creatorid")
	static private let data = Expression<String?>("data")
	static private let isdeleted = Expression<Bool>("isdeleted")
	static private let keys = Array(1...16).map{Expression<String?>("key\($0)")}

	class func createTable(_ db : Database) throws
	{
		let stmt = latest.create(ifNotExists: true) { t in
			t.column(vts, primaryKey: true)
			t.column(cts)
			t.column(key)
			t.column(aclid)
			t.column(creatorid)
			t.column(data)
			t.column(isdeleted)
			for k in keys { t.column(k) }  // Default value is NULL
			t.unique(key)			// Only one entry per key
		}

		return try db.run(stmt)
	}

	class func insert(_ db : Database, value : Value) throws -> Int64
	{
		guard value.acl != nil else {
			return 0
		}

		var setters = [vts <- value.vts,
			cts <- value.cts,
			key <- value.key,
			aclid <- value.acl!,
			creatorid <- value.creator,
			isdeleted <- !value.exists]

		if value.data != nil {
			setters.append(data <- value.data!)
		}

		for (i, k) in Key.components(value.key).enumerated() {
			setters.append(keys[i] <- k)
		}

		let insert = latest.insert(or: .replace, setters)

		return try db.run(insert)
	}

	class func vts(in db: Database, for keyString: String) throws -> VTS?
	{
		let query = latest.select(vts)       // SELECT "vts" FROM "latest"
			.filter(key == keyString)    // WHERE "key" = keyString
		let items = try db.prepare(query)
		for item in items {
			return item[vts]
		}
		return nil
	}

	class func values(in db: Database, for keyObj: Key) throws -> [Value]
	{
		var query = latest.filter(!isdeleted)
		// restrict query to match all leading non-wildcard key components
		for (i, k) in keyObj.components.enumerated() {
			if k == "*" || k == "#" {
				break
			}
			query = query.filter(keys[i] == k)
		}
		let items = try db.prepare(query)
		var values : [Value] = []
		for item in items where keyObj.matches(item[key]) {
			values.append(Value(key:item[key], exists:!item[isdeleted], stable: true, data:item[data],
				acl:item[aclid], creator: item[creatorid], cts:item[cts], vts:item[vts]))
		}
		return values
	}

	class func values(in db: Database, for keyObj: Key, with vtsSet: VTSSet) throws -> [Value]
	{
		var query = latest.filter(!isdeleted)
		// restrict query to match all leading non-wildcard key components
		for (i, k) in keyObj.components.enumerated() {
			if k == "*" || k == "#" {
				break
			}
			query = query.filter(keys[i] == k)
		}
		if let lvts = vtsSet.lvts{
			query = query.filter(vts > lvts)
		}
		if let rvts = vtsSet.rvts{
			query = query.filter(vts <= rvts) //Right side is inclusive between lvts and rvts. Outside lvts is inclusive
		}
		let items = try db.prepare(query)
		var values : [Value] = []
		for item in items where keyObj.matches(item[key]) {
			values.append(Value(key:item[key], exists:!item[isdeleted], stable: true, data:item[data],
			                    acl:item[aclid], creator: item[creatorid], cts:item[cts], vts:item[vts]))
		}
		return values
	}
}
