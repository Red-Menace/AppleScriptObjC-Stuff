# AppleScriptObjC Scripts

A few ASObjC scripts demonstrating the usage of various Cocoa classes.  These should be saved and run as stay-open applications, since GUI elements need to be run on the main thread, although many* can be run from the **Script Editor** or **Script Debugger** (and adjusted for **Xcode**, of course).  Care should be taken when running from an editor though, as programmatically created objects such as windows and menu items can be added to the current editor instance, in which case they will be kept until they are explicitly removed or the editor is quit.


* *OpenPanel - a NSOpenPanel with an accessory view.
	* NSApplication, NSOpenPanel, NSMenu, NSBox, NSButton, NSDictionary
* *Sheets - shows an alert sheet (with a help sheet) over the main window.  ASObjC does not support blocks, so you are limited to the (somewhat buggy) deprecated method.  There are some third-party Objective-C categories supporting completionHandler blocks available for use in an Xcode project.
	* NSWindow, NSAlert, NSButton
* *TimerDisplay - displays a general-purpose timer in a floating window and / or a status bar menu item.
	* NSWindow, NSStatusBar, NSMenu, NSTimer, NSTextField, NSMutableAttributedString, NSDictionary, NSFont, NSColor.
* *MenuBar Timer - a (much) bigger, enhanced version of TimerDisplay that provides a menu bar status item countdown timer with adjustable countdown and alarm times.  When the countdown expires or the alarm time is met, an alarm action can be set to play a sound or run a script.
    * NSStatusBar, NSMenu, NSMenuItem, NSViewController, NSTimer, NSUserDefaults, NSFileManager, NSEvent, NSMutableArray, NSMutableDictionary, NSMutableAttributedString, NSSound, NSColor, NSPopover, NSDatePicker, NSButton, NSTextField, NSSlider, NSPopupButton, NSComboButton.
* *Choose from List Alert - a NSAlert with a tableView accessory view to approximate AppleScript's "choose from list".
   * NSAlert, NSTableView, NSScrollView, NSMutableArray, NSMutableDIctionary, NSMutableAttributedString, NSMutableParagraphStyle
* *Popover - shows a popover at a button location when it is clicked.
	* NSWindow, NSButton, NSTextField, NSView,NSViewController, NSPopover, NSFont, NSColor
* *Contextual Menu - shows a NSMenu at a location on the screen or relative to a window or panel.
   * NSMenu, NSMenuItem, NSWindow

## Cocoa-AppleScript

These are also examples using AppleScriptObjC, but use other Cocoa classes that can be run directly from the **Script Editor** or **Script Debugger** without any main thread issues.  


* OverlayImage - overlay one image over another.  The example puts an image or application icon onto a copy of the system's generic folder icon.
	* NSData, NSImage, NSBitmapImageRep
* FinderTags - gets all of the Finder's tags and their label colors.  Works with macOS 10.9 Mavericks thru macOS 11 Big Sur and macOS 12 Monterey plist locations (uses the `sqlite3` shell utility to read the database in those OS versions).
    * NSDictionary, NSData, NSPropertyListSerialization
* JSON - conversions to/from a JSON string and a list/record.
    * NSData, NSJSONSerialization, NSError
* Extended Attributes - an example that uses the `xattr` shell utility to add or remove items from `com.apple.metadata:kMDItemWhereFroms`, `com.apple.metadata:_kMDItemUserTags`, `com.apple.metadata:kMDItemFinderComment"`, or `com.apple.metadata:kMDItemComment` file attributes.
	* NSOrderedSet, NSString, NSPropertyListSerialization

