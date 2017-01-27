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

#import <XCTest/XCTest.h>
@import CSyncSDK;

@interface ObjCTests : XCTestCase

@end

@implementation ObjCTests

- (void)setUp {
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

- (void)testObjCReadme
{
	// Connecting to a CSync store

	CSApp *csync = [[CSApp alloc] initWithHost:@"csync-staging.mybluemix.net" port:80];

	NSString *userjwt = @"user@pickles.com";
	[csync authenticateWithOAuthProvider:@"pickles" token:userjwt completionHandler:^(CSAuthData *authData, NSError *error) {
		if (error != nil) {
			// Authentication failed ...
		} else {
			// authData has details of current user
		}
	}];

	// Listening for values on a key

	CSKey *myKey = [csync keyWithString:@"a.b.c.d"];

	[myKey listen:^(CSValue *value, NSError *error) {
		if (error != nil) {
			// handle error
		} else {
			// value contains new value
		}
	}];

	// Writing a value into the CSync store

	[myKey write:@"value" with:CSAcl.Private completionHandler:^(CSKey * key, NSError * error) {
		if (error != nil) {
			// handle error
		} else {
			// Data has been written to the CSync service
		}
	}];

	// Unlistening

	[myKey unlisten];

}

- (void)testCSAppAPIs
{
	NSLog(@"CSErrorDomain = %@", CSErrorDomain);

	// Connecting to a CSync store

	CSApp *csync = [[CSApp alloc] initWithHost:@"csync-staging.mybluemix.net" port:80];

	[csync close];

	NSString *version = CSApp.sdkVersion;
	NSString *host = csync.host;
	NSInteger port = csync.port;
	NSLog(@"Version: %@, Host: %@, Port: %ld", version, host, (long)port);

	if (csync.connected) {
		NSLog(@"connected");
	}

	CSAuthData *authData = csync.authData;
	NSLog(@"%@ %@ %@ %ld", authData.uid, authData.provider, authData.token, (long)authData.expires);

	NSString *userjwt = @"user@pickles.com";
	[csync authenticateWithOAuthProvider:@"pickles" token:userjwt completionHandler:nil];

	[csync authenticateWithOAuthProvider:@"pickles" token:userjwt completionHandler:^(CSAuthData *authData, NSError *error) {
		NSLog(@"Hello");
	}];

	CSKey *key1 = [csync keyWithString:@"a.b.c.d"];
	//XCTAssertEqual(key1.components,@[@"a", @"b", @"c", @"d"]);
	{
		NSArray *expected = @[@"a", @"b", @"c", @"d"];
		XCTAssertEqualObjects(key1.components, expected);
	}
	CSKey *key2 = [csync keyWithComponents:@[@"x", @"y", @"z"]];
	XCTAssertEqualObjects(key2.key, @"x.y.z");

}

- (void)testCSKeyAPIs
{
	CSApp *csync = [[CSApp alloc] initWithHost:@"csync-staging.mybluemix.net" port:80];

	//XCTAssertThrows([[CSKey alloc] init]);

	CSKey *key1 = [csync keyWithString:@"a.b.c.d"];

	XCTAssertEqualObjects(key1.app, csync);

	NSLog(@"Created CSKey with key %@", key1.key);

	{
		NSArray *expected = @[@"a", @"b", @"c", @"d"];
		XCTAssertEqualObjects(key1.components, expected);
		XCTAssertEqualObjects(key1.lastComponent, @"d");
	}

	CSKey *key2 = [csync keyWithString:@"a.$.c.d"];

	if (key2.error) {
		NSLog(@"Key error is %@", key1.error);
	}

	CSKey *key3 = [csync keyWithString:@"a.*.c.#"];

	if (key3.isKeyPattern) {
		NSLog(@"Key %@ is a pattern", key3.key);
	}

	CSKey *key4 = [key1 parent];
	XCTAssertEqualObjects(key4.key, @"a.b.c");

	CSKey *key5 = [key4 child:@"foo"];
	XCTAssertEqualObjects(key5.key, @"a.b.c.foo");

	CSKey *key6 = [key4 child];
	XCTAssertEqualObjects(key6.parent.key, key4.key);

	[key3 listen:^(CSValue *value, NSError *error) {
		NSLog(@"This is the listener");
	}];

	[key3 unlisten];

	[key1 write:@"the data" completionHandler:^(CSKey * key, NSError * error) {
		NSLog(@"This is the write completion handler");
	}];

	[key1 write:@"the data"];

	[key1 write:@"the data" with:CSAcl.PublicRead completionHandler:^(CSKey * key, NSError * error) {
		NSLog(@"This is the write completion handler");
	}];

	[key1 write:@"the data" with:CSAcl.PublicRead];

	[key1 delete:^(CSKey *key, NSError *error) {
		NSLog(@"This is the delete completion handler");
	}];

	[key1 delete:nil];

	[key1 delete];
}

@end
