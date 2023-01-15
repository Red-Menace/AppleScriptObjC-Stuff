
use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

# Provide a timer in an app window and/or in a menu bar status item.
# Add LSUIElement key to the application's Info.plist to make an agent (no app menu or dock tile).

property mainWindow : missing value -- the app's main window
property textField : missing value -- a text field for the window
property statusItem : missing value -- the status bar item
property timerMenu : missing value -- a menu for the timer
property timer : missing value -- a repeating timer (for updating elapsed time)
property updateInterval : 1 -- time between updates (seconds)
property colorIntervals : {30, 60} -- green>yellow and yellow>red color change intervals (seconds)

global elapsed, |paused| -- total elapsed time and a flag to pause the timer update
global titleFont
global greenColor, yellowColor, redColor


on run -- example will run as an app and from the Script Editor for testing
	if current application's NSThread's isMainThread() as boolean then
		my setup()
	else
		my performSelectorOnMainThread:"setup" withObject:(missing value) waitUntilDone:true
	end if
end run

to setup() -- set stuff up and start timer
	try
		set elapsed to 0
		set |paused| to true
		
		# font and colors
		set titleFont to current application's NSFont's fontWithName:"Courier New Bold" |size|:16 -- boldSystemFontOfSize:14
		set greenColor to current application's NSDictionary's dictionaryWithObjects:{current application's NSColor's systemGreenColor} forKeys:{current application's NSForegroundColorAttributeName}
		set yellowColor to current application's NSDictionary's dictionaryWithObjects:{current application's NSColor's systemYellowColor} forKeys:{current application's NSForegroundColorAttributeName}
		set redColor to current application's NSDictionary's dictionaryWithObjects:{current application's NSColor's systemRedColor} forKeys:{current application's NSForegroundColorAttributeName}
		
		# UI items
		buildMenu()
		buildWindow() -- comment to remove window
		buildStatusItem() -- comment to remove status item
		
		# start a repeating timer
		set my timer to current application's NSTimer's timerWithTimeInterval:updateInterval target:me selector:"updateElapsed:" userInfo:(missing value) repeats:true
		current application's NSRunLoop's mainRunLoop's addTimer:timer forMode:(current application's NSDefaultRunLoopMode)
	on error errmess number errnum -- quit on error
		display alert "Error " & errnum message errmess
		terminate()
	end try
end setup

to buildMenu() -- build a menu for the window and status item
	tell (current application's NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		(its addItemWithTitle:"Start" action:"startStop:" keyEquivalent:"")'s setTarget:me
		set menuItem to its addItemWithTitle:"Pause" action:"pauseContinue:" keyEquivalent:""
		menuItem's setTarget:me
		menuItem's setEnabled:false
		(its addItemWithTitle:"Reset" action:"reset:" keyEquivalent:"")'s setTarget:me
		(its addItemWithTitle:"Quit" action:"terminate" keyEquivalent:"")'s setTarget:me
		set my timerMenu to it
	end tell
end buildMenu

to buildWindow() -- build the main window
	tell ((current application's NSWindow's alloc)'s initWithContentRect:[[0, 0], [110, 45]] styleMask:1 backing:2 defer:false)
		its setLevel:(current application's NSFloatingWindowLevel)
		its |center|()
		its setTitle:"Timer"
		set its delegate to me
		set my mainWindow to it
	end tell
	buildTextField()
	mainWindow's contentView's addSubview:textField
	mainWindow's contentView's setMenu:timerMenu
	mainWindow's orderFront:me
end buildWindow

to buildTextField() -- build a text field for the timer display
	tell (current application's NSTextField's alloc's initWithFrame:[[15, 0], [100, 32]])
		its setRefusesFirstResponder:true
		its setBezeled:false
		its setDrawsBackground:false
		its setSelectable:false
		its setFont:titleFont
		its setStringValue:(my formatTime(0))
		set my textField to it
	end tell
end buildTextField

on buildStatusItem() -- build a menu bar status item for the timer display
	tell (current application's NSStatusBar's systemStatusBar's statusItemWithLength:(current application's NSVariableStatusItemLength))
		its (button's setFont:titleFont)
		its (button's setTitle:(text 4 thru -1 of my formatTime(0)))
		its button's sizeToFit()
		its setMenu:timerMenu
		set my statusItem to it
	end tell
end buildStatusItem

to updateElapsed:sender -- called by the repeating timer to update the elapsed time display(s)
	if paused then return -- skip it
	set elapsed to elapsed + updateInterval
	try
		set newTime to formatTime(elapsed) -- plain text
		set attrText to current application's NSMutableAttributedString's alloc's initWithString:newTime
		tell colorIntervals to if elapsed ≤ its first item then -- first color
			attrText's setAttributes:greenColor range:{0, attrText's |length|()}
		else if elapsed > its first item and elapsed ≤ its second item then -- middle color
			attrText's setAttributes:yellowColor range:{0, attrText's |length|()}
		else -- last color
			attrText's setAttributes:redColor range:{0, attrText's |length|()}
		end if
		attrText's addAttribute:(current application's NSFontAttributeName) value:titleFont range:{0, attrText's |length|()}
		if mainWindow is not missing value then textField's setAttributedStringValue:attrText
		if statusItem is not missing value then
			attrText's deleteCharactersInRange:[0, 3] -- shorten for menu bar
			statusItem's button's setAttributedTitle:attrText
		end if
	on error errmess number errnum -- quit on error
		display alert "Error " & errnum message errmess
		terminate()
	end try
end updateElapsed:

on startStop:sender -- start or stop the timer
	set itemTitle to sender's title as text
	if itemTitle is "Start" then
		set |paused| to false
		sender's setTitle:"Stop"
		my reset:(missing value)
		(timerMenu's itemAtIndex:1)'s setEnabled:true
	else -- stop
		set |paused| to true
		sender's setTitle:"Start"
		(timerMenu's itemAtIndex:1)'s setEnabled:false
		(timerMenu's itemAtIndex:1)'s setTitle:"Pause"
	end if
end startStop:

on pauseContinue:sender -- pause or continue the timer
	set itemTitle to sender's title as text
	if itemTitle is "Pause" then
		set |paused| to true
		sender's setTitle:"Continue"
	else
		set |paused| to false
		sender's setTitle:"Pause"
	end if
end pauseContinue:

to reset:sender -- reset the elapsed time
	set elapsed to 0
	set newTime to formatTime(elapsed) -- plain text
	if mainWindow is not missing value then textField's setStringValue:newTime
	if statusItem is not missing value then statusItem's button's setTitle:(text 4 thru -1 of newTime)
end reset:

to formatTime(theSeconds) -- return formatted string (hh:mm:ss) from seconds
	if class of theSeconds is integer then tell "000000" & ¬
		(10000 * (theSeconds mod days div hours) ¬
			+ 100 * (theSeconds mod hours div minutes) ¬
			+ (theSeconds mod minutes)) ¬
			to set theSeconds to (text -6 thru -5) & ":" & (text -4 thru -3) & ":" & (text -2 thru -1)
	return theSeconds
end formatTime

to terminate() -- quit handler not called from normal NSApplication terminate:
	if timer is not missing value then timer's invalidate()
	if statusItem is not missing value then current application's NSStatusBar's systemStatusBar's removeStatusItem:statusItem
	if mainWindow is not missing value then mainWindow's |close|()
	if name of current application does not start with "Script" then tell me to quit
end terminate

