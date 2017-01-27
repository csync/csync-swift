# Documentation Style

These style guidelines are intended to ensure the SDK documentation is consistent in form and style across all SDK interfaces.
These guidelines intentionally mimic the style of Apple's API documentation.

The documentation for the CSync iOS SDK is generated using [jazzy][].
A good introduction to jazzy markup and operation is available at the
NSHipster article [Swift Documentation][swiftdoc].

[jazzy]: https://github.com/Realm/jazzy
[swiftdoc]: http://nshipster.com/swift-documentation/


## Class Overview

Every class should have a class overview that contains one or more paragraphs that describe the basic purpose and function of the class.

A common subsection in the class overview is "Subclassing Notes".  Include this subsection to describe any special considerations when subclassing the class.  Such special considerations may include:

- Methods to Override (e.g. UIView)
- Methods You Must Not Override (e.g. NSManagedObject)
- Methods you Are Discouraged From Overriding (e.g. NSManagedObject)
- Custom Accessor Methods (e.g. NSManagedObject)
- Alternatives to Subclassing

## Tasks

Task titles should be gerunds (verb with -ing ending).  E.g., Creating, Configuring, Managing.

## Properties

- The description (first line) of a property should be a noun phrase that describes the property.

	Examples:
	- The bounds rectangle, which describes the view’s location and size in its own coordinate system. (bounds property of UIView)
	- The object that acts as the delegate of the receiving table view. (delegate property of UITableView)

- The description for a read/write Boolean property should start with "A Boolean value that determines whether".

	Example:
	- A Boolean value that determines whether the view is hidden. (hidden property of UIView)
	- A Boolean value that determines whether the receiver is in editing mode. (editing property in UITableView)

- The description for a read-only Boolean property should start with "A Boolean value that indicates whether".

	Example:
	- A Boolean value that indicates whether the receiver is the key window for the application. (read-only) (keyWindow property of UIWindow)

- Read only methods should include "(read-only)" at the end of their description.

- Include a section titled "Availability" in the description body that indicates when this property was introduced.

## Class Methods

- The description (first line) of a class method should be a verb phrase that describes the action performed by the method.
(Do NOT include "This method" at the beginning of the description.)

	Example:
	- Resizes and moves the receiver view so it just encloses its subviews. (sizeToFit method of UIView)

## Instance Methods

- The description (first line) of an instance method should be a verb phrase that describes the action performed by the method.
(Do NOT include "This method" at the beginning of the description.)
For methods with a return value, the description should start with "Returns".

	Example (void return):
	- Resizes and moves the receiver view so it just encloses its subviews. (sizeToFit method of UIView)

	Example (non-void return):
	- Returns the natural size for the receiving view, considering only properties of the view itself. (intrinsicSize method of UIView)
	- Returns the footer view associated with the specified section. (footerViewForSection method of UIView)

### Delegate protocols

Instance methods for delegates have a special documentation style.

- The description (first line) of a delegate protocol method should begin with either "Tells the delegate that" (for void methods) or "Asks the delegate for" (for methods with return values).

	Example (void return):
	- Tells the delegate that the specified row is now selected. (tableView:didSelectRowAtIndexPath: in UITableViewDelegate Protocol)

	Example (non-void return):
	- Asks the delegate for the height to use for the header of a particular section. (tableView:heightForHeaderInSection: in UITableViewDelegate Protocol)

## Constants

TODO: Investigate whether/how jazzy handles doc for constants.

## Notifications

Some Apple classes document notifications sent by the class (e.g. UITableView documents the UITableViewSelectionDidChangeNotification).

TODO: Investigate whether/how jazzy handles doc for notification ids.


