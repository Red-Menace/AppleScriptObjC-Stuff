
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


# UI item outlets
property mainWindow : missing value -- this will be the NSWindow object

# script properties
property failed : missing value -- this will be a record of the message and number of any error


on run -- example can be run as app and from Script Editor
	try
		if current application's NSThread's isMainThread() as boolean then
			doStuff()
		else -- UI stuff needs to be done on the main thread
			my performSelectorOnMainThread:"doStuff" withObject:(missing value) waitUntilDone:true
		end if
		if failed is not missing value then error failed's errmsg number failed's errnum
		log "done"
	on error errmsg number errnum
		display alert "Error " & errnum message errmsg
	end try
end run


on doStuff() -- do the window stuff
	try
		set my mainWindow to makeWindow at {} given title:"Testing" -- make it
		
		-- add other elements as desired
		
		mainWindow's makeKeyAndOrderFront:me -- show it
	on error errmsg number errnum
		set my failed to {errmsg:errmsg, errnum:errnum}
	end try
end doStuff


# Make and return an NSWindow or NSPanel.
# Default styleMask includes title, close, and minimize buttons, and is not resizeable.
# If no origin is given the window will be centered.
to makeWindow at (origin as list) given contentSize:contentSize as list : {400, 200}, styleMask:styleMask as integer : 15, title:title as text : "", isPanel:isPanel as boolean : false, floats:floats as boolean : false, hasShadow:hasShadow as boolean : true, minimumSize:minimumSize as list : {}, maximumSize:maximumSize as list : {}, backgroundColor:backgroundColor : missing value
	tell current application to set theClass to item ((isPanel as integer) + 1) of {its NSWindow, its NSPanel}
	tell (theClass's alloc()'s initWithContentRect:{{0, 0}, contentSize} styleMask:styleMask backing:2 defer:true)
		if origin is {} then
			tell it to |center|()
		else
			its setFrameOrigin:origin
		end if
		if title is not "" then its setTitle:title
		if isPanel and floats then its setFloatingPanel:true
		its setHasShadow:hasShadow
		if minimumSize is not {} then its setContentMinSize:minimumSize
		if maximumSize is not {} then its setContentMaxSize:maximumSize
		if backgroundColor is not missing value then its setBackgroundColor:backgroundColor
		its setAutorecalculatesKeyViewLoop:true -- include added items in the key loop
		return it
	end tell
end makeWindow


# Make and return a windowController.
on makeWindowController(theWindow)
	return current application's NSWindowController's alloc()'s initWithWindow:theWindow
end makeWindowController


#
# NSWindow style masks (for combinations, add mask values together):
# NSWindowStyleMaskBorderless = 0
# NSWindowStyleMaskTitled = 1
# NSWindowStyleMaskClosable = 2
# NSWindowStyleMaskMiniaturizable = 4
# NSWindowStyleMaskResizable = 8
# NSWindowStyleMaskUtilityWindow = 16
# NSWindowStyleMaskHUDWindow = 8192
#

