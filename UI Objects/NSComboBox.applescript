
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSComboBox example:
property mainWindow : missing value -- globals can also be used
property combobox : missing value

set my combobox to makeCombobox at {100, 100} given itemList:{"foo", "bar", "baz"}, placeholder:"Select an item" -- given arguments are optional
mainWindow's contentView's addSubview:combobox
*)


# Make and return a combo box.
to makeCombobox at origin as list given width:width : 200, itemList:itemList as list : {}, placeholder:placeholder as text : "", lineBreakMode:lineBreakMode as integer : 5, tag:tag as integer : 0, action:action as text : "comboAction:", target:target : missing value
	tell (current application's NSComboBox's alloc()'s initWithFrame:{origin, {width, 25}})
		its setLineBreakMode:lineBreakMode -- 0-5 or NSLineBreakMode enum
		its addItemsWithObjectValues:itemList
		its setCompletes:true -- autocomplete
		if placeholder is not in {"", missing value} then its setPlaceholderString:placeholder
		if width ≤ 0 then its sizeToFit() -- set width to the placeholder
		if tag > 0 then its setTag:tag
		if action is not in {"", "missing value"} then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:action -- see the following action handler
		end if
		return it
	end tell
end makeCombobox

# Perform an action when the control is double-clicked.
# The selector for the following is "comboAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on comboAction:sender
	display dialog "The selected combobox item is " & quoted form of ((sender's stringValue) as text) buttons {"OK"} default button 1 giving up after 5
end comboAction:


#
# NSLineBreakMode:
# NSLineBreakByWordWrapping = 0
# NSLineBreakByCharWrapping = 1
# NSLineBreakByClipping = 2
# NSLineBreakByTruncatingHead = 3
# NSLineBreakByTruncatingTail = 4
# NSLineBreakByTruncatingMiddle = 5
#

