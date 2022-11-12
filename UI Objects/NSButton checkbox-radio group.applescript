
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property buttonGroup : missing value

set my buttonGroup to makeButtonGroup at {50, 100} given radio: true, boxWidth:200, itemList:{"foo", "bar 0123456789012345678901234567890" & return, "baz"} -- given arguments are optional
mainWindow's contentView's addSubview:buttonGroup
log (getGroupButtons from buttonGroup)
*)


# Make and return an NSBox containing a group of checkbox or radio buttons.
# The box size is determined by the width parameter and the number of button items.
# The image position is assumed to be to the left of the title (default).
on makeButtonGroup at origin given radio:radio : true, boxWidth:boxWidth : 100, itemList:itemList : {}, title:title : "", titlePosition:titlePosition : 0, lineBreakMode:lineBreakMode : 5, baseTag:baseTag : missing value, action:action : "buttonGroupAction:", target:target : missing value
	set {buttonHeight, padding, tag} to {24, 15, missing value}
	if boxWidth is in {0, false, missing value} then set boxWidth to 0
	set boxHeight to (count itemList) * buttonHeight + padding
	if titlePosition is not 0 then set boxHeight to boxHeight + 12 -- box + default label height
	set theBox to current application's NSBox's alloc's initWithFrame:{origin, {boxWidth, boxHeight}}
	if title is not in {"", missing value} then theBox's setTitle:(title as text)
	theBox's setTitlePosition:titlePosition
	set itemList to (current application's NSOrderedSet's orderedSetWithArray:itemList)'s allObjects() as list -- remove duplicates
	repeat with itemIndex from 1 to (count itemList)
		if baseTag is not missing value then set tag to baseTag + itemIndex -- group using a base tag
		tell (makeGroupButton at origin given radio:radio, buttonName:(item itemIndex of itemList), lineBreakMode:lineBreakMode, tag:tag, action:action, target:target)
			(its setFrame:{{padding, (itemIndex - 1) * buttonHeight}, {boxWidth - (padding * 2), buttonHeight}})
			(theBox's addSubview:it)
		end tell
	end repeat
	return theBox
end makeButtonGroup

# Make an individual checkbox or radio button - the state will be on if the name ends with a return.
# When called by the makeButtonGroup handler, the button width is (re)set relative to the containing box.
# The image position is to the left of the title (default), other positions are left up to the user.
to makeGroupButton at origin given radio:radio : true, controlSize:controlSize : 0, width:width : 0, buttonName:buttonName : "Button", lineBreakMode:lineBreakMode : 5, tag:tag : missing value, action:action : "buttonGroupAction:", target:target : missing value
	if width is in {0, false, missing value} then set width to 0
	if action is not missing value and target is missing value then set target to me
	if radio then
		set button to current application's NSButton's radioButtonWithTitle:"" target:target action:(action as text)
	else
		set button to current application's NSButton's checkboxWithTitle:"" target:target action:(action as text)
	end if
	set buttonName to buttonName as text
	if buttonName ends with return then -- set/check the button
		button's setState:(current application's NSOnState) # NSControlStateValueOn
		set buttonName to text 1 thru -2 of buttonName
	end if
	button's setTitle:buttonName
	button's setControlSize:controlSize -- 0-3 or NSControlSize enum
	button's setFrame:{origin, {width, 24}}
	button's setLineBreakMode:lineBreakMode
	if width is 0 then button's sizeToFit()
	if tag is not missing value then button's setTag:tag
	if action is not missing value then
		if target is missing value then set target to me -- 'me' can't be used as an optional default
		button's setTarget:target
		button's setAction:(action as text)
	end if
	return button
end makeGroupButton

# Perform an action when a button in the group is pressed (required for radio buttons in a matrix).
# The selector for the following is "buttonGroupAction:", and the button pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on buttonGroupAction:sender
	display dialog "The button '" & ((sender's title) as text) & "' was pressed." buttons {"OK"} default button 1 giving up after 2
	-- whatever
end buttonGroupAction:

# Return a record of the button titles and states from the enclosing box.
# Assumes the button group has been created with the above methods.
to getGroupButtons from buttonGroupView given onlySelected:onlySelected : true
	set buttons to current application's NSMutableDictionary's alloc's init()
	repeat with anItem in buttonGroupView's contentView's subviews
		if (anItem's state) as integer is 1 or onlySelected is false then ¬
			tell buttons to setValue:(anItem's state) forKey:(anItem's title)
	end repeat
	return buttons as record
end getGroupButtons


#
# NSBox title positions:
# NSNoImage = 0
# NSImageOnly = 1
# NSImageLeft = 2 (default)
# NSImageRight = 3
# NSImageBelow = 4
# NSImageAbove = 5
# NSImageOverlaps = 6
# NSImageLeading = 7
# NSImageTrailing = 8
#

