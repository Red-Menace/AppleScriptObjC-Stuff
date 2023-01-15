
use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Cocoa" -- Foundation, AppKit, and CoreData
use scripting additions

# Watch for specified application activation and update status item timer while it is active.
# Add LSUIElement key to Info.plist to make an agent (no app menu or dock tile).

property watchedApp : "Finder" -- the name of the application to watch/time
property statusItem : missing value -- the status bar item
property statusMenu : missing value -- the status bar item's menu
property timer : missing value -- a repeating timer for updating elapsed time
property updateInterval : 1 -- time between updates (seconds)
property colorIntervals : {30, 60} -- green>yellow and yellow>red color change intervals (seconds)

global elapsed, |paused| -- total elapsed time and a flag to pause the update
global titleFont
global greenColor, yellowColor, redColor

on run -- example will run as app and from the Script Editor
	try
		if current application's NSThread's isMainThread() as boolean then
			my doStuff()
		else
			my performSelectorOnMainThread:"doStuff" withObject:(missing value) waitUntilDone:true
		end if
	on error errmess number errnum
		log "Error:  " & errnum & return & errmess
		display alert "Error " & errnum message errmess
	end try
end run

on doStuff() -- set stuff up and start timer
	set elapsed to 0
	set |paused| to true
	
	# font and colors
	set titleFont to current application's NSFont's fontWithName:"Courier New Bold" |size|:16 -- boldSystemFontOfSize:14
	set greenColor to current application's NSDictionary's dictionaryWithObjects:{current application's NSColor's systemGreenColor} forKeys:{current application's NSForegroundColorAttributeName}
	set yellowColor to current application's NSDictionary's dictionaryWithObjects:{current application's NSColor's systemYellowColor} forKeys:{current application's NSForegroundColorAttributeName}
	set redColor to current application's NSDictionary's dictionaryWithObjects:{current application's NSColor's systemRedColor} forKeys:{current application's NSForegroundColorAttributeName}
	
	# status item and menu
	set my statusItem to current application's NSStatusBar's systemStatusBar's statusItemWithLength:(current application's NSVariableStatusItemLength)
	statusItem's button's setFont:titleFont
	statusItem's button's setTitle:formatTime(0)
	statusItem's button's sizeToFit()
	set my statusMenu to current application's NSMenu's alloc's initWithTitle:""
	statusMenu's addItemWithTitle:(watchedApp & " Elapsed Time") action:(missing value) keyEquivalent:""
	(statusMenu's addItemWithTitle:"Reset Time" action:"reset:" keyEquivalent:"")'s setTarget:me
	(statusMenu's addItemWithTitle:"Quit" action:"terminate" keyEquivalent:"")'s setTarget:me
	statusItem's setMenu:statusMenu
	
	# notification observers
	set activateNotice to current application's NSWorkspaceDidActivateApplicationNotification
	set deactivateNotice to current application's NSWorkspaceDidDeactivateApplicationNotification
	tell current application's NSWorkspace's sharedWorkspace's notificationCenter
		its addObserver:me selector:"activated:" |name|:activateNotice object:(missing value)
		its addObserver:me selector:"deactivated:" |name|:deactivateNotice object:(missing value)
	end tell
	
	# add a repeating timer
	set my timer to current application's NSTimer's timerWithTimeInterval:updateInterval target:me selector:"updateElapsed:" userInfo:(missing value) repeats:true
	current application's NSRunLoop's mainRunLoop's addTimer:timer forMode:(current application's NSDefaultRunLoopMode)
end doStuff

on activated:notification -- notification when app is activated
	set appName to (notification's userInfo's NSWorkspaceApplicationKey's localizedName()) as text
	if appName is watchedApp then set |paused| to false -- resume elapsed count
end activated:

on deactivated:notification -- notification when app is deactivated
	set appName to (notification's userInfo's NSWorkspaceApplicationKey's localizedName()) as text
	if appName is watchedApp then
		set |paused| to true -- pause elapsed count
		statusItem's button's setTitle:formatTime(elapsed)
	end if
end deactivated:

to updateElapsed:sender -- called by the repeating timer to update the elapsed time display
	if |paused| then return -- skip it
	set elapsed to elapsed + updateInterval
	try
		set attrText to current application's NSMutableAttributedString's alloc's initWithString:formatTime(elapsed)
		if elapsed ≤ colorIntervals's first item then -- first color
			attrText's setAttributes:greenColor range:{0, attrText's |length|()}
		else if elapsed > colorIntervals's first item and elapsed ≤ colorIntervals's second item then -- middle color
			attrText's setAttributes:yellowColor range:{0, attrText's |length|()}
		else -- last color
			attrText's setAttributes:redColor range:{0, attrText's |length|()}
		end if
		attrText's addAttribute:(current application's NSFontAttributeName) value:titleFont range:{0, attrText's |length|()}
		statusItem's button's setAttributedTitle:attrText
	on error errmess -- for experimenting
		display alert "Error" message errmess
	end try
end updateElapsed:

to reset:sender -- reset the elapsed time
	set elapsed to 0
	statusItem's button's setTitle:formatTime(elapsed)
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
	current application's NSWorkspace's sharedWorkspace's notificationCenter's removeObserver:me
	timer's invalidate()
	current application's NSStatusBar's systemStatusBar's removeStatusItem:statusItem
	if name of current application does not start with "Script" then tell me to quit
end terminate

