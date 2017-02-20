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

// MARK: - AuthData

/**
A AuthData object contains the authentication context for a user that has been
authenticated to the CSync service.
*/
@objc(CSAuthData)
public class AuthData : NSObject
{
	/** The uid for this user. It is unique across all auth providers. */
	public let uid : String
	/** The OAuth indentity provider that provided the token that identifies the user */
	public let provider : String
	/** The token used to authenticate the user with the CSync Service */
	public let token : String
	/** The expiration timestamp (seconds since epoch) for the OAuth token */
	public let expires : Int

	internal init(uid: String, provider: String, token: String, expires: Int)
	{
		self.uid = uid
		self.provider = provider
		self.token = token
		self.expires = expires
	}
}
