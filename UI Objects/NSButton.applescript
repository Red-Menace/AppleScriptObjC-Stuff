
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property button : missing value
property switch : missing value

set my button to makeButton at {50, 50} given title:"This is a long button title", titleFont:current application's NSFont's fontWithName:"Noteworthy Bold" |size|:12 -- given arguments are optional
mainWindow's contentView's addSubview:button

set my switch to makeSwitch at {50, 90} given tag:5 -- given arguments are optional
mainWindow's contentView's addSubview:switch

*)


# Make and return an NSSwitch (available since 10.15 Catalina)
# This operates similar to a checkbox, but using it in lists or tables is not recommended.
# A label should also be added, as the control has no title of its own.
to makeSwitch at origin given controlSize:controlSize : 0, state:state : 0, tag:tag : missing value, action:action : "switchAction:", target:target : missing value
	tell (current application's NSSwitch's alloc's initWithFrame:{origin, {42, 25}}) -- just size for largest
		its setControlSize:controlSize -- 0-2 or NSControlSize enum
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
	set theTag to sender's tag
	if (sender's state as integer) is 1 then
		set theState to "on"
	else
		set theState to "off"
	end if
	display dialog "A switch tagged " & theTag & " was turned " & theState & "." buttons {"OK"} default button 1 giving up after 2
	-- whatever
end switchAction:


# Make and return an NSButton.
# Defaults are for a regular rounded momentary push button.
to makeButton at origin given controlSize:controlSize : 0, width:width : missing value, title:title : "Button", alternateTitle:alternateTitle : missing value, titleFont:titleFont : missing value, buttonType:buttonType : missing value, bezelStyle:bezelStyle : 1, bordered:bordered : missing value, transparent:transparent : missing value, tag:tag : missing value, action:action : "buttonAction:", target:target : missing value
	if width is in {0, false, missing value} then set width to 0
	tell (current application's NSButton's alloc's initWithFrame:{origin, {width, 40}}) -- old style
		its setTitle:title
		if alternateTitle is not missing value then its setAlternateTitle:alternateTitle
		if titleFont is not missing value then its setFont:titleFont
		its setBezelStyle:bezelStyle -- 1-15 or NSBezelStyle enum
		its setControlSize:controlSize -- 0-3 or NSControlSize enum
		if buttonType is not missing value then its setButtonType:buttonType -- 0-9 or NSButtonType enum
		if bordered is not missing value then its setBordered:bordered
		if transparent is not missing value then its setTransparent:transparent
		if tag is not missing value then its setTag:tag
		if action is not missing value then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:(action as text) -- see the following action handler
		end if
		if width is 0 then its sizeToFit()
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
# NSButtonType:
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


# 
# NSBezelStyle:
# NSBezelStyleRounded = 1
# NSBezelStyleRegularSquare = 2
# NSBezelStyleDisclosure = 5
# NSBezelStyleShadowlessSquare = 6
# NSBezelStyleCircular = 7
# NSBezelStyleTexturedSquare = 8
# NSBezelStyleHelpButton = 9
# NSBezelStyleSmallSquare = 10
# NSBezelStyleTexturedRounded = 11
# NSBezelStyleRoundRect = 12
# NSBezelStyleRecessed = 13
# NSBezelStyleRoundedDisclosure = 14
# NSBezelStyleInline = 15
# 


#
# NSControlSize:
# NSControlSizeRegular = 0
# NSControlSizeSmall = 1
# NSControlSizeMini = 2
# NSControlSizeLarge = 3
#

