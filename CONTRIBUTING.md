## Coding guidelines

Contributions to the CSync iOS SDK should follow the [project coding guidelines][styleguide].
The project is set up so that developers can use [SwiftLint][swiftlint] to check conformance
to these guidelines.

[styleguide]: https://github.com/IBM-MIL/swift-style-guide
[swiftlint]: https://github.com/realm/SwiftLint

## Documentation

All code changes should include comments describing the design, assumptions, dependencies, and non-obvious aspects of the implementation.
Hopefully the existing code provides a good example of appropriate code comments.
If necessary, make the appropriate updates in the README.md and other documentation files.

We use [jazzy][jazzy] to build documentation from comments in the source code.
All external interfaces should be fully documented.

[jazzy]:https://github.com/realm/jazzy

Use `makedocs.sh` to build the docs.

## Contributing your changes

1. If one does not exist already, open an issue that your contribution is going to resolve or fix.
    1. Make sure to give the issue a clear title and a very focused description.
2. On the issue page, set the appropriate Pipeline, Label(s), Milestone, and assign the issue to
yourself.
    1. We use Zenhub to organize our issues and plan our releases. Giving as much information as to
    what your changes are help us organize PRs and streamline the committing process.
3. Make a branch from the develop branch using the following naming convention:
    1. `YOUR_INITIALS/ISSUE#-DESCRIPTIVE-NAME`
    2. For example, `kb/94-create-contributingmd` was the branch that had the commit containing this
    tutorial.
4. Commit your changes!
5. When you have completed making all your changes, create a Pull Request (PR) from your git manager
or our Github repo.
6. In the comment for the PR write `Resolves #___` and fill the blank with the issue number you
created earlier.
    1. For example, the comment we wrote for the PR with this tutorial was `Resolves #94`
7. That's it, thanks for the contribution!

## Setting up your environment

You have probably got most of these set up already, but starting from scratch
you'll need:

* Xcode
* Xcode command line tools
* Carthage
* Homebrew (optional, but useful)
* SwiftLint (optional)
* xcpretty (optional)

First, download Xcode from the app store or [ADC][adc].

When this is installed, install the command line tools. The simplest way is:

```bash
xcode-select --install
```

Install Carthage using the [guide on their site][carthage].

Install Homebrew using the [guide on the Homebrew site][homebrew].

Install SwiftLint using Homebrew

```
brew update
brew install SwiftLint
```

Finally, if you want to build from the command line, install [xcpretty][xcpretty],
which makes the `xcodebuild` output more readable.

It's a gem:

```bash
sudo gem install xcpretty
```

For documentation, install [jazzy][jazzy].

[adc]: http://developer.apple.com/
[carthage]:https://github.com/Carthage/Carthage
[homebrew]: http://brew.sh
[xcpretty]: https://github.com/mneorr/XCPretty

## Running the tests

Set the Server and Port to use for testing in CSyncSDKTests/Config.plist.

From Xcode, select the simulated or real device on which to run the tests,
and then use `CMD-u` to run the tests on the specified device. The tests
automatically generate a coverage report, which you can view in the report navigator.

You can also run the tests from the command line with [xcodebuild][xcodebuild].
Specify the simulated or real device to run the tests using `-destination`.

```
xcodebuild -project CSyncSDK.xcodeproj -scheme CSyncSDK -destination 'platform=iOS Simulator,OS=latest,name=iPhone 6' test | xcpretty -c
```

Skip `| xcpretty` if you did not install that.

[xcodebuild]:https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcodebuild.1.html

### Dependency Table

| Name | URL |License Type | Version | Need/Reason | Release Date | Verification Code |
|------|-----|-------------|---------|-------------|--------------|-------------------|
| Carthage | https://github.com/Carthage/Carthage | MIT | 0.15  | package tool | 02/25/2016 |  |
| Jazzy	   | https://github.com/realm/jazzy | MIT | 0.6.0 | generation docs | 04/05/2016 | |
| SQLite.swift | https://github.com/stephencelis/SQLite.swift | MIT | 0.11.0  | sqlite3 access | 03/27/2016 |  |
| SwiftLint | https://github.com/realm/SwiftLint | MIT | 0.9.2  | static analysis | 03/14/2016 |  |
| SwiftWebSocket | https://github.com/tidwall/SwiftWebSocket | MIT | 2.6  | web sockets | 03/22/2016 |  |

