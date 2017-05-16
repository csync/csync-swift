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

// MARK: - CSError

/** CSync Error Codes */
@objc public enum CSError : Int, Error {
	/** CSync encountered an error. This is a non-recoverable error. */
	case internalError = 1
	/** The key for this request is not valid */
	case invalidKey
	/** The request specified invalid parameters. */
	case invalidRequest
	/** The request failed at the CSync server. */
	case requestError
	/** Authentication failed for this CSync instance */
	case authenticationError
	/** Server database is corrupted or unusable */
	case badDatabase
}

internal func err(_ code: CSError, msg: String) -> NSError
{
	return NSError(domain: code._domain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: msg])
}

// MARK: - App object

/**
A App object represents an application with a persistent connection a CSync service.
Applications use the App object to authenticate app users and to generate references
to specific entries in a CSync data store.

## Subclassing Notes

Do not subclass App.

*/
@objc(CSApp)
public class App : NSObject
{
	// MARK: Creating a Connection to a CSync service

	public init(host: String, port: Int, options:[String:AnyObject]) {
		self.options = options
		operationQueue = OperationQueue()
		super.init()
		transport = Transport(app: self, host: host, port: port)
		database = Database(app: self)
	}

	/**
	Initialize a connection to the CSync service.

	Initialize a connection to the CSync service on the specified host and port.

	TODO: How does the app know when there are issues with the connection (permanent problems)?

	**Parameters**

	- host:			The DNS name or IP address of the CSync service
	- port:			The port for the CSync service

	*/
	public convenience init(host: String, port: Int) {
		self.init(host: host, port: port, options: [:])
	}

	/**
	Close the connection to the CSync service.

	All outstanding listens on this CSync service are cancelled and resources for connecting to the CSync
	service are released.  Subsequent calls to write or listen on this App object will fail.
	*/
	public func close() {
		// TODO: Add implementation for close() method
	}

	// MARK: App properties

	/** The CSync SDK version (read-only) */
	public static let sdkVersion = "0.1.0"

	/** The DNS name or IP address of the CSync service (read-only) */
	public var host : String  { return transport.host }

	/** The port for the CSync service (read-only) */
	public var port : Int { return transport.port }

	/**
	A Boolean value that indicates whether the client is currently connected to the CSync service. (read-only)

	The SDK monitors the connection state with the server and will attempt to re-establish the connection if it
	is lost.  However, there may be periods of time when the connection is not available, e.g. due to lack of
	network connectivity at the client.  When disconnected, the SDK will service listen requests from its local
	cache and will buffer writes until connectivity is re-established and they can be sent to the server.

	The application may wish to use the `connected` property to determine when listen results may not represent
	the most complete and most recent data due to lack of connectivity with the server.  The application may also
	choose to suspend or simply bypass writes when the client is disconnected.

	*/
	public var connected : Bool {
		return transport.connected
	}

	/** The the authentication context for the user of the CSync service. (read-only) */
	private(set) public var authData: AuthData?

	// MARK: Authenticating the app user to the CSync Service

	/**
	Authenticate to the CSync service with an OAuth token from a provider.

	This method works with current OAuth 2.0 providers such as Facebook, Google+, and Github.

	**Parameters**

	- oauthProvider:    The provider, all lower case with no spaces.
	- token:	    The OAuth Token to authenticate with the provider.
	- completionHandler: A block to receive the results of the authentication attempt.

	*/
	@objc(authenticateWithOAuthProvider:token:completionHandler:)
	public func authenticate(_ oauthProvider: String, token: String, completionHandler:((_ authData: AuthData?, _ error: NSError?) -> Void)?) {
		if transport.sessionId != nil {
			unauth()
		}

        if !transport.canConnect{
            //The socket is not able to open another connection at the moment, return an error
            completionHandler?(nil, err(CSError.internalError, msg:"Unable to open a socket connection, please try again later"))
            return
        }

		authCallback = completionHandler
		transport.startSession(oauthProvider, token: token)
	}

	/**
	Clears any credentials associated with this App.

	All outstanding writes and listens are cancelled.
	*/
	public func unauth(_ completionHandler: ((_ error: NSError?) -> Void)? = nil )
	{
		// Clear credentials and acls
		authData = nil
		acls = nil
		transport.clearSessionInfo()

		if let authCallback = authCallback {
			authCallback(nil, CSError.requestError as NSError?)
			self.authCallback = nil
		}
		if transport.canDisconnect {
			//Store callback to call it when the socket has closed
			unauthCallback = completionHandler

			// Close session with the server
			transport.endSession()

			// Cancel any outstanding operations
			for pendingOp in operationQueue.operations {
				pendingOp.cancel()
			}
		} else {
			completionHandler?(nil)
		}
	}

	// MARK: Creating references to entries in the CSync service

	/**
	Create a Key for an entry in the CSync service.

	**Parameters**

	- key:    The key for the entry expressed as a string containing components separated by periods ('.').
	*/
	@objc(keyWithString:) public func key(_ key: String) -> Key
	{
		return Key(key: key, app:self)
	}

	/**
	Create a Key for an entry in the CSync service.

	**Parameters**

	- components:    The key for the entry expressed as a string containing components separated by periods ('.').
	*/
	@objc(keyWithComponents:) public func key(_ components: [String]) -> Key
	{
		return Key(components: components, app:self)
	}

	// MARK: - App internal properties

	let options : [String:AnyObject]
	let operationQueue : OperationQueue
	// Force unwrapped optional due to needing self in initialization
	var transport : Transport!
	var database : Database!

	var rvts : [String:VTS] = [:]

	var acls : [String]?

	var serverUUID : String?

	let logger = Logger("App")

	let stats = Stats()

	var authCallback : ((_ authData: AuthData?, _ error: NSError?) -> Void)?
	var unauthCallback : ((_ error: NSError?) -> Void)?

	// MARK: - App internal methods

	/* This method should be called from the transport layer whenever a "connect response" is received
	   from the server.  It must verify that the server instance UUID has not changed and that the
	   user authentication was successful */
	func handleConnect(_ sessionInfo: SessionInfo?, error: NSError?)
	{
		logger.trace("Entry to app.handleConnect")

		func scheduleAuthCallback(_ authData: AuthData?, error: NSError?) {
			if let callback = authCallback {
				authCallback = nil
				DispatchQueue.main.async {
					callback(authData, error)
				}
			}
		}

		guard error == nil else {
			scheduleAuthCallback(nil, error: error)
			return
		}

		guard let sessionInfo = sessionInfo else {
			let error = err(CSError.internalError, msg:"No sessionInfo for connect")
			scheduleAuthCallback(nil, error: error)
			return
		}

		// Verify server instance by checking UUID

		if serverUUID != nil && serverUUID! != sessionInfo.uuid {
			// Server instance has changed.
			// Close session with the server with permanent failure
			let uuidError = err(CSError.badDatabase, msg:"Unrecoverable failure. Server instance has changed.")
			transport.endSessionPermanently(uuidError)

			// Clear all credentials
			authData = nil
			acls = nil

			// Invoke the callback if one is present
			scheduleAuthCallback(nil, error: uuidError)

			return
		}

		if serverUUID == nil {
			serverUUID = sessionInfo.uuid
		}

		// Construct authdata if needed

		if authData == nil {

			guard let provider = transport.authProvider,
				let token = transport.token else {
					logger.error("[\(#function)] No credentials for open session")
					return
			}

			// construct Authdata
			authData = AuthData(
				uid:sessionInfo.userid,
				provider: provider,
				token: token,
				expires: sessionInfo.tokenExpires)
		}

		scheduleAuthCallback(self.authData, error: nil)

		// drive the handleConnect method of any queued operations that have started executing

		for op in operationQueue.operations {
			if let op = op as? Operation, op.isExecuting {
				op.handleConnect()
			}
		}
	}

	/* This method should be called from the transport layer whenever the socket has officially been between the server and sdk.
	It is used to handle the completion handler on the unauth function. */
	func handleDisconnect(){
		if let callback = unauthCallback {
			unauthCallback = nil
			DispatchQueue.main.async {
				callback(nil)
			}
		}
	}

	// MARK: Operation Queue methods

	func addOperation(_ op: Operation)
	{
		if let writeOp = op as? PubOperation {
			queueWrite(writeOp)
		} else if let subOp = op as? SubOperation {
			queueSub(subOp)
		} else {
			operationQueue.addOperation(op)
		}
	}

	private func queueWrite(_ writeOp: PubOperation)
	{
		// Serialize write operations to the same key

		let pendingOps = operationQueue.operations

		for pendingOp in pendingOps.reversed() {
			if let pendingWrite = pendingOp as? PubOperation {
				if !pendingWrite.isFinished && (pendingWrite.key == writeOp.key) {
					writeOp.addDependency(pendingWrite)
					break
				}
			}
		}

		operationQueue.addOperation(writeOp)
	}

	private func queueSub(_ subOp: SubOperation)
	{
		// Serialize sub operations to the same key

		let pendingOps = operationQueue.operations

		for pendingOp in pendingOps.reversed() {
			if let pendingSub = pendingOp as? SubOperation {
				if !pendingSub.isFinished && (pendingSub.key == subOp.key) {
					subOp.addDependency(pendingSub)
					break
				}
			}
		}

		operationQueue.addOperation(subOp)
	}

	// MARK: Listener functions

	private var listeners : [Key] = []

	func addListener(_ keyObj: Key)
	{
		guard keyObj.listener != nil else {
			return
		}

		objc_sync_enter(self.listeners)

		let newListener = !hasListener(keyObj.key)

		if !listeners.contains(keyObj) {
			listeners.append(keyObj)
		}
		objc_sync_exit(self.listeners)

		DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: {
			self.deliverFromDB(keyObj)
		})

		if newListener {
			// Send listen request to the server
			let subOp = SubOperation(key: keyObj)
			addOperation(subOp)

			// Also kick off an advance
			startAdvance(keyObj)
		}
	}

	func deliverFromDB(_ key: Key)
	{
		do {
			let dbValues = try Latest.values(in: database, for:key)
			//Only deliver keys that still exist at this moment.
			for value in dbValues where value.exists == true {
				key.deliver(value)
			}
		} catch let err as Any {
			logger.error("deliverFromDB failed: \(err)")
		}
	}

	func updateLatest(_ value: Value) -> Bool
	{
		var retval = false
		do {
			try database.transaction {
				let vts = try Latest.vts(in: self.database, for:value.key)
				if vts == nil || vts! < value.vts {
					try _ = Latest.insert(self.database, value:value)
					retval = true
				}
				try _ = Log.insert(self.database, value:value)
			}
		} catch let err as Any {
			logger.error("updateLatest failed: \(err)")
		}
		return retval
	}

	func deliverToListeners(_ value: Value)
	{
		let keystring = value.key

		logger.trace("Entry to deliverToListeners for key \(keystring)")

		objc_sync_enter(self.listeners)

		// First remove any keys that are no longer listening
		listeners = listeners.filter{ key in key.listener != nil }

		for key in listeners where key.matches(keystring) {
			key.deliver(value)
		}
		objc_sync_exit(self.listeners)
	}

	func hasListener(_ key: String) -> Bool
	{
		for keyObj in listeners {
			if (keyObj.key == key) && (keyObj.listener != nil) {
				return true
			}
		}
		return false
	}

	func startAdvance(_ key: Key)
	{
		logger.trace("Starting advance for \(key.key)")

		let advanceOp = AdvanceOperation(key: key)
		operationQueue.addOperation(advanceOp)
	}
}
