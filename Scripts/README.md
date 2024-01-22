# AppleScriptObjC Scripts

A few simple ASObjC scripts demonstrating the usage of various Cocoa classes.  These should be saved and run as stay-open applications, since GUI elements need to be run on the main thread, although many* can be run from the **Script Editor** or **Script Debugger** (and adjusted for **Xcode**, of course).  Care should be taken when running from an editor though, as programmatically created objects such as windows and menu items can be added to the current editor instance, in which case they will be kept until they are explicitly removed or the editor is quit.


* *OpenPanel - a NSOpenPanel with an accessory view.
	* NSApplication, NSOpenPanel, NSMenu, NSBox, NSButton, NSDictionary
* *Sheets - shows an alert sheet (with a help sheet) over the main window.  ASObjC does not support blocks, so you are limited to the (somewhat buggy) deprecated method.  There are some third-party Objective-C categories supporting completionHandler blocks available for use in an Xcode project.
	* NSWindow, NSAlert, NSButton
* *TimerDisplay - displays a general-purpose timer in a floating window and / or a status bar menu item.
	* NSWindow, NSStatusBar, NSMenu, NSTimer, NSTextField, NSMutableAttributedString, NSDictionary, NSFont, NSColor.
* *MenuBar Timer - a bigger, enhanced version of TimerDisplay that provides a menu bar status item countdown timer with adjustable countdown and alarm times.  When the countdown expires or the alarm time is met, an alarm action can be set to play a sound or run a script.
    * NSStatusBar, NSMenu, NSMenuItem, NSViewController, NSTimer, NSUserDefaults, NSFileManager, NSEvent, NSMutableArray, NSMutableDictionary, NSMutableAttributedString, NSSound, NSColor, NSPopover, NSDatePicker, NSButton, NSTextField, NSSlider, NSPopupButton, NSComboButton.
* *AlertLib - a NSAlert library.  Performs a NSAlert with optional TextField, ComboBox, CheckBox, or RadioButton accessory views.  Can be used as a script library.
	* NSAlert, NSTextField, NSSecureTextField, NSComboBox, NSButton, NSTimer, NSBox, NSMutableDictionary, NSImage.
* *Choose from List Alert - A NSAlert with a tableView accessory view to approximate AppleScript's "choose from list".
   * NSAlert, NSTableView, NSScrollView, NSMutableArray, NSMutableDIctionary, NSMutableAttributedString, NSMutableParagraphStyle
* *Popover - shows a popover at a button when it is clicked.
	* NSWindow, NSButton, NSTextField, NSView,NSViewController, NSPopover, NSFont, NSColor

## Cocoa-AppleScript

These are also examples using AppleScriptObjC, but use other Cocoa classes that can be run directly from the **Script Editor** or **Script Debugger** without any main thread issues.  


* OverlayImage - overlay one image over another.  The example puts an image or application icon onto a copy of the system's generic folder icon.
	* NSData, NSImage, NSBitmapImageRep
* tags - a set of handlers in an example that adds or removes file tags.
	* NSOrderedSet, NSURL, NSDictionary
* FinderTags - gets all of the Finder's tags and their label colors.  Works with old and new plist locations (uses the `sqlite3` shell utility to read the database in current OS versions).
    * NSDictionary, NSData, NSPropertyListSerialization
* JSON - conversion of a list/record to/from a JSON string.
    * NSData, NSJSONSerialization, NSError
* whereFroms - a set of handlers in an example that adds or removes the file whereFrom attribute.
	* NSOrderedSet, NSString, NSPropertyListSerialization

