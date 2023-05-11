
#
# Provides a menu bar status item countdown timer with adjustable times and alarm sounds.
# Sound names are from the various Sound libraries, and must be .aiff audio files.
# A user script can also be run when the countdown reaches 0 - scripts should be tested with the timer app to pre-approve any permissions.  A sandboxed app would use NSApplicationScriptsDirectory and NSUserScriptTask, but this uses a regular choose file dialog and osascript.
# Save as a stay-open application for features such as preferences (NSUserDefaults) and Info.plist settings such as LSUIElement (to make the app an agent with no menu or dock tile).  Code sign the app or make the script in the bundle read-only to keep accessibility permissions.
#


use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

# app properties - change as desired for user script folders
property name : "Menubar Timer"
property id : "com.menace-enterprises"
property version : 1.0

# API references
property NSColor : a reference to current application's NSColor
property NSDictionary : a reference to current application's NSDictionary
property NSForegroundColorAttributeName : a reference to current application's NSForegroundColorAttributeName
property NSMenu : a reference to current application's NSMenu
property NSStatusBar : a reference to current application's NSStatusBar

# user defaults
property colorIntervals : {0.35, 0.15} -- normal-to-caution and caution-to-warning color change percentages
property countdownTime : 2 * hours -- default countdown time (seconds)
property alarmSetting : "Hero" -- the current alarm menu setting
property timeSetting : "2 Hours" -- the current time menu setting
property userScript : "" -- POSIX path to a user script

# script properties and globals
property statusItem : missing value -- this will be the status bar item
property statusMenu : missing value -- this will be a menu for the statusItem
property timeMenu : missing value -- this will be a menu of the countdown times
property alarmMenu : missing value -- this will be a menu of the alarm settings
property timer : missing value -- this will be a repeating timer
property updateInterval : 1 -- the time between updates (seconds)
property alarmSound : missing value -- this will be the sound (NSSound works better with the timer)
property soundResources : {"Basso", "Blow", "Glass", "Hero", "Ping", "Sosumi", "Tink"}
property appScripts : missing value -- the application scripts folder

global countdown -- the current countdown time (seconds)
global |paused| -- a flag for pausing the timer update (note that 'paused' is a scripting term in Script Debugger)
global titleFont
global normalColor, cautionColor, warningColor -- text colors


##############################
# Main Handlers              #
##############################

on run -- example will run as an app and from the Script Editor for testing
	if current application's NSThread's isMainThread() as boolean then -- app
		setup()
	else -- running from Script Editor
		my performSelectorOnMainThread:"setup" withObject:(missing value) waitUntilDone:true
	end if
end run

to setup() -- set stuff up and start timer
	try
		readDefaults()
		set countdown to countdownTime
		set |paused| to true
		
		# the user scripts folder (NSApplicationScriptsDirectory)
		set my appScripts to POSIX path of ((path to library folder from user domain) as text) & "Application Scripts/" & id & "/" & name & "/"
		tell application "System Events" to if not (exists folder appScripts) then do shell script "mkdir -p " & quoted form of appScripts -- make the folders
		
		# font and colors
		set titleFont to current application's NSFont's fontWithName:"Courier New Bold" |size|:16
		set normalColor to NSDictionary's dictionaryWithObjects:{NSColor's systemGreenColor} forKeys:{NSForegroundColorAttributeName}
		set cautionColor to NSDictionary's dictionaryWithObjects:{NSColor's systemYellowColor} forKeys:{NSForegroundColorAttributeName}
		set warningColor to NSDictionary's dictionaryWithObjects:{NSColor's systemRedColor} forKeys:{NSForegroundColorAttributeName}
		
		# UI items
		buildMenu()
		buildStatusItem()
		
		# start a repeating timer
		set my timer to current application's NSTimer's timerWithTimeInterval:updateInterval target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true
		current application's NSRunLoop's mainRunLoop's addTimer:timer forMode:(current application's NSDefaultRunLoopMode)
	on error errmess number errnum
		oops("setup", errmess, errnum)
		terminate()
	end try
end setup

to performAction() -- do something when the countdown reaches 0
	try
		if alarmSetting is "Off" then
			return my startStop:(missing value) -- just stop the timer
		else if alarmSetting is "Run Script" then
			do shell script "osascript " & quoted form of userScript -- better path handling than 'run script'
			terminate()
		else -- play sound (default)
			alarmSound's play() -- repeats until timer is stopped
		end if
	on error errmess number errnum
		oops("performAction", errmess, errnum)
		return my startStop:(missing value) -- stop timer
	end try
end performAction

to readDefaults()
	tell standardUserDefaults() of current application's NSUserDefaults
		its registerDefaults:{alarmSetting:alarmSetting, colorIntervals:colorIntervals, countdownTime:countdownTime, timeSetting:timeSetting, userScript:userScript}
		tell (its objectForKey:"AlarmSetting") to if it is not missing value then set my alarmSetting to (it as text)
		tell (its objectForKey:"Intervals") to if it is not missing value then set my colorIntervals to (it as list)
		tell (its objectForKey:"Countdown") to if it is not missing value then set my countdownTime to (it as integer)
		tell (its objectForKey:"TimeSetting") to if it is not missing value then set my timeSetting to (it as text)
		tell (its objectForKey:"ScriptPath") to if it is not missing value then set my userScript to (it as text)
	end tell
end readDefaults

to writeDefaults()
	tell standardUserDefaults() of current application's NSUserDefaults
		its setValue:(alarmSetting as text) forKey:"AlarmSetting"
		its setValue:(colorIntervals as list) forKey:"Intervals"
		its setValue:(countdownTime as integer) forKey:"Countdown"
		its setValue:(timeSetting as text) forKey:"TimeSetting"
		its setValue:(userScript as text) forKey:"ScriptPath"
	end tell
end writeDefaults

to terminate() -- quit handler not called from normal NSApplication terminate
	if timer is not missing value then timer's invalidate()
	NSStatusBar's systemStatusBar's removeStatusItem:statusItem
	if name of current application does not start with "Script" then
		writeDefaults()
		tell me to quit
	end if
end terminate


##############################
# UI Handlers                #
##############################

to buildStatusItem() -- build the menu bar status item
	tell (NSStatusBar's systemStatusBar's statusItemWithLength:(current application's NSVariableStatusItemLength))
		its (button's setFont:titleFont)
		its (button's setTitle:(my formatTime(countdownTime)))
		its setMenu:statusMenu
		set my statusItem to it
	end tell
end buildStatusItem

to buildMenu() -- build a menu for the status item
	tell (NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		(its addItemWithTitle:"Start Countdown" action:"startStop:" keyEquivalent:"")'s setTarget:me
		set menuItem to its addItemWithTitle:"Pause" action:"pauseContinue:" keyEquivalent:""
		menuItem's setTarget:me
		menuItem's setEnabled:false
		(its addItemWithTitle:"Reset Countdown" action:"reset:" keyEquivalent:"")'s setTarget:me
		its addItem:(current application's NSMenuItem's separatorItem)
		my addAlarmsMenu(it)
		my addTimesMenu(it)
		(its addItemWithTitle:"Color Intervals…" action:"editIntervals" keyEquivalent:"")'s setTarget:me
		its addItem:(current application's NSMenuItem's separatorItem)
		(its addItemWithTitle:"Quit" action:"terminate" keyEquivalent:"")'s setTarget:me
		set my statusMenu to it
	end tell
end buildMenu

to addTimesMenu(theMenu) -- submenu for the countdown times
	tell (NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		repeat with anItem in {"30 Minutes", "1 Hour", "2 Hours", "4 Hours"}
			set anItem to anItem as text
			set menuItem to (its addItemWithTitle:anItem action:"setTime:" keyEquivalent:"")
			(menuItem's setTarget:me)
			if timeSetting is anItem then (menuItem's setState:(current application's NSControlStateValueOn))
		end repeat
		set menuItem to (its addItemWithTitle:"Custom Time" action:"setCustomTime:" keyEquivalent:"")
		menuItem's setTarget:me
		if timeSetting is "Custom Time" then (menuItem's setState:(current application's NSControlStateValueOn))
		set my timeMenu to it
	end tell
	set newItem to (theMenu's addItemWithTitle:"Countdown Time" action:(missing value) keyEquivalent:"")
	newItem's setSubmenu:timeMenu
end addTimesMenu

to addAlarmsMenu(theMenu) -- submenu for the alarm actions
	tell (NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		set menuItem to (its addItemWithTitle:"Off" action:"setAlarm:" keyEquivalent:"")
		menuItem's setTarget:me
		if alarmSetting is "Off" then (menuItem's setState:(current application's NSControlStateValueOn))
		its addItem:(current application's NSMenuItem's separatorItem)
		repeat with anItem in soundResources
			set anItem to anItem as text
			set menuItem to (its addItemWithTitle:anItem action:"setAlarm:" keyEquivalent:"")
			(menuItem's setTarget:me)
			if alarmSetting is anItem then
				(menuItem's setState:(current application's NSControlStateValueOn))
				set my alarmSound to (current application's NSSound's soundNamed:anItem)
			end if
		end repeat
		its addItem:(current application's NSMenuItem's separatorItem)
		set menuItem to (its addItemWithTitle:"Run Script" action:"setAlarm:" keyEquivalent:"")
		menuItem's setTarget:me
		if alarmSetting is "Run Script" then (menuItem's setState:(current application's NSControlStateValueOn))
		set my alarmMenu to it
	end tell
	set newItem to (theMenu's addItemWithTitle:"Alarm Action" action:(missing value) keyEquivalent:"")
	newItem's setSubmenu:alarmMenu
end addAlarmsMenu


##############################
# Action Handlers            #
##############################

to setTime:sender -- (re)set the countdown time and menu item state
	(timeMenu's itemWithTitle:timeSetting)'s setState:(current application's NSControlStateValueOff) -- old
	set newTime to (sender's title) as text
	set interval to (first word of newTime) as integer
	if interval is 30 then
		setCountdownTime(30 * minutes)
	else
		setCountdownTime(interval * hours)
	end if
	set my timeSetting to newTime
	sender's setState:(current application's NSControlStateValueOn) -- new
end setTime:

to setCustomTime:sender -- get number of seconds for countdown
	set errorText to ""
	repeat
		try
			activate me
			set theSeconds to text returned of (display dialog "The current countdown time is " & formatTime(countdownTime) & " (hh:mm:ss)" & return & errorText & return & "Enter a new countdown time (or expression) in seconds:" default answer "" & countdownTime with title "Set Countdown Time")
			set theSeconds to (run script theSeconds) as integer
			setCountdownTime(theSeconds)
			(timeMenu's itemWithTitle:timeSetting)'s setState:(current application's NSControlStateValueOff) -- old
			set my timeSetting to "Custom Time"
			sender's setState:(current application's NSControlStateValueOn) -- new
			exit repeat
		on error errmess number errnum
			if errnum is -128 then exit repeat
			set errorText to "--> the entry must be a valid AppleScript expression"
		end try
	end repeat
end setCustomTime:

to setAlarm:sender -- (re)set the alarm action and menu item state
	set newAlarm to (sender's title) as text
	if newAlarm is "Run Script" then
		if userScript is "" then
			set current to ""
		else
			set current to "Script is currently set to " & quoted form of userScript & return & return
		end if
		try
			activate me
			set theScript to (choose file of type "com.apple.applescript.script" with prompt current & "Choose a script to run when the timer ends:" default location appScripts)
			set my userScript to POSIX path of theScript
		on error errmess number errnum -- leave existing on cancel
			log errmess
			return
		end try
	else if newAlarm is not "Off" then -- set up sound
		set my alarmSound to (current application's NSSound's soundNamed:newAlarm)
		alarmSound's play() -- sample
	end if
	(alarmMenu's itemWithTitle:alarmSetting)'s setState:(current application's NSControlStateValueOff) -- old
	set my alarmSetting to newAlarm
	sender's setState:(current application's NSControlStateValueOn) -- new
end setAlarm:

to updateCountdown:sender -- called by the timer to update the menu title
	if |paused| then return
	if countdown = 0 then
		performAction()
	else
		set countdown to countdown - updateInterval
		if countdown ≤ 0 then set countdown to 0
		try
			set newTime to formatTime(countdown) -- plain text
			set attrText to current application's NSMutableAttributedString's alloc's initWithString:newTime
			tell colorIntervals to if countdown ≥ ((its first item) * countdownTime) then
				attrText's setAttributes:normalColor range:{0, attrText's |length|()}
			else if countdown < ((its first item) * countdownTime) and countdown ≥ ((its second item) * countdownTime) then
				attrText's setAttributes:cautionColor range:{0, attrText's |length|()}
			else
				attrText's setAttributes:warningColor range:{0, attrText's |length|()}
			end if
			attrText's addAttribute:(current application's NSFontAttributeName) value:titleFont range:{0, attrText's |length|()}
			statusItem's button's setAttributedTitle:attrText
		on error errmess number errnum
			oops("updateCountdown", errmess, errnum)
			return my startStop:(missing value) -- stop timer
		end try
	end if
end updateCountdown:

to startStop:sender -- start or stop the timer
	set itemTitle to ""
	if sender is not missing value then set itemTitle to (sender's title as text)
	if itemTitle is "Start Countdown" then
		set |paused| to false
		(statusMenu's itemAtIndex:0)'s setTitle:"Stop Countdown"
		(statusMenu's itemAtIndex:1)'s setEnabled:true
		my reset:(missing value)
	else -- stop timer
		set |paused| to true
		alarmSound's |stop|()
		(statusMenu's itemAtIndex:0)'s setTitle:"Start Countdown"
		(statusMenu's itemAtIndex:1)'s setEnabled:false
		(statusMenu's itemAtIndex:1)'s setTitle:"Pause"
	end if
end startStop:

to pauseContinue:sender -- pause or continue the timer
	set itemTitle to sender's title as text
	if itemTitle is "Pause" then
		set |paused| to true
		sender's setTitle:"Continue"
	else
		set |paused| to false
		sender's setTitle:"Pause"
	end if
end pauseContinue:

to reset:sender -- reset the countdown to the current setting
	set countdown to countdownTime
	statusItem's button's setTitle:formatTime(countdown) -- plain text
end reset:

to editIntervals() -- single dialog for multiple item edit
	set {tempTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, return}
	set {Intervals, AppleScript's text item delimiters} to {colorIntervals as text, tempTID}
	set prompt to "Edit the following interval values as desired - items are separated by carriage returns:

• Percentage for color change from OK to caution
• Percentage for color change from caution to warning"
	set title to "Color Intervals"
	activate me
	try
		set dialogResult to (display dialog prompt with title title default answer Intervals)
	on error errmess -- skip
		log errmess
		return
	end try
	set input to paragraphs of text returned of dialogResult
	repeat with anItem from 1 to 2
		try
			set interval to (item anItem of input) as real
			if interval > 1 then set interval to (interval / 100)
			if interval ≥ 0 and interval ≤ 1 then set item anItem of my colorIntervals to interval
		on error errmess -- skip item
			log errmess
		end try
	end repeat
	if item 1 of colorIntervals < item 2 of colorIntervals then tell colorIntervals to set {item 1, item 2} to {item 2, item 1}
end editIntervals


##############################
# Utility Handlers           #
##############################

to formatTime(theSeconds) -- return formatted string (hh:mm:ss) from seconds
	if class of theSeconds is integer then tell "000000" & ¬
		(10000 * (theSeconds mod days div hours) ¬
			+ 100 * (theSeconds mod hours div minutes) ¬
			+ (theSeconds mod minutes)) ¬
			to set theSeconds to (text -6 thru -5) & ":" & (text -4 thru -3) & ":" & (text -2 thru -1)
	return theSeconds -- wraps at 24 hours
end formatTime

to setCountdownTime(theSeconds) -- set the countdown time
	if theSeconds > 86399 then set theSeconds to 86399 -- ~24 hours
	if theSeconds ≤ 0 then set theSeconds to 0
	set my countdownTime to theSeconds
	statusItem's button's setTitle:formatTime(countdownTime)
	my startStop:(missing value)
end setCountdownTime

on oops(theHandler, errmess, errnum) -- common error dialog
	activate me
	set handlerText to ""
	if theHandler is not in {"", missing value} then set handlerText to " in the " & quoted form of theHandler & " handler."
	display alert "Script Error" & handlerText message errmess & " (" & errnum & ")"
end oops

