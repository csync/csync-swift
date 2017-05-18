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

import Foundation

/*
* Request  -- contains the details of the request
*      example: { "path" : [ "root", "a", "b" ], "data" : "abc" }
* Request.ResponseEnvelope -- contains the request and some data about it
*      example:
*          { "kind" : "write",
*            "closure" : { "id" : 100 },
*            "payload" : { "path" : [ "root", "a", "b" ], "data" : "abc" }
*          }
*/

class Request
{
	enum RequestType : String {
		case sub = "sub"		// path
		case unsub = "unsub"		// path
		case pub = "pub"		// path, data, cts, deletePath, assumeACL?
		case getacls = "getAcls"	//
		case advance = "advance"	// pattern, rvts
		case fetch = "fetch"		// [vts]
	}

	// swiftlint:disable:next variable_name
	static let MESSAGE_VERSION = 15

	private (set) static var counter : Int64 = 0
	class func next() -> Int {
		let next = OSAtomicIncrement64(&counter)
		return Int(next)
	}

	let kind : RequestType
	let closure : Int

	var payload : [String: AnyObject] = [:]

	private let logger = Logger("Request")

	var assumeACL : String? {
		get { return payload["assumeACL"] as? String }
		set(newValue) { payload["assumeACL"] = newValue as AnyObject? }
	}

	init(kind: RequestType) {
		self.kind = kind
		self.closure = Request.next()
	}

	class func pub(_ key: Key, data: String?, delete: Bool = false, cts: Int64) -> Request {
		let req = Request(kind: RequestType.pub)
		req.payload = [
			"path" : key.components as AnyObject,
			"cts": NSNumber(value: cts as Int64),
			"deletePath": delete as AnyObject ]
		if data != nil {
			req.payload["data"] = data! as AnyObject?
		}
		return req
	}

	class func sub(_ key: Key) -> Request {
		let req = Request(kind: RequestType.sub)
		req.payload = [ "path" : key.components as AnyObject ]
		return req
	}

	class func unsub(_ key: Key) -> Request {
		let req = Request(kind: RequestType.unsub)
		req.payload = [ "path" : key.components as AnyObject ]
		return req
	}

	class func getAcls() -> Request {
		let req = Request(kind: RequestType.getacls)
		return req
	}

	class func advance(_ key: Key, rvts: VTS? = nil,  lvts: VTS? = nil, forwardLimit: Int? = nil, backwardLimit: Int? = nil) -> Request {
		let req = Request(kind: RequestType.advance)
		req.payload = [
			"pattern" : key.components as AnyObject
		]
		if let rvts = rvts {
			req.payload["rvts"] = NSNumber(value:rvts as Int64)
		}
		if let lvts = lvts {
			req.payload["lvts"] = NSNumber(value:lvts as Int64)
		}
		if let forwardLimit = forwardLimit {
			req.payload["forwardLimit"] = NSNumber(value:forwardLimit)
		}
		if let backwardLimit = backwardLimit {
			req.payload["backwardLimit"] = NSNumber(value:backwardLimit)
		}
		return req
	}

	class func fetch(_ vts: [VTS]) -> Request {
		let req = Request(kind: RequestType.fetch)
		req.payload = [ "vts" : vts as AnyObject]
		return req
	}

	var error : NSError?

	lazy var message : String? = {

		let msgDict : NSDictionary = [
			"kind": self.kind.rawValue,
			"closure": NSNumber.init(value: self.closure as Int),
			"payload" : self.payload as NSDictionary,
			"version" : MESSAGE_VERSION ]
		do {
			let data = try JSONSerialization.data(withJSONObject: msgDict, options: JSONSerialization.WritingOptions(rawValue: 0))
			let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
			return string
		} catch let error as NSError {
			self.logger.error("Error serializing JSON message: \(error.localizedDescription)")
			self.error = err(CSError.invalidRequest, msg: error.localizedDescription)
		}
		return nil
	}()
}
