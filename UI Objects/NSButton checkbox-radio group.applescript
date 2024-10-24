
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
# NSControlSize values for controlSize will auto size the box, otherwise normal sized controls will be in a custom width box.
to makeButtonGroup at (origin as list) given radio:radio as boolean : true, controlSize:controlSize as integer : 0, itemList:itemList as list : {}, title:title as text : "", titlePosition:titlePosition as integer : 0, lineBreakMode:lineBreakMode as integer : 5, baseTag:baseTag as integer : 0, action:action as text : "buttonGroupAction:", target:target : missing value
	tell (current application's NSMutableOrderedSet's orderedSetWithArray:itemList) -- remove duplicates...
		its removeObjectsInArray:{"", {}, missing value, "missing value"} -- ...and empty items
		set itemList to its allObjects() as list
	end tell
	set {buttonHeight, padding, tag} to {24, 15, 0}
	set {width, itemCount} to {controlSize, (count itemList)}
	set boxHeight to itemCount * buttonHeight + padding
	if titlePosition is not 0 then set boxHeight to boxHeight + 12 -- box + default label height
	set theBox to current application's NSBox's alloc()'s initWithFrame:{origin, {controlSize, boxHeight}}
	if title is not "" then theBox's setTitle:title
	theBox's setTitlePosition:titlePosition
	repeat with itemIndex from 1 to itemCount
		if baseTag > 0 then set tag to baseTag + itemIndex -- group using a base tag
		tell (makeGroupButton at origin given radio:radio, controlSize:width, buttonName:(item itemIndex of itemList), lineBreakMode:lineBreakMode, tag:tag, action:action, target:target)
			set newWidth to ((current application's NSWidth(its frame)) as integer) + (padding * 2)
			if newWidth > controlSize then set controlSize to newWidth
			if width is not in {0, 1, 2, 3} then set controlSize to width
			(theBox's setFrameSize:{controlSize, buttonHeight * (itemCount + 0.75)}) -- adjust box size
			(its setFrame:{{10, (itemIndex - 1) * buttonHeight}, {controlSize - (padding * 2), buttonHeight}})
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
		button's setState:1 -- NSControlStateValueOn/NSOnState
		set buttonName to text 1 thru -2 of buttonName
	end if
	button's setTitle:buttonName
	button's setFrameOrigin:origin
	button's setLineBreakMode:lineBreakMode
	if controlSize is in {0, 1, 2, 3} then -- 0-3 or NSControlSize enum
		button's setControlSize:controlSize
		button's sizeToFit()
	else
		button's setFrameSize:{controlSize, 24} -- default NSControlSize with custom width
	end if
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
		if not onlySelected or (anItem's state) as integer is 1 then ¬
			tell buttons to setValue:(anItem's state) forKey:(anItem's title) -- tags, whatever
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

