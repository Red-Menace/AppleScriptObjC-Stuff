
(* contextual menu example:
	To get a normal contextual menu in your own window, you can set its menu:
		yourWindow's contentView's setMenu:contextualMenu

	This sample shows a couple of ways to position an independent contextual menu:
		1.	Pop up the menu at a location on the main screen.
		2.	Use a window or panel to position the menu.  The menu can (optionally) be
			popped up at a location relative to the window's view.

	The menu will remain open until a selection is made, any action other than menu navigation closes it.
	
	Some of the UI handlers below use labeled parameters.  The 'given' parameters of these handlers are
		optional, and will use default values unless otherwise specified.
*)


use framework "Foundation"
use scripting additions

# UI item outlets
property mainWindow : missing value -- the window/panel used for positioning the menu
property customMenu : missing value

# script properties
property outcome : missing value -- selection result
property failure : missing value -- error record with keys {errorMessage, errorNumber, handlerName}
property testing : true -- provide feedback for the result being returned?


on run -- example
	set menuList to {"Lorem Ipsum", "Donec Laoreet", {"Single Submenu", "", "Suspendisse Tempus", "Mauris Iaculis"}, "Quisque Convallis", {"Multiple Submenus", "", "Vivamus Consectetur", "Aenean Pulvinar", {"Aliquam Dignissim", "Try Not To Do This", {"No, Really, Don't Do This!"}}, "Nullam Sollicitudin"}, "Curabitur Mollis"}
	set location to {100, 600}
	showMenu at {} for menuList
	# showMenu at location for menuList with aWindow
end run

to showMenu at (origin as list) for (menuItems as list) given aWindow:usingWindow as boolean : false, offsetOf:menuOffset as list : {0, 0}
	try
		set argumentList to {origin, menuItems, usingWindow, menuOffset} -- object to be passed to the main handler
		if current application's NSThread's isMainThread() as boolean then
			my doStuff:argumentList
		else -- UI stuff needs to be done on the main thread
			my performSelectorOnMainThread:"doStuff:" withObject:argumentList waitUntilDone:true
		end if
		if failure is not missing value then error
		if testing then
			set output to item (((outcome is missing value) as integer) + 1) of {outcome, "missing value"}
			activate me
			# display dialog output with title "Result" buttons {"OK"} giving up after 10
			say output
		end if
		return outcome
	on error errmess number errnum
		return errorIndication(errmess, errnum)
	end try
end showMenu

on errorIndication(errorMessage as text, errorNumber as integer)
	if failure is missing value then -- use passed arguments
		# display alert "NSMenu Script Error " & errorNumber message errorMessage
		say "NSMenu Script Error," & errorNumber & "," & first paragraph of errorMessage
	else -- use keys from the failure record
		# display alert "NSMenu Script Error " & failure's errorNumber message quoted form of failure's errorMessage & " from handler " & failure's handlerName
		say "NSMenu Script Error," & failure's errorNumber & "," & first paragraph of failure's errorMessage & " from handler " & failure's handlerName
	end if
	return missing value
end errorIndication

to doStuff:(menuStuff as list) -- Objective-C method definition: coercion to list also coerces items
	set {origin, menuItems, usingWindow, menuOffset} to menuStuff
	try
		set my customMenu to makeMenu for menuItems
		if usingWindow then -- example creates a small window/panel to position the menu
			set mainWindow to makeWindow at origin with panel and floats given contentSize:{28, 0}, styleMask:3
			mainWindow's makeKeyAndOrderFront:me
			mainWindow's performClose:(missing value) -- unless otherwise needed
			tell customMenu to popUpMenuPositioningItem:(its itemAtIndex:0) atLocation:menuOffset inView:(mainWindow's contentView)
		else -- pop up the menu at a location on the main screen
			if origin is {} then -- position menu at slightly above screen center, with optional offset
				tell first item of ((current application's NSScreen's screens) as list) to set {screenX, screenY} to second item of ((its frame) as list) -- size of the screen with the main menu
				set {width, height} to {width, height} of customMenu's |size|()
				set origin to {(screenX - width) / 2 + (first item of menuOffset), (screenY + height) / 1.5 + (last item of menuOffset)}
			end if
			tell customMenu to popUpMenuPositioningItem:(its itemAtIndex:0) atLocation:origin inView:(missing value)
		end if
	on error errmess number errnum
		set my failure to {errorMessage:errmess, errorNumber:errnum, handlerName:"doStuff:"}
	end try
end doStuff:

# Make and return a NSWindow or NSPanel.
# Default styleMask includes a title, close and minimize buttons, and is not resizeable.
# If no origin (top left point) is given the window will be centered.
to makeWindow at (origin as list) given contentSize:contentSize as list : {400, 200}, styleMask:styleMask as integer : 15, title:title as text : "", panel:panel as boolean : false, floats:floats as boolean : false, aShadow:aShadow as boolean : true, minimumSize:minimumSize as list : {}, maximumSize:maximumSize as list : {}, backgroundColor:backgroundColor : missing value
	tell current application to set theClass to item ((panel as integer) + 1) of {its NSWindow, its NSPanel}
	tell (theClass's alloc()'s initWithContentRect:{{0, 0}, contentSize} styleMask:styleMask backing:2 defer:true)
		if origin is {} then
			its |center|()
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

# Make and return a menu from a (possibly nested) list of menu item names.
to makeMenu for menuItems given title:title as text : "Menu"
	set theMenu to current application's NSMenu's alloc()'s initWithTitle:title
	addMenuList to theMenu given itemList:menuItems
	return theMenu
end makeMenu

# Add a list of menu items to a menu (recursive) - called by makeMenu.
# The itemList can contain nested lists, with any given list of items being the submenu for the previous item.
# Menu items use a common action handler and have no key equivalent by default, but individual item properties
#	can be changed if needed by using NSMenu itemWithTitle: or itemAtIndex: methods to get the desired items.
to addMenuList to theMenu given itemList:itemList as list : {}, previousItem:previousItem : missing value
	repeat with anItem in itemList
		if (contents of anItem) is in {"", {}, missing value} then
			(theMenu's addItem:(current application's NSMenuItem's separatorItem()))
		else if (class of anItem) is list then -- submenu items
			if previousItem is not missing value then -- set menu for the submenu as needed
				if not (previousItem's hasSubmenu) as boolean then -- create submenu
					set submenu to (current application's NSMenu's alloc's initWithTitle:(previousItem's title))
					(previousItem's setSubmenu:submenu) -- for any following lists
				end if
				addMenuList to submenu given itemList:anItem, previousItem:previousItem
			end if
		else -- treat as a menu item title
			set menuItem to (theMenu's addItemWithTitle:(anItem as text) action:"menuAction:" keyEquivalent:"")
			(menuItem's setTarget:me) -- for autoenable
			set previousItem to menuItem -- potential submenu
		end if
	end repeat
end addMenuList

# Common action when a menu item is selected.
on menuAction:sender -- Objective-C method definition: the calling (Cocoa) object is in sender
	try -- do something with the menu item (remember that properties are being used for results)
		set {submenuText, parentText} to {"", ", of the main menu "}
		if (sender's hasSubmenu) as boolean then set submenuText to ", (which is also a menu)"
		try -- add the immediate parent menu, if any
			set parentText to ", of menu '" & ((sender's parentItem's title) as text) & "'"
		end try
		
		set my outcome to ("Menu item '" & (sender's title) as text) & "'" & submenuText & parentText
		# whatever - example sets the outcome property to info about the menu item
		
	on error errmess number errnum
		set my failure to {errorMessage:errmess, errorNumber:errnum, handlerName:"menuAction"}
	end try
end menuAction:

