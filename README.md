# Contextual Sync

[![Build Status - Master](https://travis-ci.org/csync/csync-swift.svg?branch=master)](https://travis-ci.org/csync/csync-swift)
[![Carthage compatible][carthage-svg]][carthage-link]
[![License][license-svg]][license-link]

[carthage-svg]: https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat
[carthage-link]: https://github.com/carthage/carthage

[license-svg]: https://img.shields.io/hexpm/l/plug.svg
[license-link]: https://github.com/csync/csync-swift/blob/master/LICENSE

Contextual Sync (CSync) is an open source, real-time, continuous data synchronization service for building modern applications. The CSync data store is organized with key/values where keys have a hierarchical structure. Clients can obtain the current value for a key and any subsequent updates by listening on the key. Updates are delivered to all online clients in near-real time. Clients can also listen on a key pattern where some components contain wildcards. 

## Keys
CSync is structured as a tree of nodes referenced by period-delimited strings called keys.

To illustrate :

```
          companies
       /              \
    ibm                google
   /   \               /     \ 
stock   offices    stock   offices
```

The above tree consists of the following keys : `companies`, `companies.ibm`, `companies.google`, `companies.ibm.stock`, `companies.ibm.offices`, `companies.google.stock`, `companies.google.offices`. Any one of these keys can be listened to at a time and all changes to that singular node will be synced to the client device. 

### Key Limitations
Keys can have a maximum of 16 parts and a total length of 200 characters. Key components may contain only uppercase and lowercase alphabetic, numeric, "_", and "-".

Valid key: `this.is.a.valid.key.123456.7.8.9.10`

Invalid key: `this is an.invalidkey.🍕.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18`

### Wildcards in Keys
Suppose a developer wishes to listen to a subset of the tree containing multiple nodes, CSync provides this ability through wildcards. Currently CSync supports `*` and `#` as wildcards. 

#### Asterisk Wildcard
An Asterisk (`*`) wildcard will match any value in the part of the key where the wildcard is. As an example, if a developer listens to `companies.*.stock` in the above tree, the client will sync with all stock nodes for all companies.

#### Hash Wildcard
If a developer wishes to listen to all child nodes in a subset of the tree, the `#` can appended to the end of a key and the client will sync with all child nodes of the specified key. For instance in the above tree if a user listens to `companies.ibm.#`, then the client will sync with all child nodes of `companies.ibm` which include `companies.ibm.stock` and `companies.ibm.offices`. 

**Note:** Each listen is independent. For example, if a developer listens to both `companies.*.stock` and `companies.companyX.stock`, the data from `companies.companyX.stock` will be received by both of the listeners. 

## Guaranteed Relevance
Only the latest, most recent, values sync, so you’re never left with old data. CSync provides a consistent view of the values for keys in the CSync store. If no updates are made to a key for a long enough period of time, all subscribers to the key will see the same consistent value. CSync guarantees that the latest update will be reflected at all connected, subscribed clients, but not that all updates to a key will be delivered. Clients will not receive an older value than what they have already received for a given key.

## Local Storage
Work offline, read and write, and have data automatically sync the next time you’re connected. CSync maintains a local cache of data that is available to the client even when the client is offline or otherwise not connected to the CSync service. The client may perform listens, writes, and deletes on the local store while offline. When the client reestablishes connectivity to the CSync service, the local cache is efficiently synchronized with the latest data from the CSync store. The local cache is persistent across application restarts and device reboots.

## Authentication
Authenticate in an ever-growing number of ways from the provider of your choice. Currently the following methods are supported:
- [Google OAuth](https://developers.google.com/identity/protocols/OAuth2) `google`
- [Github Auth](https://developer.github.com/v3/oauth/) `github`
- [Facebook Auth](https://developers.facebook.com/docs/facebook-login/access-tokens) `facebook`
- Demo Login `demo`

### Demo Login
The Demo Login is an easy way of getting started with CSync. Just provide the `demo` authentication provider and the `demoToken` to authenticate as a demo user. This token allows for multiple user accounts as long as it is in the form `demoToken({someString})`. For example: `demoToken(abc)`, `demoToken` and `demoToken(123)` would all be treated as different user accounts.

## Access Control
Use simple access controls to clearly state who can read and write, keeping your data safe. Each key in the CSync store has an associated access control list (ACL) that specifies which users can access the key. 

Three specific forms of access are defined:
- Create: Users with create permission may create child keys of this key.
- Read: Users with read permission may read the data for the key.
- Write: Users with write permission may write the data for the key.

The creator of a key in the CSync store has special permissions to that key. In particular, the creator always has Read, Write, and Create permissions, and they also have permission to delete the key and change its ACL.

CSync provides eight "static" ACLs that can be used to provide any combination of Read, Write, and Create access to just the key's creator or all users.
- Private
- PublicRead
- PublicWrite
- PublicCreate
- PublicReadWrite
- PublicReadCreate
- PublicWriteCreate
- PublicReadWriteCreate

The ACL for a key is set when the key is created by the first write performed to the key. If the write operation specified an ACL, then this ACL is attached to the key. If no ACL was specified in the write, then the key inherits the ACL from its closest ancestor in the key space—its parent if the parent exists, else its grandparent if that key exists, possibly all the way back to the root key. The ACL of the root key is `PublicCreate`, which permits any user to create a child key but does not allow public read or write access.

# Getting Started
Use [Carthage] to include `CSync` into your iOS, macOS, or tvOS app.
Follow the current instructions in [Carthage's README][carthage-installation]
for up to date installation instructions.

[Carthage]: https://github.com/Carthage/Carthage
[carthage-installation]: https://github.com/Carthage/Carthage#adding-frameworks-to-an-application

Add the following to your Cartfile:

```
github "csync/csync-swift" ~> 1.3.0
```

Then run `carthage update`.

The `import CSyncSDK` directive is required in order to access CSync APIs.

#Usage

## Connecting to a CSync store
Applications use the CSync class to create a connection to a specific CSync service.

    let app = App(host: "localhost", port: 6005)

## Listening to values on a key

    let myKey = csync.key("a.b.c.d.e")
    myKey.listen() { value, error in
        if error != nil {
            // handle error
        }
        // value contains newly updated value for key
    }

## Writing a value into a CSync store

    myKey.write(data: "value")  { key, error in
        if error != nil {
            // handle error
        }
        // Server has accepted write of value to key
    }
    
Note: The ACL is inherited from its closest existing ancestor, up to the root key which has ACL `PublicCreate`.

## Writing a value to a CSync store with a given ACL

    myKey.write(data: "value", acl: ACL.PublicReadWrite)  { key, error in
        if error != nil {
            // handle error
        }
        // Server has accepted write of value to key and set the ACL
    }

## Unlistening

	myKey.unlisten()
	
## Deleting a key
    let testKey = app.key("a.b.c.d")

    //Listen on a key to be notified of the delete
    testKey.listen { (value, error) -> () in
        if value!.exists == false {
                // Success, the key was deleted and we were notified about it
                testKey.unlisten()
        }
    }
    testKey.delete() //Deletes the key
    
Note: A delete key can contain any number of wildcards as well. For example, the key a.b would be deleted by `a.*`, but the key `a.b.c` would not because the wildcard only covers the second part of the key. The key `a.b.c` could be deleted by `a.*.*`, `a.b.*`, `a.*.c`, `*.*.c` or `*.*.*`. The key `*.*.*` would delete all keys of length 3. Wildcard deletes make a best effort to delete everything you have access to. If you do not delete anything, you will still get a successful return because the server succesfully deleted all nodes you had access to, even if none existed.

# Troubleshooting
Running the command `carthage update --configuration Debug` will build the SDK in the Debug configuration rather then the default Release configuration. The Debug configuration logs more messages to assist with troubleshooting.

# License
This library is licensed under Apache 2.0. Full license text is
available in [LICENSE](LICENSE).

# Contribution Guide
Want to contribute? Take a look at our [CONTRIBUTING.md](https://github.com/csync/csync-swift/blob/master/.github/CONTRIBUTING.md)
