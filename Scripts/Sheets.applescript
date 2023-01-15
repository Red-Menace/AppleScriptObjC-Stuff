
use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Cocoa"
use scripting additions

property mainWindow : missing value

on run
	try
		if current application's NSThread's isMainThread() as boolean then
			doStuff()
		else
			my performSelectorOnMainThread:"doStuff" withObject:(missing value) waitUntilDone:true
		end if
	on error errmess
		display alert message errmess
	end try
end run

on doStuff() -- make a window and show it
	set mainWindow to current application's NSWindow's alloc's initWithContentRect:{{200, 400}, {400, 200}} styleMask:7 backing:(current application's NSBackingStoreBuffered) defer:true
	set mainWindow's releasedWhenClosed to true
	mainWindow's contentView's addSubview:makeButton("Alert", 180, 30)
	tell mainWindow to makeKeyAndOrderFront:me
end doStuff

on makeButton(title, x, y) -- make a button at the {x, y} position
	tell (current application's NSButton's alloc's initWithFrame:{{x, y}, {70, 24}})
		its setButtonType:(current application's NSMomentaryChangeButton)
		its setBezelStyle:(current application's NSRoundRectBezelStyle)
		its setRefusesFirstResponder:true -- no highlight
		its setTitle:title
		its setAlternateTitle:"Pressed"
		its setTarget:me
		its setAction:"buttonAction:"
		return it
	end tell
end makeButton

on buttonAction:sender -- perform an action when button is clicked
	doAlert()
end buttonAction:

on doAlert() -- show the main alert over the main window
	tell current application's NSAlert's alloc's init()
		its setDelegate:me -- for alertShowHelp
		its setShowsHelp:true
		its setMessageText:"Main alert message."
		its setInformativeText:"Main alert informative text."
		its beginSheetModalForWindow:mainWindow modalDelegate:me didEndSelector:(missing value) contextInfo:(missing value)
	end tell
end doAlert

on alertShowHelp:theAlert -- show the help alert over the main alert
	tell current application's NSAlert's alloc's init()
		its setMessageText:"Help alert message."
		its setInformativeText:"Help alert informative text."
		its beginSheetModalForWindow:(theAlert's |window|()) modalDelegate:me didEndSelector:(missing value) contextInfo:(missing value)
	end tell
	return true
end alertShowHelp:

