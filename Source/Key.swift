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

// MARK: - Key object

// Note: Design of this class is modeled after NSURL.

/**
A Key object represents a key identifying a data value stored in a CSync data store.  A Key
object may also represent a key pattern containing wildcards that describes a set of keys.
You can use Key objects to construct Keys and access their components.

Keys are composed from a sequence of components.
Key components may contain uppercase and lowercase alphabetic, numeric, "_", and "-".
Key components must contain at least one character; an empty string is not a valid component.
Keys may contain a maximum of 16 components.

Keys also have a string representation in which the components are joined together
with a separator, a period ('.') between components.
The total length of the key string may not exceed 200 characters (bytes?).

Keys with a first component of "sys" are reserved for use by CSync.

TODO: add a discussion of the hierarchical structure of keys, with a single root key.

A Key may specify a key pattern which has one or more components containing
one of the following wildcard characters:

- '*': matches any value of the specified component
- '#': matches any value for this and all subsequent components, including an empty value

Wildcard characters must appear alone; wildcard characters cannot be combined with regular key
characters or which each other.
Furthermore, only the final component of a Key may contain the '#' wildcard.

TODO: give examples of pattern matches and non-matches
*/
@objc(CSKey)
open class Key : NSObject
{
	static var nonKeyChars : CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-").inverted

	@available(*, unavailable, message: "Don't use init() on Key") public override init() {
		fatalError("Don't use init() on Key")
	}
	// MARK: - Key Internal initializers

	/**
	Initializes a Key object with the components specified in `components`.

	**Parameters**

	- components:	An array of string components to be combined into a key

	**Return Value**

	A Key object initialized with the components specified in `components`.

	*/
	internal init(components: [String], app: App) {
		self.app = app
		self.components = components
		key = components.joined(separator: ".")
		super.init()
		//logger.logLevel(LogLevel.Debug)
	}

	/**
	Initializes an Key object with a provided key string.

	This method expects key to contain only characters that are allowed in a
	properly formed Key.

	**Parameters**

	- keyString: The Key string with which to initialize the Key object.
	This Key string must conform to rules for Key values described above
	and must not be nil.

	**Return Value**

	A Key object initialized with the value of `key`.

	*/
	convenience init(key: String, app: App) {
		let components = Key.components(key)
		self.init(components: components, app: app)
	}

	// MARK: Key properties

	/** The App associated with this entry (read-only). */
	private(set) open var app : App

	/**
	The string representation of the Key (read-only).
	*/
	open private(set) var key : String!

	/**
	The components of the Key (read-only).
	*/
	open private(set) var components: [String]

	/**
	The last component of the Key (nil for root key) (read-only).
	*/
	lazy open var lastComponent : String? = {
		return self.components.last
	}()

	override open var description : String {
		return key
	}

	/**
	If the key is invalid, an error value specifying the problem (read-only).
	*/
	lazy open var error : NSError? = {

		// Check number of components is <= 16
		if self.components.count > 16 {
			return err(CSError.invalidKey, msg: "Key contains more than 16 components")
		}

		var keyLength = -1		// Init to -1 since we need one fewer separators than components

		// Check each component for valid structure
		for (index, p) in self.components.enumerated() {

			// Each component must be non-empty
			if p.characters.count == 0 {
				return err(CSError.invalidKey, msg: "Key contains empty component")
			}

			// Each component must be a wildard or contain only valid key characters
			if (p == "*")								// Asterisk can appear anywhere
				|| (p == "#" && index == (self.components.count-1))	// Pound must be last component
				|| p.rangeOfCharacter(from: Key.nonKeyChars) == nil {
					// null then path
			} else {
				return err(CSError.invalidKey, msg:"Key contains invalid character")
			}

			keyLength += p.characters.count + 1
		}

		// Check keyString length <= 200
		if keyLength > 200 {
			return err(CSError.invalidKey, msg:"Key exceeds maximum length of 200 characters")
		}

		return nil
	}()

	/**
	A boolean value that indicates if the Key is a key pattern (read-only).
	*/
	open private(set) lazy var isKeyPattern : Bool = {
		self.components.reduce(false, {(r, p) in r || (p == "*") || (p == "#")})
	}()

	// MARK: Creating Related Key Objects

	/**
	Returns a new Key made by removing the last component from the original key.

	If the original key is the root key (has no components), this function returns a
	copy of the root key.

	**Return Value**

	A Key object made by removing the last component from the original key.

	*/
	open var parent: Key {
		let last = self.components.isEmpty ? 0 : components.endIndex-1
		return Key(components: Array(components[0..<last]), app: app)
	}

	/**
	Returns a new Key made by appending a component to the original key.

	**Parameters**

	- childname:	The component to append to the receiving key.
	This component must conform to rules for Key values described above
	and must not be nil.

	**Return Value**

	A Key object made by appending the `childname` component to the original key.

	*/
	open func child(_ childname: String) -> Key {
		return Key(components: self.components + [childname], app: app)
	}

	/**
	Returns a new Key made by appending a unique component to the original key.

	**Return Value**

	A Key object made by appending a unique component to the original key.

	*/
	open func child() -> Key {
		return child(UUID().uuidString)
	}

	// MARK: Obtaining data from the CSync store

	/**
	Registers `listener` to receive the current value and value updates for a specified key or keys
	matching a pattern.

	Values are delivered to the specified listener along with the associated key, ACL, and
	a flag that indicates if the key has been deleted.  Only keys/values for which the user
	has at least read access are delivered.

	A Key may have at most one listener.  If listen is called for a Key that already has a registered
	listener, the prior listener is removed and replaced with the one specified on this call.

	**Parameters**

	- listener:	A callback to receive values for the specified key or key pattern.

	*/
	open func listen(_ listener:@escaping (_ value: Value?, _ error: NSError?) -> Void) {

		logger.trace("listen for key \(key)")

		guard error == nil else {
			DispatchQueue.main.async {
				listener(nil, self.error!)
			}
			return
		}

		self.listener = listener
		self.latest = [:]	// Clear latest so all values are delivered to new listener

		// Add this key to an internal list of all active listeners
		app.addListener(self)
	}

	/**
	Unregister `listener` from receiving value updates for a specified key or keys matching
	a pattern.
	*/
	open func unlisten() {

		logger.trace("unlisten for key \(key)")

		self.listener = nil

		// Note: listener will be removed from app.listeners on the next inbound message

		// Send unlisten request to the server

		if !app.hasListener(key) {
			let subOp = SubOperation(key: self)
			subOp.delete = true
			app.addOperation(subOp)
		}
	}

	// MARK: Updating data in the CSync store

	/**
	Writes the specified data into the persistent key/value store for the given key.

	The user must have write permisson to the entry for this key or the write is rejected.

	The key specified for the write may not contain wildcards.
	
	The ACL is inherited from its closest existing ancestor, up to the root key which has ACL PublicCreate

	**Parameters**

	- data:		The data to be stored and distributed to any clients listening on this key.
	- completionHandler: A block that will be called with the response from the service when it
			has accepted or rejected the write

	*/
	open func write(_ data: String, completionHandler:((_ key: Key, _ error: NSError?) -> Void)?)
	{
		logger.trace("write for key \(key)")

		let writeOp = PubOperation(key: self)
		writeOp.data = data
		writeOp.completionHandler = completionHandler
		app.addOperation(writeOp)
	}

	/**
	Writes the specified data into the persistent key/value store for the given key.

	The user must have write permisson to the entry for this key or the write is rejected.

	The key specified for the write may not contain wildcards.

	**Parameters**

	- data:		The data to be stored and distributed to any clients listening on this key.

	*/
	open func write(_ data: String)
	{
		write(data, completionHandler: nil)
	}

	/**
	Writes the specified data into the persistent key/value store for the given key.

	The user must have write permisson to the entry for this key or the write is rejected.

	The key specified for the write may not contain wildcards.

	- SeeAlso: `ACL`

	**Parameters**

	- data:		The data to be stored and distributed to any clients listening on this key.
	- acl:		The access control list specifying the access allowed by other users.
	- completionHandler: A block that will be called with the response from the service when it
			has accepted or rejected the write

	*/
	open func write(_ data: String, with acl: ACL, completionHandler:((_ key: Key, _ error: NSError?) -> Void)?)
	{
		logger.trace("write for key \(key)")

		let writeOp = PubOperation(key: self)
		writeOp.data = data
		writeOp.aclid = acl.id
		writeOp.completionHandler = completionHandler
		app.addOperation(writeOp)
	}

	/**
	Writes the specified data into the persistent key/value store for the given key.

	The user must have write permisson to the entry for this key or the write is rejected.

	The key specified for the write may not contain wildcards.

	- SeeAlso: `ACL`

	**Parameters**

	- data:		The data to be stored and distributed to any clients listening on this key.
	- acl:		The access control list specifying the access allowed by other users.

	*/
	open func write(_ data: String, with acl: ACL)
	{
		write(data, with: acl, completionHandler: nil)
	}

	/**
	Deletes the key and its data from the CSync store.

	The key specified on delete may contain wildcards, which specifies that all keys in the
	CSync store matching the key patterns are deleted.  Only keys for which the user has delete
	permission are deleted.

	**Parameters**

	- completionHandler: A block that will be called with the response from the service when it
			has accepted or rejected the delete

	*/
	open func delete(_ completionHandler:((_ key: Key, _ error: NSError?) -> Void)?)
	{
		logger.trace("delete for key \(key)")

		let writeOp = PubOperation(key: self)
		writeOp.delete = true
		writeOp.completionHandler = completionHandler
		app.addOperation(writeOp)
	}

	/**
	Deletes the key and its data from the CSync store.

	The key specified on delete may contain wildcards, which specifies that all keys in the
	CSync store matching the key patterns are deleted.  Only keys for which the user has delete
	permission are deleted.

	*/
	open func delete()
	{
		delete(nil)
	}

	// MARK: - Key internals

	class func components(_ keyStr: String) -> [String] {
		let components = (keyStr.characters.count == 0) ? [] :
			keyStr.characters.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
		return components
	}

	private let logger = Logger("Key")

	var listener : ((_ value: Value?, _ error: NSError?) -> Void)?

	// Map from (concrete) keystring to highest VTS delivered to this listener
	// Serialization: This structure should only be accessed on the main queue, just before invoking the
	// listener (or otherwise scheduled on the main queue)
	private var latest : [String:VTS] = [:]

	func deliver(_ value : Value)
	{
		guard listener != nil else {
			return
		}

		DispatchQueue.main.async {
			// Check again, just to be sure
			if let listenerCallback = self.listener {
				// Check that the value to be delivered is more recent than the last value
				// delivered to this listener for this key.  If not, we simply skip it.
				let latestVts = self.latest[value.key] ?? 0
				if latestVts < value.vts {
					self.latest[value.key] = value.vts
					listenerCallback(value, nil)
				}
			}
		}
	}

	/* Return true if the concrete key `other` matches the key (which may be a key pattern) of this Key.

	`other` is assumed to be a valid key and no effort is made to confirm this assumption.  This means
	that the return value of this method could be incorrect if `other` is not a valid key.
	*/
	func matches(_ other: String) -> Bool {
		if !self.isKeyPattern {
			return (self.key == other)
		}
		let otherComponents = Key.components(other)

		// Check for match component by component
		for (index, p) in components.enumerated() {
			if p == "#" {
				return true
			}
			if otherComponents.count-1 < index {
				return false
			}
			if p != otherComponents[index] && p != "*" {
				return false
			}
		}

		return (components.count == otherComponents.count)
	}

}

// Equatable protocol methods
internal func == (left: Key, right: Key) -> Bool {
	return (left.key == right.key)
}
