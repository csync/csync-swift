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

	func testDeleteWildcard(){
		let expectation = self.expectation(description: "\(#function)")
		let config = getConfig()
		let uuid = UUID().uuidString
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
			//Check to be sure the right 3 keys are deleted
			var keyOne = false, keyTwo = false, keyThree = false
			let listenKey = app.key("tests.DeleteWildcard." + uuid + "a.*")
			let writeKey = app.key("tests.DeleteWildcard." + uuid + "a.b")
			writeKey.write("b")
			let writeKey2 = app.key("tests.DeleteWildcard." + uuid + "a.c")
			writeKey2.write("c")
			let writeKey3 = app.key("tests.DeleteWildcard." + uuid + "a.d")
			writeKey3.write("d")
			let writeKey4 = app.key("tests.DeleteWildcard." + uuid + "b.e")
			writeKey4.write("be")
			let writeKey5 = app.key("tests.DeleteWildcard." + uuid + "a.e.f")
			writeKey5.write("aef")
			let writeKey6 = app.key("tests.DeleteWildcard." + uuid + "b.a.g")
			writeKey6.write("bag")
			listenKey.listen { (value, error) -> () in
				if let key = value?.key {
					if key == "tests.DeleteWildcard." + uuid + "a.b" && (value?.exists)! == false {
						keyOne = true
					} else if key == "tests.DeleteWildcard." + uuid + "a.c" && value?.exists == false {
						keyTwo = true
					} else if key == "tests.DeleteWildcard." + uuid + "a.d" && value?.exists == false {
						keyThree = true
					} else if key == "tests.DeleteWildcard." + uuid + "b.e" && value?.exists == false {
						XCTFail("a.* delete should not delete b.e")
					} else if key == "tests.DeleteWildcard." + uuid + "a.e.f" && value?.exists == false {
						XCTFail("a.* delete should not delete a.e.f")
					} else if key == "tests.DeleteWildcard." + uuid + "b.a.g" && value?.exists == false {
						XCTFail("a.* delete should not delete b.a.g")
					}
					//If all three keys that we expected to get deleted were deleted, pass
					if keyOne && keyTwo && keyThree {
						expectation.fulfill()
					}
				}
			}
			let writeKey7 = app.key("tests.DeleteWildcard." + uuid + "a.*")
			writeKey7.delete()
		}
		waitForExpectations(timeout: 20.0, handler:nil)
	}

	func testDeleteWildcardInMiddle(){
		let expectation = self.expectation(description: "\(#function)")
		let config = getConfig()
		let uuid = UUID().uuidString
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
			//Check to be sure the right 3 keys are deleted
			var keyOne = false, keyTwo = false, keyThree = false
			let listenKey = app.key("tests.DeleteWildcardInMiddle." + uuid + "a.*.e")
			let writeKey = app.key("tests.DeleteWildcardInMiddle." + uuid + "a.b.e")
			writeKey.write("b")
			let writeKey2 = app.key("tests.DeleteWildcardInMiddle." + uuid + "a.c.e")
			writeKey2.write("c")
			let writeKey3 = app.key("tests.DeleteWildcardInMiddle." + uuid + "a.d.e")
			writeKey3.write("d")
			let writeKey4 = app.key("tests.DeleteWildcardInMiddle." + uuid + "b.e.e")
			writeKey4.write("be")
			let writeKey5 = app.key("tests.DeleteWildcardInMiddle." + uuid + "a.e.e.f")
			writeKey5.write("aef")
			let writeKey6 = app.key("tests.DeleteWildcardInMiddle." + uuid + "b.a.e.g")
			writeKey6.write("bag")
			listenKey.listen { (value, error) -> () in
				if let key = value?.key {
					if key == "tests.DeleteWildcardInMiddle." + uuid + "a.b.e" && (value?.exists)! == false {
						keyOne = true
					} else if key == "tests.DeleteWildcardInMiddle." + uuid + "a.c.e" && value?.exists == false {
						keyTwo = true
					} else if key == "tests.DeleteWildcardInMiddle." + uuid + "a.d.e" && value?.exists == false {
						keyThree = true
					} else if key == "tests.DeleteWildcardInMiddle." + uuid + "b.e.e" && value?.exists == false {
						XCTFail("a.* delete should not delete b.e")
					} else if key == "tests.DeleteWildcardInMiddle." + uuid + "a.e.e.f" && value?.exists == false {
						XCTFail("a.* delete should not delete a.e.f")
					} else if key == "tests.DeleteWildcardInMiddle." + uuid + "b.a.e.g" && value?.exists == false {
						XCTFail("a.* delete should not delete b.a.g")
					}
					//If all three keys that we expected to get deleted were deleted, pass
					if keyOne && keyTwo && keyThree {
						expectation.fulfill()
					}
				}
			}
			let writeKey7 = app.key("tests.DeleteWildcardInMiddle." + uuid + "a.*.e")
			writeKey7.delete()
		}
		waitForExpectations(timeout: 20.0, handler:nil)
	}

	func testDeleteNonexistantWildcard(){
		//Deleting something that does not exist should return a success
		let expectation = self.expectation(description: "\(#function)")
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
			let writeKey7 = app.key("tests.DeleteNonexistantWildcard.*")
			writeKey7.delete(){ key, error in
				assert(error == nil)
				assert(key.key == "tests.DeleteNonexistantWildcard.*")
				expectation.fulfill()
			}

		}
		waitForExpectations(timeout: 10.0, handler:nil)
	}

}
