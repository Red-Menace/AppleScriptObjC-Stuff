
use AppleScript version "2.5" -- Sierra (10.12) or later
use framework "Foundation"
use scripting additions


(* NSPathControl example:
property mainWindow : missing value -- globals can also be used
property pathControl : missing value

set my pathControl to makePathControl at {100, 100} with popup -- given arguments are optional
mainWindow's contentView's addSubview:pathControl
*)


# Make and return a path control - the pathURL can also be given as posix, HFS, or alias.
on makePathControl at origin as list given width:width as integer : 200, pathURL:pathURL : missing value, placeholder:placeholder as text : "", popup:popup as boolean : false, allowedTypes:allowedTypes as list : {}, editable:editable as boolean : true, backgroundColor:backgroundColor : missing value, action:action as text : "pathAction:", target:target : missing value
	if pathURL is (missing value) then set pathURL to (path to desktop folder)
	if class of pathURL is not current application's NSURL then set pathURL to current application's NSURL's fileURLWithPath:(POSIX path of (pathURL as text))
	tell (current application's NSPathControl's alloc()'s initWithFrame:{origin, {width, 25}})
		its setPathStyle:(item ((popup as integer) + 1) of {0, 2}) -- NSPathStyleStandard or NSPathStylePopUp
		if allowedTypes is not {} then set its allowedTypes to allowedTypes
		its setURL:pathURL
		its setPlaceholderString:placeholder
		if action is not missing value then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setDoubleAction:action
		end if
		its setEditable:editable
		if backgroundColor is not missing value then its setBackgroundColor:backgroundColor -- NSColor
		return it
	end tell
end makePathControl

# Perform an action when the control is double-clicked.
# The selector for the following is "pathAction:", and the control pressed is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on pathAction:sender
	display dialog "Path Control was double-clicked:" & return & (sender's clickedPathItem's title) as text buttons {"OK"} default button 1
	-- whatever
end pathAction:


#
# NSPathStyle:
# NSPathStyleStandard = 0
# NSPathStylePopUp = 2
#

