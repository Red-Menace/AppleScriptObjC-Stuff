# AppleScriptObjC Stuff

A few ASObjC scripts demonstrating the usage of various Cocoa classes.  These should be saved and run as stay-open applications, although many* can be run directly from the **Script Editor** or **Script Debugger** (and adjusted for **Xcode**, of course).  Care should be taken when running from an editor though, as programmatically created objects such as windows and menu items can be added to the current editor instance, in which case they will be kept until they are explicitly removed or the editor is quit.


* *OpenPanel - an NSOpenPanel with an accessory view.
	* NSApplication, NSOpenPanel, NSMenu, NSBox, NSButton, NSDictionary
* *Sheets - shows an alert sheet (with a help sheet) over the main window.  ASObjC does not support blocks, so you are limited to the (somewhat buggy) deprecated method.  There are some third-party Objective-C categories supporting completionHandler blocks available for use in an Xcode project.
	* NSWindow, NSAlert, NSButton
* *Overlay - overlay one image over another.
	* NSData, NSImage, NSBitmapImageRep
* *StatusBarTimer - a status bar menu item with a timer display.
	* NSStatusBar, NSMenu, NSWorkspace notifications, NSTimer, NSMutableAttributedString, NSDictionary, NSFont, NSColor.
* *AlertLib - an NSAlert library.  Performs an NSAlert with optional TextField, ComboBox, CheckBox, or RadioButton accessory views.  Can be used as a script library.
	* NSAlert, NSTextField, NSSecureTextField, NSComboBox, NSButton, NSTimer, NSBox, NSMutableDictionary, NSImage.
* *Popover - shows a popover at a button when it is clicked.
	* NSWindow, NSButton, NSTextField, NSView,NSViewController, NSPopover, NSFont, NSColor

