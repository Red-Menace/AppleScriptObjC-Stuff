
use AppleScript version "2.5" -- Sierra (10.12) or later
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property pathControl : missing value

set my pathControl to makePathControl at {100, 100} given popup:true -- given arguments are optional
mainWindow's contentView's addSubview:pathControl
*)


# Make and return a path control - the pathURL can be posix, HFS, or alias.
on makePathControl at origin given width:width : 200, pathURL:pathURL : missing value, placeholder:placeholder : missing value, popup:popup : false, allowedTypes:allowedTypes : missing value, editable:editable : true, backgroundColor:backgroundColor : missing value, action:action : "pathAction:", target:target : missing value
	if pathURL is (missing value) then set pathURL to (path to desktop folder)
	if class of pathURL is not current application's NSURL then set pathURL to current application's NSURL's fileURLWithPath:(POSIX path of (pathURL as text))
	tell (current application's NSPathControl's alloc's initWithFrame:{origin, {width, 25}})
		if popup is true then
			its setPathStyle:(current application's NSPathStylePopUp) -- 2 (not editable)
		else
			its setPathStyle:(current application's NSPathStyleStandard) -- 0
		end if
		if allowedTypes is not (missing value) then set its allowedTypes to (allowedTypes as list)
		its setURL:pathURL
		if action is not missing value then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setDoubleAction:(action as text)
		end if
		if editable is not false then its setEditable:true
		if backgroundColor is not missing value then its setBackgroundColor:backgroundColor
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

