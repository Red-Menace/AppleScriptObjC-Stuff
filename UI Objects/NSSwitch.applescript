
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSSwitch example:
property mainWindow : missing value -- the window that will contain the control
property switch : missing value

set {originX, originY} to {60, 100} -- base location
set label to makeLabel at {originX, originY + 5} given labelString:"This is a test switch:" -- offset to match switch
mainWindow's contentView's addSubview:label
set {width, height} to last item of (label's |bounds| as list)
set my switch to makeSwitch at {originX + width, originY} given tag:5 -- place switch after label
mainWindow's contentView's addSubview:switch
*)


# Make and return an NSSwitch (available in macOS 10.15 Catalina and later)
# This operates similar to a checkbox, but using it in lists or tables is not recommended.
# A label should also be added, as the control has no title of its own.
to makeSwitch at origin as list given controlSize:controlSize as integer : 0, state:state as integer : 0, tag:tag as integer : 0, action:action as text : "switchAction:", target:target : missing value
	tell (current application's NSSwitch's alloc()'s initWithFrame:{origin, {42, 25}}) -- just size for largest
		if controlSize > 0 then its setControlSize:controlSize -- 0-2 or NSControlSize enum
		if tag > 0 then its setTag:tag
		if action is not in {"", "missing value"} then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:action -- see the following action handler
		end if
		return it
	end tell
end makeSwitch


# Make and return a label - the bounds can be used to position the switch.
to makeLabel at (origin as list) given labelString:labelString as text : "", maxWidth:maxWidth as integer : 0
	tell (current application's NSTextField's labelWithString:labelString)
		its setFrameOrigin:origin
		its setLineBreakMode:(current application's NSLineBreakByTruncatingMiddle)
		if maxWidth > 0 then
			set {width, height} to last item of (its |bounds| as list)
			its setFrameSize:{maxWidth, height}
		end if
		return it
	end tell
end makeLabel


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

