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

#if DEBUG
import XCTest
@testable import CSyncSDK

class DatabaseTests: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testUpdateLatest() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in }

		let myKey = app.key("tests.updateLatest."+NSUUID().uuidString)

		let myValue1 = Value(key: myKey.key, exists: true, stable: true, data: "This is the data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1000, vts: 1000)
		XCTAssertTrue(app.updateLatest(myValue1), "First update should succeed")

		let myValue2 = Value(key:myKey.key, exists: true, stable: true, data: "This is old data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 999, vts: 999)
		XCTAssertFalse(app.updateLatest(myValue2), "Update for older value should fail")

		let myValue3 = Value(key:myKey.key, exists: true, stable: true, data: "This is new data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1001, vts: 1001)
		XCTAssertTrue(app.updateLatest(myValue3), "Update for newer value should succeed")

		XCTAssertFalse(app.updateLatest(myValue3), "Update for same value should fail")
	}

	func testGetLatest() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in }

		let myKey = app.key("tests.getLatest."+NSUUID().uuidString)

		let myValue1 = Value(key:myKey.key, exists: true, stable: true, data: "This is the data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1000, vts: 1000)
		XCTAssertTrue(app.updateLatest(myValue1), "First update should succeed")

		let myValue2 = Value(key:myKey.key, exists: true, stable: true, data: "This is new data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1001, vts: 1001)
		XCTAssertTrue(app.updateLatest(myValue2), "Update for newer value should succeed")

		let myValue3 = Value(key:myKey.key, exists: true, stable: true, data: "This is the newest data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1002, vts: 1002)
		XCTAssertTrue(app.updateLatest(myValue3), "Update for newer value should succeed")

		do {
			let dbValues = try Latest.values(in: app.database, for: myKey)
			XCTAssertTrue(dbValues.count == 1)
			if let dbValue = dbValues.first {
				XCTAssertEqual(dbValue.vts, 1002)
				XCTAssertEqual(dbValue.data, "This is the newest data")
			}
		} catch _ {
			XCTFail("values for key threw exception")
		}
	}

	func testGetLatestWithDelete() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in }

		let myKey = app.key("tests.GetLatestWithDelete."+NSUUID().uuidString)

		let myValue1 = Value(key: myKey.key, exists: true, stable: true, data: "This is the data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1000, vts: 1000)
		XCTAssertTrue(app.updateLatest(myValue1), "First update should succeed")

		let myValue2 = Value(key:myKey.key, exists: false, stable: true, data: nil,
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1001, vts: 1001)
		XCTAssertTrue(app.updateLatest(myValue2), "Update with isDeleted should succeed")

		do {
			let dbValues = try Latest.values(in: app.database, for: myKey)
			XCTAssertTrue(dbValues.count == 0)
		} catch _ {
			XCTFail("values for key threw exception")
		}
	}

	func testGetLatestWithWildcards() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in }

		let myKey = app.key("tests.getLatestWithWildcards."+NSUUID().uuidString)

		let myValue1 = Value(key:myKey.key, exists: true, stable: true, data: "This is the data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1000, vts: 1000)
		XCTAssertTrue(app.updateLatest(myValue1), "First update should succeed")

		let myValue2 = Value(key:myKey.key, exists: true, stable: true, data: "This is new data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1001, vts: 1001)
		XCTAssertTrue(app.updateLatest(myValue2), "Update for newer value should succeed")

		let myValue3 = Value(key:myKey.key, exists: true, stable: true, data: "This is the newest data",
		                       acl: ACL.PublicRead.id, creator:"user1", cts: 1002, vts: 1002)
		XCTAssertTrue(app.updateLatest(myValue3), "Update for newer value should succeed")

		let getKey = app.key("tests.getLatestWithWildcards.#")

		do {
			let dbValues = try Latest.values(in: app.database, for: getKey)
			XCTAssertTrue(dbValues.count >= 1)
			let myValues = dbValues.filter{ $0.key == myKey.key }
			XCTAssertTrue(myValues.count == 1)
			if let myValue = myValues.first {
				XCTAssertEqual(myValue.vts, 1002)
				XCTAssertEqual(myValue.data, "This is the newest data")
			}
		} catch _ {
			XCTFail("valuesForKey threw exception")
		}

	}

	func testInsertLog() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in }

		let myKey = app.key("tests.InsertLog."+NSUUID().uuidString)

		do {
			let myValue1 = Value(key: myKey.key, exists: true, stable: true, data: "This is the data",
			                       acl: ACL.PublicRead.id, creator:"user1", cts: 1000, vts: 1000)
			let ret1 = try Log.insert(app.database, value:myValue1)
			XCTAssertEqual(ret1, myValue1.vts, "First insert should succeed")

			let myValue2 = Value(key:myKey.key, exists: true, stable: true, data: "This is new data",
			                       acl: ACL.PublicRead.id, creator:"user1", cts: 1001, vts: 1001)
			let ret2 = try Log.insert(app.database, value:myValue2)
			XCTAssertEqual(ret2, myValue2.vts, "Second insert should succeed")

			let myValue3 = Value(key:myKey.key, exists: true, stable: true, data: "This is the newest data",
			                       acl: ACL.PublicRead.id, creator:"user1", cts: 1002, vts: 1002)
			let ret3 = try Log.insert(app.database, value:myValue3)
			XCTAssertEqual(ret3, myValue3.vts, "Third insert should succeed")

			let ret4 = try Log.insert(app.database, value:myValue3)
			XCTAssertEqual(ret4, myValue3.vts, "Repeat of third insert should silently fail")
		} catch _ {
			XCTFail("testInsertLog threw exception")
		}

	}

	func testVtsFromLog() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in }

		let myKey1 = app.key("tests.VtsFromLog."+NSUUID().uuidString)
		let myKey2 = app.key("tests.VtsFromLog."+NSUUID().uuidString)

		do {
			let myValue1 = Value(key: myKey1.key, exists: true, stable: true, data: "This is the data",
			                       acl: ACL.PublicRead.id, creator:"user1", cts: 1000, vts: 1000)
			let ret1 = try Log.insert(app.database, value:myValue1)
			XCTAssertEqual(ret1, myValue1.vts, "First insert should succeed")

			let myValue2 = Value(key:myKey2.key, exists: false, stable: true, data: nil,
			                       acl: ACL.PublicRead.id, creator:"user1", cts: 1001, vts: 1001)
			let ret2 = try Log.insert(app.database, value:myValue2)
			XCTAssertEqual(ret2, myValue2.vts, "Second insert should succeed")

			let myValue3 = Value(key:myKey1.key, exists: true, stable: true, data: "This is new data",
			                       acl: ACL.Private.id, creator:"user1", cts: 1002, vts: 1002)
			let ret3 = try Log.insert(app.database, value:myValue3)
			XCTAssertEqual(ret3, myValue3.vts, "Third insert should succeed")

			let myValue4 = Value(key:myKey2.key, exists: false, stable: true, data: nil,
			                       acl: ACL.Private.id, creator:"user1", cts: 1003, vts: 1003)
			let ret4 = try Log.insert(app.database, value:myValue4)
			XCTAssertEqual(ret4, myValue4.vts, "Fourth insert should succeed")

			let vtsForKey1 = try Log.vts(in: app.database, for: myKey1, after: 1001)
			XCTAssertEqual(vtsForKey1, [1002])

			let vtsForKey2 = try Log.vts(in: app.database, for: myKey2, after: 1001)
			XCTAssertEqual(vtsForKey2, [1003])

		} catch _ {
			XCTFail("testCountByAcl threw exception")
		}

	}

	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measure {
			// Put the code you want to measure the time of here.
		}
	}

}
#endif
