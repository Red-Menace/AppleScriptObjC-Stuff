
use framework "Cocoa"
use scripting additions

# some shortcuts
property NSWindow : a reference to current application's NSWindow
property NSButton : a reference to current application's NSButton
property NSTextField : a reference to current application's NSTextField
property NSViewController : a reference to current application's NSViewController
property NSView : a reference to current application's NSView
property NSPopover : a reference to current application's NSPopover
property NSFont : a reference to current application's NSFont
property NSColor : a reference to current application's NSColor

property theWindow : missing value

on run -- example will run as app and from the Script Editor
	if current application's NSThread's isMainThread() as boolean then
		doStuff()
	else
		my performSelectorOnMainThread:"doStuff" withObject:(missing value) waitUntilDone:true
	end if
end run

on doStuff() -- make a window and show it
	set theWindow to NSWindow's alloc's initWithContentRect:{{200, 300}, {400, 200}} styleMask:7 backing:(current application's NSBackingStoreBuffered) defer:true
	set theWindow's releasedWhenClosed to true
	theWindow's contentView's addSubview:makeButton("Button", 50, 140)
	theWindow's contentView's addSubview:makeButton("A Second Button", 240, 110)
	theWindow's contentView's addSubview:makeButton("And Yet Another Button", 50, 50)
	tell theWindow to makeKeyAndOrderFront:me
end doStuff


on makeButton(title, x, y) -- make a button at the {x, y} position
	tell (NSButton's alloc's initWithFrame:{{x, y}, {70, 24}})
		its setButtonType:(current application's NSMomentaryChangeButton)
		its setBezelStyle:(current application's NSRoundRectBezelStyle)
		its setRefusesFirstResponder:true -- no highlight
		its setTitle:title
		its sizeToFit()
		its setAlternateTitle:"Pressed"
		its setTarget:me
		its setAction:"buttonAction:"
		return it
	end tell
end makeButton


on buttonAction:sender -- perform an action when button is clicked
	set title to sender's title
	set testString to "This is some popover text
located at '" & title & "'."
	set {{x, y}, {width, height}} to (sender's frame()) as list
	set x to x + (width div 2)
	set y to y + (height div 2)
	my popoverWithMessage:testString atPoint:{x, y} inView:(sender's |window|'s contentView())
end buttonAction:


on popoverWithMessage:_message atPoint:_point inView:_view -- position popover at a point in the view
	set textField to makeTextField()
	textField's setStringValue:_message
	textField's sizeToFit() -- adjust text field to fit string
	set {width, height} to second item of (textField's frame as list) -- size to adjust view to text field
	
	set viewController to NSViewController's alloc's init
	viewController's setView:(NSView's alloc's initWithFrame:{{0, 0}, {width + 15, height + 15}})
	viewController's view's addSubview:textField
	
	tell NSPopover's alloc's init()
		its setContentViewController:viewController
		its setContentSize:(second item of viewController's view's frame())
		its setBehavior:(current application's NSPopoverBehaviorTransient)
		# its setAnimates:false
		its showRelativeToRect:{_point, {1, 1}} ofView:_view preferredEdge:(current application's NSMaxYEdge)
	end tell
end popoverWithMessage:atPoint:inView:


to makeTextField() -- make a text field for the popover
	tell (NSTextField's alloc's initWithFrame:{{10, 10}, {100, 100}})
		its setBordered:false
		its setDrawsBackground:false -- label
		its setRefusesFirstResponder:true -- no highlight
		its setAlignment:(current application's NSTextAlignmentCenter) -- NSTextAlignmentLeft
		its setFont:(current application's NSFont's fontWithName:"Noteworthy Bold" |size|:24)
		its setTextColor:(current application's NSColor's redColor)
		return it
	end tell
end makeTextField


