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
import SwiftWebSocket

struct SessionInfo
{
	let uuid : String
	let userid : String
	let tokenExpires : Int
	let tokenInfo : Dictionary<String, AnyObject>
}

class Transport
{
	/** The app associated with this transport instance */
	weak var app : App! 	// declared weak rather than unowned to avoid swift_abortRetainUnowned crash

	/** The DNS name or IP address of the CSync service (read-only) */
	let host : String!
	/** The port for the CSync service (read-only) */
	let port : Int!

	typealias TransportCallback = (_ response: Response?, _ error: NSError?)->()

	private let ws : WebSocket!
	private var wsState : WebSocketReadyState = .closed

	/** OAuth token */
	var authProvider : String?
	var token : String?

	var sessionId : String?

	private let logger = Logger("Transport")

	var msgQueue : [Request] = []
	var callbacks : [Int : TransportCallback ] = [:]
	// FIXME: Need separate lock variable for now because Swift does not recognize callbacks as an AnyObject
	private var callbacksLock : AnyObject = NSObject()

	init(app: App, host: String, port: Int) {
		self.app = app
		self.host = host
		self.port = port
		self.ws = WebSocket()

		// Set up WebSocket event handlers
		ws.event.open = handleOpen
		ws.event.message = handleMessage
		ws.event.error = handleError
		ws.event.close = handleClose
	}

	/**
	A Boolean value that indicates whether the transport is currently connected to the CSync service.
	*/
	var connected : Bool {
		return wsState == .open
	}

	/**
	A Boolean value that indicates if the socket is in a state where we can setup a connection
	*/
	var canConnect : Bool {
		return wsState == .closed
	}

	/**
	A Boolean value that indicates if the socket is in a state where it can close a connection.
	There is no point in closing a connection that is closed or in the process of closing.
	*/
	var canDisconnect : Bool {
		return wsState == .open || wsState == .connecting
	}

	/**
	Starts a session with the server.
	*/
	func startSession(_ authProvider: String, token: String) -> () {
		// For now, we simply return if a session is active
		guard sessionId == nil else {
			return
		}

		guard permanentError == nil else {
			app.handleConnect(nil, error: permanentError!)
			return
		}

		// Set session ID
		self.authProvider = authProvider
		self.token = token
		sessionId = UUID().uuidString
		connect()
	}

	/**
	Ends a session with the server.
	*/
	func endSession() -> () {

		clearSessionInfo()
		// Close the connection to the server
		wsState = .closing
		ws.close()
	}

	/**
	Clear Session information.
	*/
	func clearSessionInfo() -> () {
		// Clear session info
		authProvider = nil
		token = nil
		sessionId = nil

	}

	var permanentError : NSError? = nil

	func endSessionPermanently(_ error: NSError) {
		permanentError = error
		endSession()
	}

	/**
	Send a request message
	*/
	func send(_ req : Request, callback: @escaping TransportCallback) -> () {
		if !connected {
			guard permanentError == nil else {
				DispatchQueue.main.async {
					callback(nil, self.permanentError!)
				}
				return
			}
			connect()
		} else {
			if let message = req.message {
				objc_sync_enter(callbacksLock)
				callbacks[req.closure] = callback
				objc_sync_exit(self.callbacksLock)

				ws.send(message)
			} else {
				DispatchQueue.main.async {
					callback(nil, req.error!)
				}
			}
		}
	}

	// MARK: Internal methods

	private func connect() -> () {
		guard sessionId != nil else {
			logger.warn("Attempt to connect with no active session")
			return
		}

		// For now, we simply return if the ws is not in a state where we can reopen
		guard wsState == .closed else {
			logger.warn("Attempt to connect with active ws silently ignorned")
			return
		}

		let authParms : String
		if authProvider != nil && token != nil {
			let encodedProvider = authProvider!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
			let encodedToken = token!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
			authParms = "&authProvider=\(encodedProvider!)&token=\(encodedToken!)"
		} else {
			authParms = ""
		}

		let useSSL = !(app.options["useSSL"] as? String == "NO")
		let url = (useSSL ? "wss" : "ws") + "://\(host!):\(port!)/connect?sessionId=\(sessionId!)"+authParms

		wsState = .connecting
		ws.open(url)
	}

	// MARK: WebSocket event handlers

	private func handleOpen() -> () {
		logger.info("WebSocket opened")
		wsState = .open
	}

	// swiftlint:disable:next cyclomatic_complexity
	private func handleMessage(_ data : Any) -> () {
		// The following is to avoid swift_abortRetainUnowned crash
		guard app != nil else {
			return
		}

		guard let message = data as? String else {
			logger.error("Incoming data is not a string!")
			return
		}

		guard let response = Response.fromIncoming(app, message: message) else {
			logger.error("Cannot create Response from incoming message!")
			return
		}

		if let closure = response.closure {
			objc_sync_enter(callbacksLock)
			let callback = callbacks.removeValue(forKey: closure)
			objc_sync_exit(callbacksLock)

			if callback != nil {
				callback!(response, response.error as NSError?)
			} else {
				logger.error("Missing callback for closure \(closure)")
			}
		} else if response.kind == .data {
			for value in response.values! {
				if app.updateLatest(value) {
					app.deliverToListeners(value)
				}
			}
		} else if response.kind == .connect {
			if response.error != nil {
				app.handleConnect(nil, error: response.error!)
			} else {
				let sessionInfo = SessionInfo(uuid: response.uuid!, userid: response.uid!, tokenExpires: response.expires!, tokenInfo: [:])
				app.handleConnect(sessionInfo, error: nil)
			}
		} else if response.kind == .error {
			if response.error!.code == CSError.authenticationError.rawValue {
				app.handleConnect(nil, error: response.error)
			}
		} else {
			logger.error("Unhandled Response: \(response)")
		}
	}

	private func handleError(_ error : Error) -> () {
		wsState = ws.readyState
		logger.error("WebSocket reported error \(error)")
	}

	private func handleClose(_ code : Int, reason : String, wasClean : Bool) -> () {
		wsState = .closed
		logger.info("WebSocket closed: \(reason)")
		guard app != nil else {
			return
		}
		app.handleDisconnect()
	}

}
