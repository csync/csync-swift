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

class AclTests: XCTestCase {

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

	// This test should verify that the example code in the README.md is correct
	func testStaticACLs() {

		XCTAssertEqual(ACL.Private.id, "$private")
		XCTAssertEqual(ACL.PublicRead.id, "$publicRead")
		XCTAssertEqual(ACL.PublicWrite.id, "$publicWrite")
		XCTAssertEqual(ACL.PublicCreate.id, "$publicCreate")
		XCTAssertEqual(ACL.PublicReadWrite.id, "$publicReadWrite")
		XCTAssertEqual(ACL.PublicReadCreate.id, "$publicReadCreate")
		XCTAssertEqual(ACL.PublicWriteCreate.id, "$publicWriteCreate")
		XCTAssertEqual(ACL.PublicReadWriteCreate.id, "$publicReadWriteCreate")
	}

	/*func testSimpleWriteWithAcl() {
		let expectation = self.expectation(description: "\(#function)")

		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		app.authenticate(config.authenticationProvider, token: config.token) { _, error in
			XCTAssertNil(error)
			guard error == nil else {
				return
			}
		}

		let testKey = app.key("tests.SimpleWriteWithAcl."+UUID().uuidString)

		//delete this key in the teardown
		keyToDelete = testKey

		let expectedData = "foo"

		testKey.listen { (value, error) -> Void in
			XCTAssertNil(error)
			XCTAssertEqual(value!.acl, ACL.PublicReadWrite.id)
			XCTAssertEqual(value!.data!, expectedData)
			XCTAssertEqual(value!.creator, app.authData!.uid)
			expectation.fulfill()
			testKey.unlisten()
		}

		testKey.write(expectedData, with:ACL.PublicReadWrite, completionHandler: nil)

		waitForExpectations(timeout: 10.0, handler:nil)
	}*/

}
