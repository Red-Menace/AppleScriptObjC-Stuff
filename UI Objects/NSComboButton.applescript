
use AppleScript version "2.8" -- Monterey (12.0) and later
use framework "Foundation"
use scripting additions


(* NSComboButton example:
property mainWindow : missing value -- globals can also be used
property comboButton : missing value

set my comboButton to makeComboButton at {100, 100} given menuActions:{{"one", "alternateButtonAction:"},{}, {"two", "alternateButtonAction:"}} -- given arguments are optional
mainWindow's contentView's addSubview:comboButton
*)


# Make and return a combo button (available since macOS 13.0 Ventura).
# Menu actions can be an NSMenu or a list of lists, e.g. {{"one", "actionOne:"}, {"two", "actionTwo:"}, ...}.
to makeComboButton at origin as list given controlSize:controlSize as integer : 0, buttonStyle:buttonStyle as integer : 0, buttonFont:buttonFont : missing value, title:title as text : "Combo Button", image:image : missing value, imageScaling:imageScaling as integer : 2, menuActions:menuActions as list : {}, action:action as text : "comboButtonAction:", target:target : missing value
	if action is not missing value then
		if target is missing value then set target to me -- 'me' can't be used as an optional default
		set action to (action as text)
	end if
	if menuActions is not {} then set menuActions to makeActionMenu for menuActions given target:target
	tell (current application's NSComboButton's comboButtonWithTitle:title image:image |menu|:menuActions target:target action:action)
		its setFrameOrigin:origin
		its setControlSize:controlSize -- 0-3 or NSControlSize enum
		if buttonStyle ≥ 0 then its setStyle:buttonStyle -- 0-1 or NSComboButtonStyle enum
		if buttonFont is not missing value then its setFont:buttonFont
		if image is not missing value then if imageScaling is not 2 then its setImageScaling:imageScaling -- 0-3 or NSImageScaling enum
		return it
	end tell
end makeComboButton

# Make and return a menu from a list of list items containing a title and an action selector.
# If actionItems is a list of names or the action selector is missing the default will be used.
to makeActionMenu for actionItems as list given target:target
	tell (current application's NSMenu's alloc()'s initWithTitle:"Button Actions")
		set menuTitles to {}
		repeat with anItem in actionItems
			if anItem is in {"", {}, missing value} then -- separator
				if missing value is not in menuTitles then
					(its addItem:(current application's NSMenuItem's separatorItem()))
					set end of menuTitles to missing value -- just one
				end if
			else -- unique title
				set anItem to anItem as list
				if first item of anItem is not in menuTitles then
					if (first item of anItem) is (last item of anItem) then set end of anItem to "alternateButtonAction:" -- use default action
					set menuItem to (its addItemWithTitle:(first item of anItem) action:(last item of anItem) keyEquivalent:"")
					(menuItem's setTarget:target) -- same as the button
					set end of menuTitles to first item of anItem
				end if
			end if
		end repeat
		return it
	end tell
end makeActionMenu

# Perform an action when the main button is clicked.
# The selector for the following is "comboButtonAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on comboButtonAction:sender
	display dialog "The combo button " & quoted form of ((sender's title) as text) & " was pressed." with title "Default Action" buttons {"OK"} default button 1 giving up after 5
end comboButtonAction:

# A default action for testing alternate button menu items.
# The selector for the following is "alternateButtonAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on alternateButtonAction:sender
	display dialog "The combo button menu item " & quoted form of ((sender's title) as text) & " was pressed." with title "Alternate Action" buttons {"OK"} default button 1 giving up after 5
end alternateButtonAction:


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

