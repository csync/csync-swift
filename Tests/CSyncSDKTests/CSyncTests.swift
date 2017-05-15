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

import XCTest
import CSyncSDK

struct Config {let host: String; let port: Int; let authenticationProvider: String; let token: String; let options: [String:AnyObject]}
/*
 * The Config.plist file is used to set configuration parameters for the CSyncSDKTests.
 */
func getConfig() -> Config {
    let configPlist = Bundle(for: CSyncTests.self).path(forResource: "Config", ofType: "plist")
	let configDict = configPlist.map { plist in NSDictionary(contentsOfFile:plist) }

	guard let host = configDict??["CSYNC_HOST"] as? String,
		let port = configDict??["CSYNC_PORT"] as? Int,
		let authenticationProvider = configDict??["CSYNC_DEMO_PROVIDER"] as? String,
		let token = configDict??["CSYNC_DEMO_TOKEN"] as? String else{
			fatalError("Unable to find CSync config information, please specify in Config.plist")
	}

	return Config(host: host, port: port, authenticationProvider: authenticationProvider, token: token, options:["useSSL":"NO" as AnyObject, "dbInMemory":"YES" as AnyObject])
}

func after(_ delay:Double, closure:@escaping () -> Void) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func testKeyString(_ testname: String) -> String {
	let start = testname.range(of: "test")!.upperBound
	let end = testname.range(of: "(")!.lowerBound
	return "tests."+testname.substring(with: Range(start..<end))+"."+UUID().uuidString
}

class CSyncTests: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	// This test should verify that the example code in the README.md is correct
	func testREADME() {

		// Connecting to a CSync store

		let app = App(host: "csync-ga6z7rK.mybluemix.net", port: 667)

		let userjwt = "user@pickles.com"
		app.authenticate("google", token: userjwt, completionHandler: nil)

		// Listening for values on a key

		let myKey = app.key("a.b.c.d.e")

		myKey.listen { _, error in
			if error != nil {
				// handle error
			}
			// value contains newly updated value for key
		}

		// Writing a value into the CSync store

		myKey.write("value")  { _, error in
			if error != nil {
				// handle error
			}
			// Server has accepted write of value to key
		}

		// Writing a value into the CSync store with a given ACL

		myKey.write("value", with: ACL.PublicReadWrite)  { _, error in
			if error != nil {
				// handle error
			}
			// Server has accepted write of value to key
		}

		// Unlistening

		myKey.unlisten()

	}

	func testAppProperties() {

		let version = App.sdkVersion
		// swiftlint:disable:next force_try
		let regex = try! NSRegularExpression(pattern: "^\\d{1,}\\.\\d{1,}\\.\\d{1,}$")
		let match = regex.matches(in: version, range: NSRange(location: 0, length: version.characters.count))
		XCTAssertNotNil(match)

		let host = "csync-ga6z7rK.mybluemix.net"
		let port = 667

		// Connect to the CSync store
		let csync = App(host: host, port: port)

		XCTAssertEqual(csync.host, host)
		XCTAssertEqual(csync.port, port)

		XCTAssertNil(csync.authData, "authData should be nil before authenticate has been called.")
		XCTAssertTrue(!csync.connected)
	}

}
