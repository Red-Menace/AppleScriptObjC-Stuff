
use AppleScript version "2.8" -- Monterey (12.0) and later
use framework "Foundation"
use scripting additions


(* NSComboButton example:
property mainWindow : missing value -- globals can also be used
property comboButton : missing value

# a record to use individual custom action handlers
set my comboButton to makeComboButton at {100, 100} given menuActions:{foo:"menuItemButtonAction:", _:"", bar:"menuItemButtonAction:"} -- given arguments are optional

# a list to use a combined default action handler
set my comboButton to makeComboButton at {100, 100} given menuActions:{"yes", "no", "_", "maybe"}

# a NSMenu can also be used for additional settings (submenus, icons, etc)
set my comboButton to makeComboButton at {100, 100} given menuActions:myCustomMenu

mainWindow's contentView's addSubview:comboButton
*)


# Make and return a combo button (available in macOS 13.0 Ventura and later).
# Menu actions can be a list of titles, a record of titles and actions, or a NSMenu for more complexity.
to makeComboButton at (origin as list) given controlSize:controlSize as integer : 0, buttonStyle:buttonStyle as integer : 0, buttonFont:buttonFont : missing value, title:title as text : "Combo Button", image:image : missing value, imageScaling:imageScaling as integer : 2, menuActions:menuActions : missing value, action:action as text : "comboButtonAction:", target:target : missing value
	if class of menuActions is in {list, record} then set menuActions to makeActionMenu for menuActions given target:target
	if target is missing value then set target to me -- 'me' can't be used as an optional default
	tell (current application's NSComboButton's comboButtonWithTitle:title image:image |menu|:menuActions target:target action:action)
		its setFrameOrigin:origin
		if controlSize > 0 then its setControlSize:controlSize -- 0-3 or NSControlSize enum
		if buttonStyle > 0 then its setStyle:buttonStyle -- 0-1 or NSComboButtonStyle enum
		if buttonFont is not missing value then its setFont:buttonFont
		if image is not missing value then if imageScaling is not 2 then its setImageScaling:imageScaling -- 0-3 or NSImageScaling enum
		return it
	end tell
end makeComboButton


# Make and return a simple single level menu with titles from record keys or a list.
# Empty list items or list items or record keys beginning with an underscore indicate a separator.
to makeActionMenu for actionItems as {list, record} given target:target
	set {dict, defaultAction} to {missing value, "menuItemButtonAction:"}
	if target is missing value then set target to me
	tell (current application's NSMenu's alloc()'s initWithTitle:"Button Actions")
		if class of actionItems is record then -- title:action
			set dict to current application's NSDictionary's dictionaryWithDictionary:actionItems
			set actionItems to dict's allKeys()
		end if
		repeat with anItem in (actionItems as list)
			if anItem begins with "_" or anItem is in {""} then -- no duplicate record/dictionary keys
				(its addItem:(current application's NSMenuItem's separatorItem()))
			else -- key value (record) or default (list) for button action selector
				set action to defaultAction
				if dict is not missing value then set action to (dict's valueForKey:anItem) as text
				set menuItem to (its addItemWithTitle:anItem action:action keyEquivalent:"")
				(menuItem's setTarget:target)
			end if
		end repeat
		return it
	end tell
end makeActionMenu


# Perform an action when the main button is clicked.
# The selector for the following is "comboButtonAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on comboButtonAction:sender
	display dialog "The combo button " & quoted form of ((sender's title) as text) & " was pressed." with title "Button Action" buttons {"OK"} default button 1 giving up after 5
end comboButtonAction:


# A combined default action for button menu items.
# The selector for the following is "menuItemButtonAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on menuItemButtonAction:sender
	display dialog "The combo button menu item " & quoted form of ((sender's title) as text) & " was pressed." with title "Menu Item Action" buttons {"OK"} default button 1 giving up after 5
end menuItemButtonAction:


#
# NSComboButtonStyle:
# NSComboButtonStyleSplit = 0
# NSComboButtonStyleUnified = 1
#

#
# NSImageScaling:
# NSImageScaleProportionallyDown = 0
# NSImageScaleAxesIndependently = 1
# NSImageScaleNone = 2
# NSImageScaleProportionallyUpOrDown = 3
#

#
# NSControlSize:
# NSControlSizeRegular = 0
# NSControlSizeSmall = 1
# NSControlSizeMini = 2
# NSControlSizeLarge = 3
#

