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

class AppTests: XCTestCase {

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

	func testPicklesAuth() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
			XCTAssertNil(error)
			XCTAssertNotNil(authData!.uid)
			XCTAssertGreaterThan(authData!.expires, Int(NSDate().timeIntervalSince1970))
			expectation.fulfill()
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testAuthFailure() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: "This is a bad token") { _, error in
			XCTAssertNotNil(error)
			expectation.fulfill()
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testUnknownProvider() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate("Iamnotarealprovider", token: "fbtoken") { _, error in
			XCTAssertNotNil(error)
			expectation.fulfill()
		}

		waitForExpectations(timeout: 10.0, handler:nil)
	}

	func testBackToBackLogins(){
		let expectation1 = self.expectation(description: "\(#function)")

		//Grab the CSync Config
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { _, error in
			app.unauth()
			//Unauth right away and try to reauth
			app.authenticate(config.authenticationProvider, token: config.token) { _, error in
				if error?.code == CSError.internalError.rawValue {
					expectation1.fulfill()
				}
			}
		}
		//Wait for expecations
		waitForExpectations(timeout: 10.0) { (error) -> Void in
			if error != nil {
				print("")
			}
		}
	}

	func testQuickLogins(){
		let expectation1 = self.expectation(description: "\(#function)")

		//Grab the CSync Config
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)
		app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
			XCTAssert(error?.code == 4 && authData == nil)
		}
		app.unauth { error in
			XCTAssert(error == nil)
			app.authenticate(config.authenticationProvider, token: config.token) { authData, error in
				if error == nil && authData != nil {
					expectation1.fulfill()
				}
			}
		}
		//Wait for expecations
		waitForExpectations(timeout: 10.0) { (error) -> Void in
			if error != nil {
				print("")
			}
		}
	}

	func testUnauthCompletionHandler(){
		let expectation1 = self.expectation(description: "\(#function)")

		//Grab the CSync Config
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		//Authenticate
		app.authenticate(config.authenticationProvider, token: config.token) { _, error in
			//unauth and check success
			app.unauth { error in
				//Check to be sure no error was sent
				if error == nil {
					expectation1.fulfill()
				}
			}
		}
		//Wait for expecations
		waitForExpectations(timeout: 10.0) { (error) -> Void in
			if error != nil {
				print("")
			}
		}
	}

	func testUnauthAlwaysReturns(){
		let expectation1 = self.expectation(description: "\(#function)")
		let expectation2 = self.expectation(description: "\(#function)")
		//Grab the CSync Config
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		//Authenticate
		app.authenticate(config.authenticationProvider, token: config.token) { _, error in
			//unauth twice so the second one should always return
			app.unauth { error in
				if error == nil {
					expectation1.fulfill()
				}
			}
			app.unauth { error in
				//Check to be sure no error was sent but it returned
				if error == nil {
					expectation2.fulfill()
				}
			}
		}
		//Wait for expecations
		waitForExpectations(timeout: 10.0) { (error) -> Void in
			if error != nil {
				print("")
			}
		}
	}

/*
	func testAnonymous() {
		let expectation = expectationWithDescription("\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		let testKey = app.key("sys.stats.#")

		testKey.listen { (value, error) -> () in
			XCTAssertNil(error)
			expectation.fulfill()
			testKey.unlisten()
		}

		waitForExpectationsWithTimeout(5.0, handler:nil)
	}
*/

#if DEBUG
	func testHandshake() {
		let expect = expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		let testKey = app.key("tests.Handshake."+NSUUID().uuidString)

		//delete this key in the teardown
		keyToDelete=testKey

		// Set the app's serverUUID to simulate a prior connect to a different server instance
		app.serverUUID = testKey.lastComponent

		app.authenticate(config.authenticationProvider, token: config.token) { _, error in
			XCTAssertNotNil(error)

			testKey.write("value")  { _, error in
				XCTAssertNotNil(error)
				XCTAssertEqual(error!.code, CSError.badDatabase.rawValue)
				expect.fulfill()
				testKey.unlisten()
			}

		}

		waitForExpectations(timeout: 10.0, handler:nil)

	}
#endif
}
