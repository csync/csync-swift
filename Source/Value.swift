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

import Foundation

typealias VTS = Int64
typealias VTSSet = (lvts: VTS?,rvts: VTS?)

// MARK: - Value

/**
A Value object is an immutable image of the value and metadata for a Key stored by
the CSync service.
*/
@objc(CSValue)
open class Value : NSObject
{
	/** The string representation of the key for the entry in the CSync service (read-only). */
	private(set) public var key : String

	/** A boolean value that indicates whether the entry exists (YES) or has been deleted (NO) (read-only). */
	private(set) public var exists : Bool

	/** A boolean value that indicates whether the entry has been accepted and stored on the server (YES)
	    or is a local write that is pending confirmation by the server (NO) (read-only). */
	private(set) public var stable : Bool

	/** The data for this entry (read-only). */
	private(set) public var data : String?

	/** The id of the access control list associated with this entry (read-only).

	Values that are `stable` will always have an associated aclid.  The acl for a local write may not be known
	until the write is accepted by the server, so the aclid may not be set for non-`stable` entries.
	*/
	private(set) public var acl : String?

	/** The uid of the creator of this entry (read-only).*/
	private(set) public var creator : String

	// Internal properties
	var cts : Int64
	var vts : VTS

	// swiftlint:disable:next function_parameter_count
	init(key: String, exists: Bool, stable: Bool, data: String?, acl: String, creator: String, cts: Int64, vts: VTS)
	{
		self.key = key
		self.exists = exists
		self.stable = stable
		self.data = data
		self.acl = acl
		self.creator = creator
		self.cts = cts
		self.vts = vts
	}

}
