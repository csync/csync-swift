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

import XCTest
#if DEBUG
@testable import CSyncSDK
#else
import CSyncSDK
#endif

class AdvanceTests: XCTestCase {

	var keysToDelete = [Key]()
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.

		//Delete any keys used during the tests
		for key in keysToDelete{
			key.delete()
		}
		keysToDelete.removeAll()
		super.tearDown()
	}

	func testSimpleAdvance() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { _, _ in
		}
		let testKey = app.key("tests.SimpleAdvance."+UUID().uuidString)

		//delete this key in the teardown
		keysToDelete.append(testKey)

		let numWrites = 5

		// closure to register listener for testKey
		let doListen = {
			testKey.listen { (value, error) -> Void in
				XCTAssertNil(error)
				XCTAssertNotNil(value)
				if value!.key == testKey.key {
					let val = Int(value!.data!)
					if val == numWrites {
						expectation.fulfill()
						testKey.unlisten()
					} else {
						print("Got intermediate write with value \(String(describing: val))")
					}
				}
			}
			testKey.getPreviousValues(upTo: 10000)
		}

		// Do some writes

		var count = 1
		var writeHandler : (Key, NSError?) -> Void = {_, _ in }
		writeHandler = { key, error in
			XCTAssertNil(error)
			count += 1
			if count <= numWrites {
				testKey.write("\(count)", completionHandler: writeHandler)
			} else {
				// All writes have completed, so start listening
				after(1.0) { doListen() }
			}
		}

		testKey.write("\(count)", completionHandler: writeHandler)

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testAdvanceWithWildcards() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { _, _ in
		}

		let listenKey = app.key("#")
		let writeKeys = [ "tests.AdvanceWithWildcards",
		                  "tests.AdvanceWithWildcards."+UUID().uuidString,
		                  "tests.AdvanceWithWildcards.bar."+UUID().uuidString,
		                  UUID().uuidString+".AdvanceWithWildcards.baz"]

		// closure to register listener for listenKey
		var total = 0
		var count = 0
		var start : Date! = nil
		let doListen = {
			listenKey.listen { (value, error) -> Void in
				XCTAssertNil(error)
				XCTAssertNotNil(value)
				total += 1
				#if DEBUG
				if total % 50 == 0 {
					print("\(#function): [\(NSDate().timeIntervalSince(start))] total = \(total)")
				}
				#endif
				if writeKeys.contains(value!.key) {
					count += 1
					if count == writeKeys.count {
						expectation.fulfill()
						listenKey.unlisten()
					}
				}
			}
			listenKey.getPreviousValues(upTo: 1000)
		}

		// Do some writes
		for (index, keyString) in writeKeys.enumerated() {
			let writeKey = app.key(keyString)
			writeKey.write("\(index)")  { _, error in
				XCTAssertNil(error)
				if index == writeKeys.count-1 {
					// All writes have completed, so start listening
					after(1.0) { doListen() }
				}
			}
		}

		//delete these keys in the teardown
		keysToDelete.append(app.key(writeKeys[0]))
		keysToDelete.append(app.key(writeKeys[1]))
		keysToDelete.append(app.key(writeKeys[2]))
		keysToDelete.append(app.key(writeKeys[3]))

		start = Date()
		waitForExpectations(timeout: 30.0) { (error) -> Void in
			if error != nil {
				print("\(#function) failed \(String(describing: error)): total = \(total) count is \(count)")
			}
		}

	}

	func testAdvanceCounts() {
		let expect = expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { _, _ in }

		let testKey = app.key("tests.AdvanceCounts."+NSUUID().uuidString)

		//delete this key in the teardown
		keysToDelete.append(testKey)

		let numPubs = 50
		var count = 0
		testKey.listen { (value: Value?, error: NSError?) -> Void in
			XCTAssertNil(error)
			count += 1
			if Int(value!.data!)! < numPubs {
				testKey.write("\(count)", completionHandler: nil)
			} else {
				// Advance items should be fewer than 10% of pubbed items
				//XCTAssertLessThan(app.stats.advanceItems*10, numPubs)
				// For automation, advance items should be fewer than 50% of pubbed items
				//XCTAssertLessThan(app.stats.advanceItems*2, numPubs)
				expect.fulfill()
				testKey.unlisten()
			}
		}

		after(1.0) { testKey.write("0", completionHandler: nil) }

		waitForExpectations(timeout: 20.0, handler:nil)
	}
}
