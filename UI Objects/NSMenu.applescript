
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions



(* NSMenu example:

	Separator items are indicated by an empty string.
	
	Menu items use a common menuAction: handler and have no key equivalent by default,
	but individual items can be changed as needed, for example:
		set myMenu to makeMenu for {"Foo", "Bar", "Cow", "Frog"}
		set menuItem to myMenu's itemWithTitle:"Foo" -- or itemWithTag, etc
		menuItem's setAction:customAction
		menuItem's setKeyEquivalent:customKey
		menuItem's setKeyEquivalentModifierMask:(current application's NSShiftKeyMask) -- whatever
		
	The menu declaration consists of a list of item names and (possibly nested) lists of
	item names, with any given list of items being the submenu for the previous text item.
	For example, the following will result in the FOO menu item having a single submenu,
	the BAR menu item having two submenus, with a separator between them, and the indicated
	tag properties if tags are used (a base starting tag can also be specified):

	{"First Item", "Item FOO", {"one", "two"}, "", "Item BAR", {"three", "four", {"five", "six"}, {"seven", "eight"}}, "Last Item"}

	First Item		(1)
	Item FOO			(2)
		one				(3)
		two				(4)
	--------
	Item BAR			(5)
		three			(6)
		four			(7)
			five		(8)
			six			(9)
			seven		(10)
			eight		(11)
	Last Item			(12)

	If using tags, the menu items (excluding separators) are tagged in the order they are created,
	and the tag and menu/menu item titles are logged as a reference (for action handlers, etc).
	The example action handler just displays a dialog with some info about the sender.

property mainWindow : missing value -- globals can also be used
property customMenu : missing value

set my customMenu to makeMenu for {"First Item", "Item foo", {"one", "two"}, "", "Item bar", {"three", "four", {"five", "six"}, {"seven", "eight"}}, "Last Item"} -- given arguments are optional
mainWindow's contentView's setMenu:customMenu
*)


# Make and return a menu from a (nested) list of menu items.
to makeMenu for menuItems given title:title : "Menu", useTags:useTags : true, baseTag:baseTag : 1
	set theMenu to current application's NSMenu's alloc()'s initWithTitle:(title as text)
	addMenuList to theMenu given itemList:menuItems, useTags:useTags, baseTag:baseTag
	return theMenu
end makeMenu

# Add a list of menu items to a menu (recursive).
to addMenuList to theMenu given itemList:itemList : {}, previousItem:previousItem : missing value, useTags:useTags : true, baseTag:baseTag : 1
	repeat with anItem in (itemList as list)
		if (contents of anItem) is "" or anItem is missing value then
			(theMenu's addItem:(current application's NSMenuItem's separatorItem()))
		else if (class of anItem) is list then -- submenu items
			if previousItem is not missing value then -- set menu for the submenu as needed
				if not (previousItem's hasSubmenu) as boolean then -- create submenu
					set submenu to (current application's NSMenu's alloc's initWithTitle:(previousItem's title))
					(previousItem's setSubmenu:submenu) -- for any following lists
				end if
				set baseTag to (addMenuList to submenu given itemList:anItem, previousItem:previousItem, useTags:useTags, baseTag:baseTag)
			end if
		else -- treat as a menu item title
			set menuItem to (theMenu's addItemWithTitle:(anItem as text) action:"menuAction:" keyEquivalent:"")
			(menuItem's setTarget:me) -- for autoenable
			set previousItem to menuItem -- potential submenu
			if useTags then
				(menuItem's setTag:baseTag)
				log "Tag " & baseTag & " is menuItem '" & anItem & "' of menu '" & theMenu's title & "'"
			end if
			set baseTag to baseTag + 1
		end if
	end repeat
	return baseTag
end addMenuList

##################################################
# Individual menu/item handlers
##################################################

# Create and return an NSMenu.
to createMenu for title
	tell (current application's NSMenu's alloc's initWithTitle:(title as text))
		its setAutoenablesItems:true
		its setDelegate:me
		return it
	end tell
end createMenu

# Add a menu item to a menu.
to addMenuItem to theMenu given title:title : "MenuItem", target:target : missing value, action:action : missing value, keyEquivalent:keyEquivalent : "", tag:tag : missing value
	set unique to 1
	set newTitle to (title as text)
	if newTitle is "MenuItem" then set newTitle to newTitle & unique
	tell theMenu -- add suffix for duplicate or default titles
		repeat while ((get its indexOfItemWithTitle:newTitle) as integer) is not -1
			set unique to unique + 1
			set newTitle to (title as text) & unique
		end repeat
		set menuItem to its addItemWithTitle:newTitle action:action keyEquivalent:keyEquivalent
		if target is missing value then set target to me -- 'me' can't be used as an optional default
		menuItem's setTarget:target
		if tag is not missing value then menuItem's setTag:tag
	end tell
	return menuItem
end addMenuItem

# Alternate general-purpose handler to add a menu item to a menu.
to altAddMenuItem to theMenu given title:title : (missing value), header:header : false, action:action : (missing value), theKey:theKey : "", target:target : missing value, tag:tag : (missing value), enable:enable : (missing value), state:state : (missing value) -- given parameters are optional
	if title is in {"", missing value} then return theMenu's addItem:(current application's NSMenuItem's separatorItem)
	tell (current application's NSMenuItem) to if header is true then if (its respondsToSelector:"sectionHeaderWithTitle:") as boolean then return theMenu's addItem:(its sectionHeaderWithTitle:title) -- macOS 14 Sonoma and later
	tell (theMenu's addItemWithTitle:title action:action keyEquivalent:theKey)
		if action is not missing value then its setTarget:(item (((target is missing value) as integer) + 1) of {target, me})
		if tag is not missing value then its setTag:(tag as integer)
		if enable is not missing value then its setEnabled:(item (((enable is false) as integer) + 1) of {true, false})
		if state is not missing value then its setState:state -- 1, 0, -1, or NSControlStateValue enum
		return it
	end tell
end altAddMenuItem


# Common menu action - can use sender's title or tag for comparisons.
on menuAction:sender
	if ((sender's tag) as integer) is 0 then
		set tagText to " with no tag."
	else
		set tagText to " with a tag of " & sender's tag & "."
	end if
	try -- error if no parent (main menu)
		set parentText to "' of menu '" & ((sender's parentItem's title) as text) & "'"
	on error
		set parentText to "'"
	end try
	display dialog "Menu item '" & sender's title & parentText & tagText buttons {"OK"} giving up after 3
end menuAction:


#
# NSControlStateValues:
# NSControlStateValueOn = 1
# NSControlStateValueOff = 0
# NSControlStateValueMixed = -1
#

# 
# NSEventModifierFlags (can be added for combinations):
# NSEventModifierFlagCapsLock = 1 << 16		(65536)
# NSEventModifierFlagShift = 1 << 17			(131072)
# NSEventModifierFlagControl = 1 << 18		(262144)
# NSEventModifierFlagOption = 1 << 19		(524288)
# NSEventModifierFlagCommand = 1 << 20		(1048576)
# NSEventModifierFlagNumericPad = 1 << 21	(2097152)
# NSEventModifierFlagHelp = 1 << 22			(4194304)
# NSEventModifierFlagFunction = 1 << 23		(8388608)
# 

