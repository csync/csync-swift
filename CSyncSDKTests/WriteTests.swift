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

class WriteTests: XCTestCase {

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

	func testSimpleWrite() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}
		let testKey = app.key(testKeyString("\(#function)"))

		//delete this key in the teardown
		keyToDelete=testKey

		testKey.write("value")  { key, error in
			XCTAssertNil(error)
			expectation.fulfill()
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testWriteWithNilCompletionHandler() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey = app.key(testKeyString("\(#function)"))

		//delete this key in the teardown
		keyToDelete=testKey

		testKey.listen { (value, error) -> () in
			XCTAssertNil(error)
			XCTAssertEqual(value!.key, testKey.key)
			expectation.fulfill()
			testKey.unlisten()
		}

		testKey.write("data", completionHandler: nil)

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testWriteWithNoCompletionHandler() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey = app.key(testKeyString("\(#function)"))

		//delete this key in the teardown
		keyToDelete=testKey

		testKey.listen { (value, error) -> () in
			XCTAssertNil(error)
			XCTAssertEqual(value!.key, testKey.key)
			expectation.fulfill()
			testKey.unlisten()
		}

		testKey.write("data")

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testSimpleDelete() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey = app.key(testKeyString("\(#function)"))

		var gotListen = false, gotCompletion = false

		testKey.listen { (value, error) -> () in
			XCTAssertNil(error)
			XCTAssertEqual(value!.key, testKey.key)
			gotListen = !value!.exists
			if gotListen && gotCompletion {
				// Success
				expectation.fulfill()
				testKey.unlisten()
			}
		}

		testKey.write("data")   { key, error in
			XCTAssertNil(error)
			testKey.delete() { key, error in
				XCTAssertNil(error)
				gotCompletion = true
				if gotListen && gotCompletion {
					// Success
					expectation.fulfill()
					testKey.unlisten()
				}
			}
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testDeleteWithNilCompletionHandler() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey = app.key(testKeyString("\(#function)"))

		testKey.listen { (value, error) -> () in
			XCTAssertNil(error)
			XCTAssertEqual(value!.key, testKey.key)
			if value!.exists == false {
				// Success
				expectation.fulfill()
				testKey.unlisten()
			}
		}

		testKey.write("data")   { key, error in
			XCTAssertNil(error)
			// How to call delete with a nil completionHandler?
			// testKey.delete(completionHandler: nil) // build error - Argument labels do not match
			// testKey.delete(_: nil)	// build error - Ambiguous use of 'delete'
			// testKey.delete() {}		// build error - wrong type
			//testKey.delete(nil as ((key: Key, error: NSError?)->())?)
			testKey.delete(nil)
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testDeleteWithNoCompletionHandler() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey = app.key(testKeyString("\(#function)"))

		testKey.listen { (value, error) -> () in
			XCTAssertNil(error)
			XCTAssertEqual(value!.key, testKey.key)
			if value!.exists == false {
				// Success
				expectation.fulfill()
				testKey.unlisten()
			}
		}

		testKey.write("data")   { key, error in
			XCTAssertNil(error)
			testKey.delete()
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testDeleteWildcardThatDoesNotExist() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey = app.key(testKeyString("\(#function)")+".*")
		testKey.delete() {key, error in
			// Wildcard deletes should always return success, even if nothing was deleted
			assert(error == nil)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testDeleteThatDoesNotExist() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
		}

		let testKey = app.key(testKeyString("\(#function)"))
		testKey.delete() {key, error in
			// Single Key deletes will return an error if you delete something that doesn't exist.
			assert(error?.code == CSError.requestError.rawValue)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 10.0, handler:nil)
	}

}
