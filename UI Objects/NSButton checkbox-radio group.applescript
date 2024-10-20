
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSButton group example:
property mainWindow : missing value -- globals can also be used
property buttonGroup : missing value

set my buttonGroup to makeButtonGroup at {35, 35} without radio given itemList:{"foo", "bar 0123456789012345678901234567890" & return, "baz", "testing", "whatever"} -- given arguments are optional
mainWindow's contentView's addSubview:buttonGroup

getGroupButtons from buttonGroup -- get a record of the buttonGroup settings
*)


# Make and return a NSBox containing a group of checkbox or radio buttons.
# The box size is determined by the width parameter and the number of button items.
# Buttons are tagged with their order in the list, adding any base amount.
on makeButtonGroup at (origin as list) given radio:radio as boolean : true, width:width as integer : 300, itemList:itemList as list : {}, title:title as text : "", titlePosition:titlePosition as integer : 0, lineBreakMode:lineBreakMode as integer : 5, baseTag:baseTag as integer : 0, action:action as text : "buttonGroupAction:", target:target : missing value
	set {buttonHeight, padding} to {24, 18}
	set {boxWidth, itemCount} to {width, (count itemList)}
	set boxHeight to itemCount * buttonHeight + padding
	if titlePosition is not 0 then set boxHeight to boxHeight + 12 -- box + default title height
	set theBox to current application's NSBox's alloc()'s initWithFrame:{origin, {boxWidth, boxHeight}}
	if title is not "" then theBox's setTitle:title
	theBox's setTitlePosition:titlePosition -- 0-6 or NSTitlePosition enum
	# add any other box settings, such as an autoresizingMask or whatever
	set itemList to (current application's NSOrderedSet's orderedSetWithArray:itemList)'s allObjects() as list -- remove duplicates
	repeat with itemIndex from 1 to itemCount -- items are drawn bottom up, but tagged and indexed in list order
		set tag to (itemCount - itemIndex) + 1
		if baseTag > 0 then set tag to tag + baseTag -- group using a base tag
		tell (makeGroupButton at {0, 0} given radio:radio, buttonName:(item (itemCount - itemIndex + 1) of itemList), lineBreakMode:lineBreakMode, tag:tag, action:action, target:target)
			if width is 0 then -- size box around longest button title
				set newWidth to (first item of second item of (its frame as list)) + (padding * 2)
				if newWidth > boxWidth then set boxWidth to newWidth
				(theBox's setFrameSize:{boxWidth, buttonHeight * (itemCount + 0.75)})
			end if
			(its setFrame:{{10, (itemIndex - 1) * buttonHeight}, {boxWidth - (padding * 2), buttonHeight}})
			(its setRefusesFirstResponder:true) -- initial highlight as desired
			(theBox's addSubview:it)
		end tell
	end repeat
	return theBox
end makeButtonGroup

# Make an individual checkbox or radio button - the state will be on if the name ends with a return.
# The image position is to the left of the title (default), other positions are left up to the user.
to makeGroupButton at (origin as list) given radio:radio as boolean : true, controlSize:controlSize as integer : 0, buttonName:buttonName as text : "Button", lineBreakMode:lineBreakMode as integer : 5, tag:tag as integer : 0, action:action as text : "buttonGroupAction:", target:target : missing value
	if radio then
		set button to current application's NSButton's radioButtonWithTitle:"" target:target action:action
	else
		set button to current application's NSButton's checkboxWithTitle:"" target:target action:action
	end if
	if buttonName ends with return then -- set/check the button
		button's setState:(current application's NSOnState) # NSControlStateValueOn
		set buttonName to text 1 thru -2 of buttonName
	end if
	button's setTitle:buttonName
	if controlSize > 0 then button's setControlSize:controlSize -- 0-3 or NSControlSize enum
	button's setFrame:{origin, {0, 24}}
	button's setLineBreakMode:lineBreakMode
	button's sizeToFit()
	if tag is not 0 then button's setTag:tag
	if action is not "" then
		button's setTarget:(item (((target is missing value) as integer) + 1) of {target, me})
		button's setAction:action
	end if
	return button
end makeGroupButton

# Perform an action when a button in the group is pressed (required for radio buttons in a matrix).
# The selector for the following is "buttonGroupAction:", and the button pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on buttonGroupAction:sender
	display dialog "The button '" & (sender's title as text) & "' with tag " & (sender's tag as text) & " was pressed." buttons {"OK"} default button 1 giving up after 2
	-- whatever
end buttonGroupAction:

# Return a record of the button titles and states from the enclosing box.
# Assumes the button group has been created with the above methods.
to getGroupButtons from buttonGroupView given onlySelected:onlySelected as boolean : true
	set buttons to current application's NSMutableDictionary's alloc()'s init()
	repeat with anItem in buttonGroupView's contentView's subviews
		if (anItem's state) as integer is 1 or not onlySelected then ¬
			tell buttons to setValue:(anItem's state) forKey:(anItem's title) -- or tags, whatever
	end repeat
	return buttons as record
end getGroupButtons


#
# NSTitlePosition:
# NSNoTitle = 0
# NSAboveTop = 1
# NSAtTop = 2
# NSBelowTop = 3
# NSAboveBottom = 4
# NSAtBottom = 5
# NSBelowBottom = 6
#

