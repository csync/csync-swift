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

/** CSync Access Control List

 The ACL class provides methods to create and inspect CSync Access Control Lists (ACLs).

 Each key in the CSync store has an associated access control list (ACL) that specifies
 which users can access the key.  Currently, three specific forms of access are defined:

 - Read: Users with read permission may read the data for the key.
 - Write: Users with write permission may write the data for the key.
 - Create: Users with create permission may create child keys of this key.

 The creator of a key in the CSync store has special permissions to the key.
 In particular, the creator always has Read, Write and Create permission.
 Permission to delete the key and change its ACL are currently reserved to the creator of the key.

 An ACL specifies the set of users to be granted Read, Write, and Create access to the key.
 CSync provides eight "static" ACLs that can be used to provide any combination of
 Read, Write, and Create access to just the key's creator or all users.

*/
@objc(CSAcl)
public class ACL : NSObject
{
	// MARK: - ACL class properties

	/** A static ACL that permits only the creator read, write and create access. */
	public static let Private : ACL = ACL(id: "$private")

	/** A static ACL that permits all users read access, but only the creator has write and create access. */
	public static let PublicRead : ACL = ACL(id: "$publicRead")

	/** A static ACL that permits all users write access, but only the creator has read and create access. */
	public static let PublicWrite : ACL = ACL(id: "$publicWrite")

	/** A static ACL that permits all users create access, but only the creator has read and write access. */
	public static let PublicCreate : ACL = ACL(id: "$publicCreate")

	/** A static ACL that permits all users read and write access, but only the creator has create access. */
	public static let PublicReadWrite : ACL = ACL(id: "$publicReadWrite")

	/** A static ACL that permits all users read and create access, but only the creator has write access. */
	public static let PublicReadCreate : ACL = ACL(id: "$publicReadCreate")

	/** A static ACL that permits all users write and create access, but only the creator has read access. */
	public static let PublicWriteCreate : ACL = ACL(id: "$publicWriteCreate")

	/** A static ACL that permits all users read, write and create access. */
	public static let PublicReadWriteCreate : ACL = ACL(id: "$publicReadWriteCreate")

	// MARK: - ACL properties

	/**
	The name of the ACL (read-only).
	*/
	public private(set) var id : String!

	// MARK: - ACL methods

	/*
	Initializes an ACL object with the specified Acl name.

	**Parameters**

	- id: The string identifier for the Acl.

	**Return Value**

	A ACL object initialized with the specified id.
	*/
	internal init(id: String) {
		self.id = id
	}

}
