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
* Response  -- contains the details of the response
*      example: { "code" : 4, "msg" : "path not found" }
* Response.ResponseEnvelope -- contains the response and some data about it
*     example:
*         { "kind" : "sad",
*           "closure" : { "id" : 100 },
*           "payload" : { "code" : 4, "msg" : "path not found" }
*         }
*/

class Response
{
	enum ResponseType : String
	{
		case happy = "happy"		// closure, payload [ code, msg ]
		case error = "error"		// closure, payload [ msg, cause ]
		case data = "data"		// payload [ path, acl, data, creator, deletePath, cts, vts ]
		case getAcls = "getAclsResponse" // closure, payload [ [acls] ]
		case advance = "advanceResponse" // payload [ [vts] ]
		case fetch = "fetchResponse"     // payload [ response [values] ]
		case connect = "connectResponse" // payload [ uuid, uid, expires ]
	}

	// swiftlint:disable:next variable_name
	static let MESSAGE_VERSION = 15

	// The app associated with this response instance
	unowned let app : App

	let version: Int
	let kind : ResponseType

	var closure : Int?
	var payload : [String: AnyObject] = [:]

	var error : NSError?

	// Acls for GetAcls response
	var acls : [String]? {
		return payload["acls"] as? [String]
	}

	// Values for Data msg or Fetch response
	var values : [Value]?

	// vts and maxvts for Advance response
	var vts : [VTS] {
		// Treat missing vts array as empty
		return payload["vts"] as? [VTS] ?? []
	}
	var maxvts : VTS? {
		return payload["maxvts"] as? VTS
	}

	// Expected values for Connect response
	var uuid : String? {
		return payload["uuid"] as? String
	}
	var uid : String? {
		return payload["uid"] as? String
	}
	var expires : Int? {
		return payload["expires"] as? Int
	}

	private static let staticLogger = Logger("Response")

	init(app: App, kind: ResponseType, version: Int) {
		self.app = app
		self.kind = kind
		self.version = version
	}

	subscript(key: String) -> AnyObject? {
		get { return payload[key] }
	}

	class func fromIncoming(_ app: App, message: String) -> Response?
	{
		let msgDict : [String:AnyObject]!
		do {
			let data = (message as NSString).data(using: String.Encoding.utf8.rawValue)!
			msgDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String:AnyObject]
		} catch let error as NSError {
			staticLogger.error("Error deserializing JSON message: \(error.localizedDescription)")
			return nil
		}

		guard let version = msgDict["version"] as? Int, version == MESSAGE_VERSION else {
			staticLogger.error("Error deserializing JSON message: version missing or invalid")
			return nil
		}

		guard let rawKind = msgDict["kind"] as? String,
		    let kind = ResponseType.init(rawValue: rawKind) else {
			staticLogger.error("Error deserializing JSON message: kind missing or invalid")
			return nil
		}

		guard let payload = msgDict["payload"] as? [String: AnyObject] else {
			staticLogger.error("Error deserializing JSON message: payload missing or invalid")
			return nil
		}

		let response = Response(app: app, kind: kind, version: version)
		response.payload = payload
		response.closure = msgDict["closure"] as? Int

		response.parsePayload()

		return response
	}

	// swiftlint:disable:next cyclomatic_complexity
	private func parsePayload()
	{
		switch kind {
		case .happy:
			if let code = payload["code"] as? Int, code != 0,
			    let msg = payload["msg"] as? String {
				error = err(CSError.requestError, msg: "\(msg). Code(\(code))")
			}

		case .error:
			if let msg = payload["msg"] as? String {
				if msg.range(of: "Token validation failed") != nil {
					error = err(CSError.authenticationError, msg:"\(msg)")
				} else {
					error = err(CSError.internalError, msg:"\(msg)")
				}
			}

		case .data:
			if let keyArr = payload["path"] as? [String],
			    let deletePath = payload["deletePath"] as? Bool,
			    let data = payload["data"] as? String?,
			    let acl = payload["acl"] as? String,
			    let creator = payload["creator"] as? String,
			    let cts = (payload["cts"] as? NSNumber)?.int64Value,
			    let vts = (payload["vts"] as? NSNumber)?.int64Value {
				let keyString = keyArr.joined(separator: ".")
				values = [Value(key: keyString, exists: !deletePath, stable: true, data: data,
				                       acl: acl, creator: creator, cts: cts, vts: vts)]
			} else {
				let msg = "Malformed data message"
				Response.staticLogger.error(msg)
				error = err(CSError.internalError, msg:"\(msg)")
			}

		case .getAcls:
			if acls == nil {
				let msg = "Malformed getAcls response"
				Response.staticLogger.error(msg)
				error = err(CSError.internalError, msg:"\(msg)")
			}

		case .connect:
			if (uuid == nil) || (uid == nil) || (expires == nil) {
				let msg = "Malformed connect response"
				Response.staticLogger.error(msg)
				error = err(CSError.internalError, msg:"\(msg)")
			}

		case .advance:
			// All payload values in advance response are optional
			break

		case .fetch:
			if let responses = payload["response"] as? [AnyObject] {
				var values : [Value] = []
				for index in responses.indices {
					if let response = responses[index] as? [String:AnyObject],
						let keyArr = response["path"] as? [String],
						let deletePath = response["deletePath"] as? Bool,
						let data = response["data"] as? String?,
						let acl = response["acl"] as? String,
						let creator = response["creator"] as? String,
						let cts = (response["cts"] as? NSNumber)?.int64Value,
						let vts = (response["vts"] as? NSNumber)?.int64Value {
						let keyString = keyArr.joined(separator: ".")
						let value = Value(key: keyString, exists: !deletePath, stable: true,
						                  data: data, acl: acl, creator: creator, cts: cts, vts: vts)
						values.append(value)
					}
				}
				self.values = values
			} else {
				let msg = "Malformed fetch response"
				Response.staticLogger.error(msg)
				error = err(CSError.internalError, msg:"\(msg)")
			}

		}
	}
}
