
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSButton example:
property mainWindow : missing value -- globals can also be used
property button : missing value

set my button to makeButton at {50, 50} given title:"This is a long button title", titleFont:(current application's NSFont's fontWithName:"Noteworthy Bold" |size|:12) -- given arguments are optional
button's setRefusesFirstResponder:true -- as desired
mainWindow's contentView's addSubview:button
*)


# Make and return a NSButton.
# Note that the control highlight can act differently for various bezel, border, and transparency combinations.
# Defaults are for a regular rounded momentary push button.
to makeButton at (origin as list) given controlSize:controlSize as {integer, list} : 0, width:width as integer : 0, title:title as text : "Button", alternateTitle:alternateTitle as text : "", titleFont:titleFont : missing value, buttonType:buttonType as integer : 7, bordered:bordered as boolean : true, bezelStyle:bezelStyle as integer : 1, bezelColor:bezelColor : missing value, transparent:transparent as boolean : false, tag:tag as integer : 0, action:action as text : "buttonAction:", target:target : missing value
	if width < 0 then set width to 0
	tell (current application's NSButton's alloc()'s initWithFrame:{origin, {width, 20}}) -- old style
		if class of controlSize is list then
			its setFrameSize:controlSize -- e.g. large transparent button
		else
			if controlSize > 0 then its setControlSize:controlSize -- 0-3 or NSControlSize enum
		end if
		if buttonType is not 7 then its setButtonType:buttonType -- 0-9 or NSButtonType enum
		if titleFont is not missing value then its setFont:titleFont
		if title is not in {"", "missing value"} then its setTitle:title
		if alternateTitle is not in {"", "missing value"} then its setAlternateTitle:alternateTitle
		if bordered then
			its setBordered:bordered
			if bezelStyle > 0 then
				its setBezelStyle:bezelStyle -- 1-15 or NSBezelStyle enum
				if width is 0 then its sizeToFit()
			end if
			if bezelColor is not missing value then its setBezelColor:bezelColor -- NSColor
		else
			its setBordered:false
		end if
		if transparent then its setTransparent:transparent
		if tag > 0 then its setTag:tag
		if action is not in {"", "missing value"} then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:action -- see the following action handler
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

