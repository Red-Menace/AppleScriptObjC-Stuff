
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSPopover example:
property mainWindow : missing value -- globals can also be used
property popover : missing value

# create controls as desired:
property button : missing value
property textField : missing value
--
set button to makeButton at {10, 10} given title:"Testing"
set textField to makeTextField at {10, 30} given stringValue:"This is a test.", drawsBackground:false

# use a consolidated self-contained handler to show a popover for an individual control:
showPopover for "This is a test." at button

# use a handler that combines the individual handlers to display a popover for a view:
displayPopover for (mainWindow's contentView) given controls:{button, textField}

# or use the individual handlers:
set popoverView to makeViewController for {button, textField}
set my popover to makePopover for popoverView
popover's showRelativeToRect:{{0, 0}, {0, 0}} ofView:(mainWindow's contentView) preferredEdge:0 -- view must be in a window
*)


# Consolidated single handler with optional parameters.
to showPopover for (message as text) at viewRef given alignment:(alignment as integer) : 1, textFont:textFont : (missing value), textColor:textColor : (missing value), padding:(padding as list) : {20, 18}, edge:edge as integer : 1 -- given arguments are optional
	if (message is "") or (viewRef is missing value) then return
	set viewController to current application's NSViewController's alloc's init
	tell (current application's NSTextField's labelWithString:message)
		its setFrameOrigin:{10, 10} -- inset for view
		its setAlignment:alignment -- default NSTextAlignmentCenter
		its setFont:(item (((textFont is missing value) as integer) + 1) of {textFont, current application's NSFont's fontWithName:"Helvetica" |size|:14})
		its setTextColor:(item (((textColor is missing value) as integer) + 1) of {textColor, current application's NSColor's systemRedColor})
		its sizeToFit() -- adjust textField to string after text settings
		tell (its frame) to set {width, height} to {current application's NSWidth(it), current application's NSHeight(it)}
		viewController's setView:(current application's NSView's alloc's initWithFrame:{{0, 0}, {width + (first item of padding), height + (last item of padding)}})
		viewController's view's addSubview:it
	end tell
	tell current application's NSPopover's alloc's init()
		its setContentViewController:viewController
		its setBehavior:(current application's NSPopoverBehaviorTransient)
		its showRelativeToRect:{{0, 0}, {0, 0}} ofView:viewRef preferredEdge:edge -- default NSMinYEdge
	end tell
end showPopover


# Handler that combines the following individual handlers to create and show a popover - view must be in a window.
to displayPopover for targetView given controls:controls : {}, rect:rect : {{0, 0}, {0, 0}}, edge:edge : 0, padding:padding : {20, 20}, animates:animates : true, behavior:behavior : 1
	set popoverView to makeViewController for controls given padding:padding -- create viewController for the controls
	set popover to makePopover for popoverView given animates:animates, behavior:behavior -- create popover
	popover's showRelativeToRect:rect ofView:targetView preferredEdge:edge -- show popover
	return popover
end displayPopover

# Make and return an NSPopover.
to makePopover for viewController given animates:animates : true, behavior:behavior : 1
	tell current application's NSPopover's alloc's init()
		if animates is not true then its setAnimates:false
		if behavior is not 0 then its setBehavior:behavior -- 0 = needs to be closed, 1 = transient
		its setContentViewController:viewController
		its setContentSize:(second item of viewController's view's frame())
		return it
	end tell
end makePopover

# Make and return a view controller for the popover controls.
# Controls are assumed to be stacked, with the default size being the maximum width and combined height of the control(s).
# View size can be padded (default is none) - set the origin and properties of the individual controls to suit.
to makeViewController for (controls as list) given padding:padding as list : {0, 0}, title:title : missing value, representedObject:representedObject : missing value
	set {maxWidth, maxHeight} to {0, 0}
	set viewController to current application's NSViewController's alloc's init
	viewController's setView:(current application's NSView's alloc's initWithFrame:{{0, 0}, {0, 0}})
	repeat with anItem in controls -- adjust size to fit controls
		set {{originX, originY}, {width, height}} to anItem's frame() as list
		set newWidth to originX + width
		set newHeight to originY + height
		if newWidth > maxWidth then set maxWidth to newWidth
		if newHeight > maxHeight then set maxHeight to newHeight
		(viewController's view's addSubview:anItem)
	end repeat
	viewController's view's setFrameSize:{maxWidth + (first item of padding), maxHeight + (last item of padding)}
	if title is not missing value then viewController's setTitle:(title as text)
	if representedObject is not missing value then viewController's setRepresentedObject:representedObject
	return viewController
end makeViewController


##################################################
#	Example Control handlers
##################################################

# Make and return an NSTextField.
to makeTextField at (origin as list) given dimensions:dimensions as list : {100, 22}, secure:secure as boolean : false, editable:editable as boolean : true, selectable:selectable as boolean : true, bordered:bordered as boolean : false, bezeled:bezeled as boolean : false, bezelStyle:bezelStyle as integer : 0, stringValue:stringValue as text : "", placeholder:placeholder as text : "", lineBreakMode:lineBreakMode as integer : 5, textFont:textFont : missing value, textColor:textColor : missing value, backgroundColor:backgroundColor : missing value, drawsBackground:drawsBackground as boolean : true
	set theClass to item ((secure as integer) + 1) of {current application's NSTextField, current application's NSSecureTextField}
	tell (theClass's alloc()'s initWithFrame:{origin, dimensions})
		its setLineBreakMode:lineBreakMode -- default NSLineBreakByTruncatingMiddle
		if textFont is not missing value then its setFont:textFont
		if textColor is not missing value then its setTexColor:textColor
		if backgroundColor is not missing value then its setBackgroundColor:backgroundColor
		if bezeled then
			its setBezeled:bezeled
			its setBezelStyle:bezelStyle
		end if
		if bordered then its setBordered:true
		if stringValue is not "" then its setStringValue:stringValue
		if placeholder is not "" then its setPlaceholderString:placeholder
		its setEditable:editable
		its setSelectable:selectable
		its setDrawsBackground:drawsBackground
		return it
	end tell
end makeTextField

# Make and return an NSButton.
to makeButton at (origin as list) given dimensions:(dimensions as list) : {80, 24}, title:title as text : "Button", alternate:alternate as text : "", buttonType:buttonType as integer : 7, bezelStyle:bezelStyle as integer : 1, bordered:bordered as boolean : true, transparent:transparent as boolean : false, tag:tag as integer : 0, action:action as text : "buttonAction:", target:target : missing value
	tell (current application's NSButton's alloc's initWithFrame:{origin, dimensions}) -- old style
		its setTitle:title
		its setAlternateTitle:alternate
		its setButtonType:buttonType -- NSButtonType enum
		its setBezelStyle:bezelStyle
		its setBordered:bordered
		its setTransparent:transparent
		if tag is not 0 then its setTag:tag
		if action is not "" then
			its setTarget:(item (((target is missing value) as integer) + 1) of {target, me}) -- 'me' can't be used as an optional default
			its setAction:(action as text) -- see the following action handler
		end if
		return it
	end tell
end makeButton

# Perform an action when the connected button is pressed.
on buttonAction:sender
	display dialog "The button '" & ((sender's title) as text) & "' was pressed." buttons {"OK"} default button 1 giving up after 2
	-- whatever
end buttonAction:

