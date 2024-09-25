
# Create and show an NSStatusBar status item.
# Add LSUIElement key to an app's Info.plist to make it an agent (no menu or dock tile).
# Items created in a Script Editor will remain in the menu bar unless removed or the editor is quit.
# Run as a stay-open application for extended testing.


use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSStatusItem example:
property statusItem : missing value

set my statusItem to makeStatusItem for "MenuName" -- given arguments are optional
*)


property statusItem : missing value -- this will be the status bar item

on run -- run from the Script Editor or app double-clicked
	if current application's NSThread's isMainThread() as boolean then -- run on main thread
		setup()
	else
		my performSelectorOnMainThread:"setup" withObject:(missing value) waitUntilDone:true
	end if
end run

on setup()
	set my statusItem to makeStatusItem for "Testing" given theMenu:doMenu(), toolTip:"It works!"
end setup


# Make and return a status item.
# The title can be a string, attributed string, or an image file
on makeStatusItem for title given theMenu:theMenu : missing value, toolTip:toolTip : missing value
	tell (current application's NSStatusBar's systemStatusBar's statusItemWithLength:(current application's NSVariableStatusItemLength)) -- NSSquareStatusItemLength
		set image to current application's NSImage's alloc's initByReferencingFile:title
		if (image's isValid) as boolean then -- set image
			image's setSize:{20, 20} -- size image for menu bar
			its (button's setImage:theImage)
		else -- set title
			try
				if title's superclass() is in {current application's NSMutableAttributedString, current application's NSAttributedString} then its (button's setAttributedTitle:title)
			on error errmess
				its (button's setTitle:(title as text))
			end try
		end if
		its button's sizeToFit()
		if toolTip is not in {"", missing value} then its (button's setToolTip:toolTip)
		its setMenu:theMenu
		return it
	end tell
end makeStatusItem

##################################################
#	Utility handlers
##################################################

to doMenu() -- also makeMenu from UI object scripts
	tell (current application's NSMenu's alloc's initWithTitle:"") -- create menu
		(its addItemWithTitle:"Something" action:"doSomething:" keyEquivalent:"")'s setTarget:me
		(its addItemWithTitle:"Another Thing" action:"doAnotherThing:" keyEquivalent:"")'s setTarget:me
		(its addItemWithTitle:"Quit" action:"terminate:" keyEquivalent:"")'s setTarget:me
		return it
	end tell
end doMenu

to doSomething:sender -- handle the 'Something' menu item
	display alert "doing Something..." -- whatever
end doSomething:

to doAnotherThing:sender -- handle the 'Another Thing' menu item
	display alert "doing Another Thing..." -- whatever
end doAnotherThing:

to terminate:sender -- quit handler is not called from normal NSApplication terminate
	current application's NSStatusBar's systemStatusBar's removeStatusItem:statusItem
	if name of current application does not start with "Script" then tell me to quit -- don't quit Script Editors
end terminate:

