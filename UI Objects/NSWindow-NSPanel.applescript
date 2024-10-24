
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


# UI item outlets
property mainWindow : missing value -- this will be the NSWindow object

# script properties
property failure : missing value -- error record with keys {errorMessage, errorNumber, handlerName}


on run -- example can be run as app and from Script Editor
	try
		if current application's NSThread's isMainThread() as boolean then
			doStuff()
		else -- UI stuff needs to be done on the main thread
			my performSelectorOnMainThread:"doStuff" withObject:(missing value) waitUntilDone:true
		end if
		if failure is not missing value then error failure's errorMessage number failure's errorNumber
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
		set my failure to {errorMessage:errmsg, errorNumber:errnum}
	end try
end doStuff


# Make and return a NSWindow or NSPanel.
# Default styleMask includes a title, close and minimize buttons, and is not resizeable.
# If no origin is given the window will be centered.
to makeWindow at (origin as list) given contentSize:contentSize as list : {400, 200}, styleMask:styleMask as integer : 15, title:title as text : "", panel:panel as boolean : false, floats:floats as boolean : false, aShadow:aShadow as boolean : true, minimumSize:minimumSize as list : {}, maximumSize:maximumSize as list : {}, backgroundColor:backgroundColor : missing value
	tell current application to set theClass to item ((panel as integer) + 1) of {its NSWindow, its NSPanel}
	tell (theClass's alloc()'s initWithContentRect:{{0, 0}, contentSize} styleMask:styleMask backing:2 defer:true)
		if origin is {} then
			tell it to |center|()
		else
			its setFrameOrigin:origin
		end if
		if title is not "" then its setTitle:title
		if panel and floats then its setFloatingPanel:true
		its setHasShadow:aShadow
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

