
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property popover : missing value

# create controls as desired:
property button : missing value
property textField : missing value
--
set button to makeButton at {10, 10} given title:"Testing"
set textField to makeTextField at {10, 30} given stringValue:"This is a test.", drawsBackground:false

# use the combination showPopover handler:
showPopover for (mainWindow's contentView) given controls:{button, textField}

# or use the individual handlers:
set popoverView to makeViewController for {button, textField}
set my popover to makePopover for popoverView
popover's showRelativeToRect:{{0, 0}, {0, 0}} ofView:(mainWindow's contentView) preferredEdge:0 -- view must be in a window
*)


# Combination handler to create and show a popover - view must be in a window.
to showPopover for targetView given controls:controls : {}, rect:rect : {{0, 0}, {0, 0}}, edge:edge : 0, padding:padding : {20, 20}, animates:animates : true, behavior:behavior : 1
	set popoverView to makeViewController for controls given padding:padding -- create viewController for the controls
	set popover to makePopover for popoverView given animates:animates, behavior:behavior -- create popover
	popover's showRelativeToRect:rect ofView:targetView preferredEdge:edge -- show popover
	return popover
end showPopover

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
to makeViewController for controls given padding:padding : {0, 0}, title:title : missing value, representedObject:representedObject : missing value
	set {maxWidth, maxHeight} to {0, 0}
	set viewController to current application's NSViewController's alloc's init
	viewController's setView:(current application's NSView's alloc's initWithFrame:{{0, 0}, {0, 0}})
	repeat with anItem in (controls as list) -- adjust size to fit controls
		set {{originX, originY}, {width, height}} to anItem's frame() as list
		set newWidth to originX + width
		set newHeight to originY + height
		if newWidth > maxWidth then set maxWidth to newWidth
		if newHeight > maxHeight then set maxHeight to newHeight
		(viewController's view's addSubview:anItem)
	end repeat
	if class of padding is not list then set padding to {padding, padding} -- common width & height padding
	viewController's view's setFrameSize:{maxWidth + (first item of padding), maxHeight + (last item of padding)}
	if title is not missing value then viewController's setTitle:(title as text)
	if representedObject is not missing value then viewController's setRepresentedObject:representedObject
	return viewController
end makeViewController


##################################################
#	Example Control handlers
##################################################

# Make and return an NSTextField.
to makeTextField at origin given dimensions:dimensions : {100, 22}, secure:secure : false, editable:editable : true, selectable:selectable : true, bordered:bordered : false, bezeled:bezeled : false, bezelStyle:bezelStyle : missing value, stringValue:stringValue : missing value, placeholder:placeholder : missing value, lineBreakMode:lineBreakMode : 5, textFont:textFont : missing value, textColor:textColor : missing value, backgroundColor:backgroundColor : missing value, drawsBackground:drawsBackground : true
	set theClass to current application's NSTextField
	if secure is true then set theClass to current application's NSSecureTextField
	tell (theClass's alloc()'s initWithFrame:{origin, dimensions})
		its setLineBreakMode:lineBreakMode -- 5 = NSLineBreakByTruncatingMiddle
		if textFont is not missing value then its setFont:textFont
		if textColor is not missing value then its setTexColor:textColor
		if backgroundColor is not missing value then its setBackgroundColor:backgroundColor
		if bezeled is not false then
			its setBezeled:bezeled
			its setBezelStyle:bezelStyle
		end if
		if bordered is not false then its setBordered:true
		if stringValue is not missing value then its setStringValue:stringValue
		if placeholder is not missing value then its setPlaceholderString:placeholder
		its setEditable:editable
		its setSelectable:selectable
		its setDrawsBackground:drawsBackground
		return it
	end tell
end makeTextField

# Make and return an NSButton.
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
on buttonAction:sender
	display dialog "The button '" & ((sender's title) as text) & "' was pressed." buttons {"OK"} default button 1 giving up after 2
	-- whatever
end buttonAction:



