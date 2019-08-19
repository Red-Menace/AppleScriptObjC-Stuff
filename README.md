# AppleScriptObjC Stuff

A few ASObjC scripts demonstrating the usage of various Cocoa classes.  These should all be saved and run as stay-open applications, although some* can be run directly from the **Script Editor** or **Script Debugger** (and adjusted for **Xcode**, of course).  Care should be taken when running from an editor though, as programmatically created objects such as windows and menu items can be added to the current editor instance, in which case they will be kept until they are explicitly removed or the editor is quit.


- *OpenPanel - an NSOpenPanel with an accessory view.
	* NSApplication, NSOpenPanel, NSMenu, NSBox, NSButton, NSDictionary
- *Overlay - overlay one image over another.
	* NSData, NSImage, NSBitmapImageRep
- StatusBarTimer - a status bar menu item with a timer display.
	* NSStatusBar, NSMenu, NSWorkspace notifications, NSTimer, NSMutableAttributedString, NSDictionary, NSFont, NSColor.

