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

class Database
{
	/** The app associated with this transport instance */
	unowned let app : App

	var conn : Connection!

	init(app: App) {
		self.app = app

		// TODO: Create a dbname from the app.transport.host || app.transport.port

		do {
			conn = try Connection(.inMemory)
			try Latest.createTable(self)
			try Log.createTable(self)
		} catch let error as NSError {
			fatalError("Could not open database connection: \(error)")
		}
	}

	func prepare(_ query: QueryType) throws-> AnySequence<SQLite.Row> {
		return try conn.prepare(query)
	}
	func run(_ stmt: String) throws {
		try conn.run(stmt)
	}
	func run(_ insert: SQLite.Insert) throws -> Int64 {
		return try conn.run(insert)
	}
	func transaction(_ block: @escaping(() throws -> Void)) throws {
		try conn.transaction(block: block)
	}
}
