
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property button : missing value
property switch : missing value

set my button to makeButton at {0, 0} -- given arguments are optional
mainWindow's contentView's addSubview:button

set my switch to makeSwitch at {0, 0} -- given arguments are optional
mainWindow's contentView's addSubview:switch

*)


# Make and return an NSSwitch (available since 10.15 Catalina)
# This operates similar to a checkbox, but using it in lists or tables is not recommended.
# A label also needs to be added, as the control has no title of its own.
to makeSwitch at origin given dimensions:dimensions : {80, 24}, tag:tag : missing value, action:action : "switchAction:", target:target : missing value
	tell (current application's NSSwitch's alloc's initWithFrame:{origin, dimensions})
		if tag is not missing value then its setTag:tag
		if action is not missing value then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:(action as text) -- see the following action handler
		end if
		return it
	end tell
end makeSwitch


# Perform an action when the connected switch is pressed.
# The selector for the following is "switchAction:", and the button pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on switchAction:sender
	display dialog "A switch was pressed." buttons {"OK"} default button 1 giving up after 2
	-- whatever
end switchAction:


# Make and return an NSButton.
# Defaults are for a regular bordered rounded momentary push button (buttonType NSButtonTypeMomentaryPushIn = 7, bezelStyle NSBezelStyleRounded = 1).
to makeButton at origin given dimensions:dimensions : {80, 24}, title:title : "Button", buttonType:buttonType : 7, bezelStyle:bezelStyle : 1, bordered:bordered : true, transparent:transparent : false, alternate:alternate : missing value, tag:tag : missing value, action:action : "buttonAction:", target:target : missing value
	tell (current application's NSButton's alloc's initWithFrame:{origin, dimensions}) -- old style
		its setTitle:(title as text)
		its setButtonType:buttonType -- NSButtonType enum
		its setBezelStyle:bezelStyle
		if bordered is not true then its setBordered:false
		if transparent is not false then its setTransparent:true
		if alternate is not missing value then its setAlternateTitle:alternate
		if tag is not missing value then its setTag:tag
		if action is not missing value then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:(action as text) -- see the following action handler
		end if
		return it
	end tell
end makeButton

# Perform an action when the connected button is pressed.
# The selector for the following is "buttonAction:", and the button pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on buttonAction:sender
	display dialog "The button '" & ((sender's title) as text) & "' was pressed." buttons {"OK"} default button 1 giving up after 2
	-- whatever
end buttonAction:


#
# NSButton types:
# NSButtonTypeMomentaryLight = 0
# NSButtonTypePushOnPushOff = 1
# NSButtonTypeToggle = 2
# NSButtonTypeSwitch = 3 (checkbox)
# NSButtonTypeRadio = 4 (radio)
# NSButtonTypeMomentaryChange = 5
# NSButtonTypeOnOff = 6
# NSButtonTypeMomentaryPushIn = 7 (default)
# NSButtonTypeAccelerator = 8
# NSButtonTypeMultiLevelAccelerator = 9
#

