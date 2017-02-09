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

class ListenTests: XCTestCase {

	var keyToDelete : Key?
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		//Delete any keys used during the tests
		if keyToDelete != nil{
			keyToDelete!.delete()
			keyToDelete=nil
		}
		super.tearDown()
	}

	func testSimpleListen() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		var uid : String! = nil
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
			uid = authData?.uid
		}

		let listenKey = app.key("tests.simpleListen.*")
		let writeKey = app.key("tests.simpleListen."+UUID().uuidString)

		//delete this key in the teardown
		keyToDelete=writeKey

		listenKey.listen { (value, error) -> () in
			XCTAssertNil(error)
			if let key = value?.key, key == writeKey.key {
				XCTAssertEqual(value!.creator, uid)
				expectation.fulfill()
				listenKey.unlisten()
			}
		}

		after(1.0) {
			writeKey.write("stuff")  { key, error in
				XCTAssertNil(error)
			}
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testMultipleListensOnKey() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey1 = app.key("tests.multipleListensOnKey."+UUID().uuidString)

		//delete this key in the teardown
		keyToDelete = testKey1

		let testKey2 = app.key(testKey1.key)

		let writer = { (data: String) in
			testKey1.write(data)  { key, error in
				XCTAssertNil(error)
			}
		}

		var count = 0
		let listener = { (value: Value?, error: NSError?) -> () in
			XCTAssertNil(error)
			count += 1
			if count == 2 {
				testKey1.unlisten()
				after(1.0) { writer("after") }
			} else if count == 3 {
				XCTAssertEqual(value!.data!, "after")
				testKey2.unlisten()
				expectation.fulfill()
			}
		}

		testKey1.listen(listener)
		testKey2.listen(listener)

		after(1.0) { writer("before") }

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testRepeatListensOnKey() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey = app.key("tests.repeatListensOnKey."+UUID().uuidString)

		var count = 0
		var listener = { (value: Value?, error: NSError?) -> () in }
		listener = { (value: Value?, error: NSError?) -> () in
			XCTAssertNil(error)
			XCTAssertEqual(value!.data!, "data")
			count += 1
			if count == 1 {
				testKey.unlisten()
				after(1.0) { testKey.listen(listener) }
			} else {
				testKey.unlisten()
				expectation.fulfill()
			}
		}

		testKey.listen(listener)

		//delete this key in the teardown
		keyToDelete=testKey

		testKey.write("data")  { key, error in
			XCTAssertNil(error)
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

/*
	func testListenNullData() {
		let expectation = expectationWithDescription("\(#function)")

		// Connect to the CSync store
		let app = App(host: config.host, port: config.port)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let listenKey = app.key("try.that")

		listenKey.listen { (value, error) -> () in
			XCTAssertNil(error)
			XCTAssertNil(value!.data)
			expectation.fulfill()
			listenKey.unlisten()
		}

		waitForExpectationsWithTimeout(5.0, handler:nil)
	}
*/
}
