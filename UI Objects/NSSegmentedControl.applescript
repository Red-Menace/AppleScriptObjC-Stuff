
use AppleScript version "2.7" -- High Sierra (10.13) and later
use framework "Foundation"
use scripting additions


(* NSSegmentedControl example:

	A segmented control combines the features of buttons and popup buttons, in that each segment can operate as a regular segment button but can also have menus.  These handlers create a labeled segment control, with the individual segment labels, toolTips, and any menu items specified with a list of records with the following keys:

	{label:"Button label", toolTip:"Button toolTip", menuItems:{{"MenuItem Title", "actionHandler:"}, {}, "Another Title"}}
	
	The menu item list is a simple single level menu - for more complex menus see the NSMenu script.
	A menu is not created if menuItems is missing value or an empty list.
	An empty list in a list of menu items marks a separator item.
	A menu item can be a list of a name and an action handler, or if just a name a default action handler will be used.
	Clicking a segment button will select it and call the button action handler, holding the button will drop the menu, and selecting a menu item will call its menu action handler.

property mainWindow : missing value -- globals can also be used
property segmentedControl : missing value

set segments to {¬
	{label:"Left", toolTip:"this button has a 3 menu items", menuItems:{{"First", "customSegmentMenuAction:"}, {}, {"Second", "customSegmentMenuAction:"}, "third"}}, ¬
	{label:"Short", menuItems:{}}, ¬
	{label:"A Longer Label", toolTip:"this button only has 2 menu items", menuItems:{"one", "two"}}, ¬
	{label:"?", toolTip:"?"} ¬
		}

set my segmentedControl to makeSegmentedControl at {50, 50} given width:300, itemList:segments
mainWindow's contentView's addSubview:segmentedControl
*)


# Make and return a NSSegmentedControl.
# The radio argument sets single or multiple selections.
# The itemList consists of a list of records containing segment titles and any menus.
to makeSegmentedControl at (origin as list) given controlSize:controlSize as integer : 0, width:width as integer : 0, segmentStyle:segmentStyle as integer : 0, segmentFill:segmentFill as integer : 2, radio:radio as boolean : true, itemList:itemList as list : {}, action:action as text : "segmentButtonAction:", target:target : missing value
	if origin is {} then set origin to {0, 0}
	if target is missing value then set target to me -- 'me' can't be used as an optional default
	tell current application to set mode to item ((radio as integer) + 1) of {its NSSegmentSwitchTrackingSelectAny, its NSSegmentSwitchTrackingSelectOne}
	set array to current application's NSArray's arrayWithArray:itemList
	set labelList to (array's valueForKey:"label") as list
	set toolTipList to (array's valueForKey:"toolTip") as list
	set menuLists to (array's valueForKey:"menuItems") as list
	tell (current application's NSSegmentedControl's segmentedControlWithLabels:labelList trackingMode:mode target:target action:action)
		its setFrameOrigin:origin
		its setControlSize:controlSize -- 0-3 or NSControlSize enum
		its setSegmentStyle:segmentStyle -- 0-8 or NSSegmentStyle enum
		its setSegmentDistribution:segmentFill -- 0-3 or NSSegmentDistribution enum
		if width is not 0 then
			set {_width, height} to second item of (its frame as list)
			its setFrameSize:{width, height} -- usually needs a wider control for the fill
		end if
		repeat with indx from 1 to (count labelList)
			if item indx of toolTipList is not in {"", missing value} then (its setToolTip:(item indx of toolTipList) forSegment:(indx - 1))
			set theMenu to my (makeSegmentMenu for (item indx of menuLists) given target:target)
			(its setMenu:theMenu forSegment:(indx - 1))
		end repeat
		return it
	end tell
end makeSegmentedControl

# Make and return a single level menu from a list of list items containing a title and an action selector.
# There can be multiple separators, but duplicate menu item titles will be skipped.
# If menuItems is just a list of names or the action selector is missing the default will be used.
to makeSegmentMenu for (menuItems as list) given target:target
	if menuItems is in {{}, missing value} then return missing value
	tell (current application's NSMenu's alloc's initWithTitle:"Segment Menu")
		set menuTitles to {}
		repeat with anItem in menuItems
			if anItem is in {"", {}, missing value} then -- separator
				(its addItem:(current application's NSMenuItem's separatorItem()))
			else -- unique title
				set {title, action} to {first item, last item} of (anItem as list)
				if title is not in menuTitles then
					if title is action then set action to "segmentMenuAction:" -- use default action
					set menuItem to (its addItemWithTitle:title action:action keyEquivalent:"")
					(menuItem's setTarget:target) -- same as the button
					set end of menuTitles to title
				end if
			end if
		end repeat
		return it
	end tell
end makeSegmentMenu

# Perform an action when a main segment button is clicked.
# The selector for the following is "segmentButtonAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on segmentButtonAction:sender
	set segmentIndex to sender's selectedSegment() as integer
	set segmentLabel to (sender's labelForSegment:segmentIndex) as text
	display dialog "Segment button " & segmentIndex & " (" & quoted form of segmentLabel & ") was pressed." with title "Default Segment Button Action" buttons {"OK"} default button 1 giving up after 5
end segmentButtonAction:

# Perform an action when a segment menu item is clicked.
# The selector for the following is "segmentMenuAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on segmentMenuAction:sender
	display dialog "The segment menu item " & quoted form of ((sender's title) as text) & " was pressed." with title "Default Segment Menu Action" buttons {"OK"} default button 1 giving up after 5
end segmentMenuAction:

# A custom action when a segment menu item is clicked.
# The selector for the following is "customSegmentMenuAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on customSegmentMenuAction:sender
	display dialog "The segment menu item " & quoted form of ((sender's title) as text) & " was pressed." with title "Custom Segment Menu Action" buttons {"OK"} default button 1 giving up after 5
end customSegmentMenuAction:


#
# NSSegmentStyle:
# NSSegmentStyleAutomatic = 0
# NSSegmentStyleRounded = 1
# NSSegmentStyleTexturedRounded = 2
# NSSegmentStyleRoundRect = 3
# NSSegmentStyleTexturedSquare = 4
# NSSegmentStyleCapsule = 5
# NSSegmentStyleSmallSquare = 6
# NSSegmentStyleSeparated = 8
#

#
# NSSegmentDistribution:
# NSSegmentDistributionFit = 0
# NSSegmentDistributionFill = 1
# NSSegmentDistributionFillEqually = 2
# NSSegmentDistributionFillProportionally = 3
#

