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
#if DEBUG
@testable import CSyncSDK
#else
import CSyncSDK
#endif

class KeyTests: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testValidKeys() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		// simple key
		do {

			let k1 = app.key(["foo", "bar", "baz"])
			XCTAssertEqual(k1.key, "foo.bar.baz")
			XCTAssertEqual(k1.lastComponent, "baz")
			XCTAssertEqual(k1.app, app)
			XCTAssertFalse(k1.isKeyPattern)

			// root key
			let k2 = app.key([])
			XCTAssertEqual(k2.key, "")
			XCTAssertEqual(k2.lastComponent, nil)
			XCTAssertEqual(k2.app, app)
			XCTAssertFalse(k2.isKeyPattern)

			// Key with max (16) components
			let k3 = app.key(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"])
			XCTAssertEqual(k3.key, "a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p")
			XCTAssertEqual(k3.lastComponent, "p")
			XCTAssertEqual(k3.app, app)
			XCTAssertFalse(k3.isKeyPattern)

			// Key with max (200) size
			_ = app.key(["ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxy",	// 50 chars
				"ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxy",			// 50 chars
				"ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxy",			// 50 chars
				"ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuv"])			// 47 chars
		}

		// Use keyString intializer

		do {
			let k1 = app.key("foo.bar.baz")
			XCTAssertEqual(k1.components, ["foo", "bar", "baz"])
			XCTAssertEqual(k1.app, app)
			XCTAssertFalse(k1.isKeyPattern)

			// root key
			let k2 = app.key("")
			XCTAssertEqual(k2.components, [])
			XCTAssertEqual(k2.app, app)
			XCTAssertFalse(k2.isKeyPattern)

			// Key with max (16) components
			let k3 = app.key("a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p")
			XCTAssertEqual(k3.components, ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"])
			XCTAssertEqual(k3.app, app)
			XCTAssertFalse(k3.isKeyPattern)
		}
	}

	func testWildcards() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		do {
			// asterisk
			let k1 = app.key(["foo", "*", "baz"])
			XCTAssertEqual(k1.key, "foo.*.baz")
			XCTAssertTrue(k1.isKeyPattern)

			// pound
			let k2 = app.key(["foo", "bar", "#"])
			XCTAssertEqual(k2.key, "foo.bar.#")
			XCTAssertEqual(k2.lastComponent, "#")
			XCTAssertTrue(k2.isKeyPattern)

			// multiple asterisk
			let k3 = app.key(["foo", "*", "*"])
			XCTAssertEqual(k3.key, "foo.*.*")
			XCTAssertEqual(k3.lastComponent, "*")
			XCTAssertTrue(k3.isKeyPattern)

			// max asterisk
			let k4 = app.key(["*", "*", "*", "*", "*", "*", "*", "*", "*", "*", "*", "*", "*", "*", "*", "*"])
			XCTAssertEqual(k4.key, "*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*")
			XCTAssertTrue(k4.isKeyPattern)

			// max components with #
			let k5 = app.key(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "#"])
			XCTAssertEqual(k5.key, "a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.#")
			XCTAssertTrue(k5.isKeyPattern)

			// max compoents with * and #
			let k6 = app.key(["a", "b", "c", "*", "e", "f", "g", "*", "i", "j", "k", "*", "m", "n", "o", "#"])
			XCTAssertEqual(k6.key, "a.b.c.*.e.f.g.*.i.j.k.*.m.n.o.#")
			XCTAssertTrue(k6.isKeyPattern)
		}

		// Use keyString intializer

		do {
			// asterisk
			let k1 = app.key("foo.*.baz")
			XCTAssertEqual(k1.key, "foo.*.baz")
			XCTAssertTrue(k1.isKeyPattern)

			// pound
			let k2 = app.key("foo.bar.#")
			XCTAssertEqual(k2.key, "foo.bar.#")
			XCTAssertTrue(k2.isKeyPattern)

			// multiple asterisk
			let k3 = app.key("foo.*.*")
			XCTAssertEqual(k3.key, "foo.*.*")
			XCTAssertTrue(k3.isKeyPattern)

			// max asterisk
			let k4 = app.key("*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*")
			XCTAssertEqual(k4.key, "*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*")
			XCTAssertTrue(k4.isKeyPattern)

			// max components with #
			let k5 = app.key("a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.#")
			XCTAssertEqual(k5.key, "a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.#")
			XCTAssertTrue(k5.isKeyPattern)

			// max compoents with * and #
			let k6 = app.key("a.b.c.*.e.f.g.*.i.j.k.*.m.n.o.#")
			XCTAssertEqual(k6.key, "a.b.c.*.e.f.g.*.i.j.k.*.m.n.o.#")
			XCTAssertTrue(k6.isKeyPattern)
		}
	}

	func testErrorKeys() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		// too many components
		let k1 = app.key(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q"])
		XCTAssertNotNil(k1.error)

		// empty string component
		let k2 = app.key(["a", "", "c"])
		XCTAssertNotNil(k2.error)

		let k2a = app.key("a..c")
		XCTAssertNotNil(k2a.error)

		// pound not final component
		let k3 = app.key(["a", "#", "c"])
		XCTAssertNotNil(k3.error)

		// wildcard does not appear alone
		let k4 = app.key(["a", "b*", "c"])
		XCTAssertNotNil(k4.error)

		// key exceeds maximum size (200 chars)
		let k5 = app.key(["ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxy",	// 50 chars
			"ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxy",					// 50 chars
			"ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxy",					// 50 chars
			"ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvw"])					// 48 chars
		XCTAssertNotNil(k5.error)

		// component contains illegal character (.)
		let k6 = app.key(["a", "b.c", "d"])
		XCTAssertNotNil(k6.error)

		// component contains illegal character (:)
		let k7 = app.key(["abcdefghijklm:nopqrstuvwxyz"])
		XCTAssertNotNil(k7.error)

		// component contains all illegal characters
		let k7a = app.key(["[]()&%$"])
		XCTAssertNotNil(k7a.error)

		// too many components
		let k8 = app.key("a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p")
		let k9 = k8.child("q")
		XCTAssertNotNil(k9.error)

		// key with only separator
		let k10 = app.key(".")
		XCTAssertNotNil(k10.error)

		// key starts or ends with a separator
		let k11 = app.key(".abc")
		XCTAssertNotNil(k11.error)
		let k12 = app.key("abc.")
		XCTAssertNotNil(k12.error)

	}

	func testParent() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		let k16 = app.key(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"])

		let k15 = k16.parent
		XCTAssertEqual(k15.key, "a.b.c.d.e.f.g.h.i.j.k.l.m.n.o")

		let k14 = k15.parent
		XCTAssertEqual(k14.key, "a.b.c.d.e.f.g.h.i.j.k.l.m.n")

		let k13 = k14.parent
		XCTAssertEqual(k13.key, "a.b.c.d.e.f.g.h.i.j.k.l.m")

		let k2 = k13.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent
		XCTAssertEqual(k2.key, "a.b")

		let k1 = k2.parent
		XCTAssertEqual(k1.key, "a")

		let k0 = k1.parent
		XCTAssertEqual(k0.key, "")

		let k = k0.parent
		XCTAssertEqual(k.key, "")
	}

	func testChild() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		let k0 = app.key([])

		let k1 = k0.child("a")
		XCTAssertEqual(k1.key, "a")

		let k2 = k1.child("b")
		XCTAssertEqual(k2.key, "a.b")

		let k3 = k1.child()
		XCTAssertEqual(k3.parent.key, k1.key)

		let k13 = k2.child("c").child("d").child("e").child("f").child("g").child("h").child("i").child("j").child("k").child("l").child("m")
		XCTAssertEqual(k13.key, "a.b.c.d.e.f.g.h.i.j.k.l.m")

		let k14 = k13.child("n")
		XCTAssertEqual(k14.key, "a.b.c.d.e.f.g.h.i.j.k.l.m.n")

		let k15 = k14.child("o")
		XCTAssertEqual(k15.key, "a.b.c.d.e.f.g.h.i.j.k.l.m.n.o")

		let k16 = k15.child("p")
		XCTAssertEqual(k16.key, "a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p")
	}

	func testCornerCases() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		// Test for key immutability

		var a = "a", b = "b"

		let k1 = app.key([a, b])
		XCTAssertEqual(k1.key, "a.b")

		a = "c"
		b = "d"
		XCTAssertEqual(k1.key, "a.b")
	}

#if DEBUG
	func testMatches() {
		// Connect to the CSync store
		let config = getConfig()
		let app = App(host: config.host, port: config.port, options: config.options)

		// Test concrete keys
		do {
			let k = app.key("foo.bar.baz")

			// Matches
			XCTAssertTrue(k.matches("foo.bar.baz"))

			// Non-matches
			XCTAssertFalse(k.matches("foo.bar"))
			XCTAssertFalse(k.matches("foo.bar.baz.qux"))
			XCTAssertFalse(k.matches("foo.#"))
			XCTAssertFalse(k.matches("foo.*.baz"))
			XCTAssertFalse(k.matches(""))
		}

		do {
			let k = app.key("")

			// Matches
			XCTAssertTrue(k.matches(""))

			// Non-matches
			XCTAssertFalse(k.matches("foo"))
			XCTAssertFalse(k.matches("foo.bar"))
		}

		// Test keys with "*"
		do {
			let k = app.key("foo.*.baz")

			// Matches
			XCTAssertTrue(k.matches("foo.bar.baz"))
			XCTAssertTrue(k.matches("foo.foo.baz"))
			XCTAssertTrue(k.matches("foo.foo-foo-foo-foo-foo-foo-foo-foo-foo.baz"))

			// Non-matches
			XCTAssertFalse(k.matches("foo.bar"))
			XCTAssertFalse(k.matches("foo.bar.baz.qux"))
			XCTAssertFalse(k.matches("foo.#"))
			//XCTAssertFalse(k.matches("foo.*.baz"))    // Invalid test since other is not valid concrete key
		}

		// Test keys with "#"
		do {
			let k = app.key("foo.bar.#")

			// Matches
			XCTAssertTrue(k.matches("foo.bar.baz"))
			XCTAssertTrue(k.matches("foo.bar"))
			XCTAssertTrue(k.matches("foo.bar.2.3.4.5.6.7.8.9.a.b.c.d.e.f"))

			// Non-matches
			XCTAssertFalse(k.matches("foo"))
			XCTAssertFalse(k.matches("foo.baz"))
			XCTAssertFalse(k.matches("foo.baz.bar"))
		}

		// Test keys with multiple "*"
		do {
			let k = app.key("foo.*.baz.*")

			// Matches
			XCTAssertTrue(k.matches("foo.bar.baz.qux"))
			XCTAssertTrue(k.matches("foo.a.baz.b"))

			// Non-matches
			XCTAssertFalse(k.matches("foo.bar"))
			XCTAssertFalse(k.matches("foo.bar.baz"))
			XCTAssertFalse(k.matches("foo.bar.bar.bar"))
			XCTAssertFalse(k.matches("foo.bar.baz.bar.baz"))
		}

		// Test keys with "*" and "#"
		do {
			let k = app.key("foo.*.baz.#")

			// Matches
			XCTAssertTrue(k.matches("foo.bar.baz.qux"))
			XCTAssertTrue(k.matches("foo.a.baz.b"))
			XCTAssertTrue(k.matches("foo.bar.baz"))
			XCTAssertTrue(k.matches("foo.bar.baz.3.4.5.6.7.8.9.a.b.c.d.e.f"))

			// Non-matches
			XCTAssertFalse(k.matches("foo.bar"))
			XCTAssertFalse(k.matches("foo.bar.bar.bar"))
		}

	}
#endif
}
