
#
# Provides a countdown timer menu bar status item with adjustable times and alarm sounds.
# Sound names can be from any of the various Sound libraries, but must be .aiff audio files.
# A user script can also be run when the countdown reaches 0 - scripts must be located in the Application Scripts folder for the bundle identifier, and should be tested with the timer app to pre-approve any permissions.
# Save as a stay-open application, and code sign or make the script read-only to keep accessibility permissions.
# Multiple timers can be created by making multiple copies of the application - note that the name/bundle identifier must be different for the preferences and the scripts folder.
# Add LSUIElement key to the application's Info.plist to make an agent (no app menu or dock tile).
#


use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

# app properties - these are used when running in the Script Editor to access the user scripts folder
# the actual application bundle identifiers must be different for multiple copies, and set using the
# reverse-dns form idPrefix.appName
property idPrefix : "com.yourcompany"
property appName : "Menubar Timer"

# API references
property NSColor : a reference to current application's NSColor
property NSDictionary : a reference to current application's NSDictionary
property NSMenu : a reference to current application's NSMenu
property NSStatusBar : a reference to current application's NSStatusBar

# user defaults
property colorIntervals : {0.35, 0.15} -- OK-to-caution and caution-to-warning color change percentages
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
property userScriptsFolder : missing value -- where the user scripts are placed
property showErrors : true -- show error alerts?
property testing : false -- don't update preferences when testing

global countdown -- the current countdown time (seconds)
global |paused| -- a flag for pausing the timer update (note that 'paused' is a scripting term in Script Debugger)
global titleFont
global okColor, cautionColor, warningColor -- text colors


##############################
# Main Handlers              #
##############################

on run -- example will run as an app and from the Script Editor for testing
	if (name of current application) contains "Script" then set my testing to true
	if current application's NSThread's isMainThread() as boolean then -- app
		setup()
	else -- running from Script Editor
		my performSelectorOnMainThread:"setup" withObject:(missing value) waitUntilDone:true
	end if
end run

to setup() -- set stuff up and start timer
	try
		readDefaults()
		tell (id of current application) to if it does not start with idPrefix then -- running from Script Editor
			set bundleID to (do shell script "/usr/bin/env ruby -e 'puts \"" & idPrefix & "." & appName & "\".gsub(/[^a-zA-Z0-9.]/, \"-\").downcase'") -- illegal characters replaced by dashes
		else
			set bundleID to it
		end if
		set my userScriptsFolder to POSIX path of ((path to library folder from user domain) as text) & "Application Scripts/" & bundleID & "/"
		tell application "System Events" to if not (exists folder userScriptsFolder) then do shell script "mkdir -p " & quoted form of userScriptsFolder
		set countdown to countdownTime
		set |paused| to true
		
		# font and colors
		set titleFont to current application's NSFont's fontWithName:"Courier New Bold" |size|:16 -- boldSystemFontOfSize:14
		set okColor to NSDictionary's dictionaryWithObject:(NSColor's systemGreenColor) forKey:"NSColor"
		set cautionColor to NSDictionary's dictionaryWithObject:(NSColor's systemYellowColor) forKey:"NSColor"
		set warningColor to NSDictionary's dictionaryWithObject:(NSColor's systemRedColor) forKey:"NSColor"
		
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
			return my startStop:(missing value) -- stop countdown
		else if alarmSetting is "Run Script" then
			do shell script "osascript " & quoted form of userScript -- better path handling than 'run script'
			terminate()
		else -- play sound (default)
			if alarmSound is not missing value then alarmSound's play() -- continues until timer is stopped
		end if
	on error errmess number errnum
		oops("performAction", errmess, errnum)
		return my startStop:(missing value) -- stop timer
	end try
end performAction

to readDefaults()
	tell standardUserDefaults() of current application's NSUserDefaults
		its registerDefaults:{alarmSetting:alarmSetting, colorIntervals:colorIntervals, countdownTime:countdownTime, timeSetting:timeSetting, userScript:userScript}
		tell (its valueForKey:"AlarmSetting") to if it is not missing value then set my alarmSetting to (it as text)
		tell (its valueForKey:"Intervals") to if it is not missing value then set my colorIntervals to (it as list)
		tell (its valueForKey:"Countdown") to if it is not missing value then set my countdownTime to (it as integer)
		tell (its valueForKey:"TimeSetting") to if it is not missing value then set my timeSetting to (it as text)
		tell (its valueForKey:"ScriptPath") to if it is not missing value then set my userScript to (it as text)
	end tell
end readDefaults

to writeDefaults()
	if testing is true then return -- don't update preferences when testing
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
		set menuItem to its addItemWithTitle:appName action:(missing value) keyEquivalent:""
		menuItem's setEnabled:false
		its addItem:(current application's NSMenuItem's separatorItem)
		set menuItem to its addItemWithTitle:"Start Countdown" action:"startStop:" keyEquivalent:""
		menuItem's setTarget:me
		menuItem's setTag:100
		set menuItem to its addItemWithTitle:"Pause" action:"pauseContinue:" keyEquivalent:""
		menuItem's setTarget:me
		menuItem's setTag:200
		menuItem's setEnabled:false
		set menuItem to its addItemWithTitle:"Reset Countdown" action:"reset:" keyEquivalent:""
		menuItem's setTarget:me
		menuItem's setEnabled:false
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
		set alarmMenu to it
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
			set input to text returned of (display dialog "The current countdown time is " & formatTime(countdownTime) & " (hh:mm:ss)" & return & errorText & return & "Enter a new countdown time in seconds:" default answer "" & countdownTime with title "Set Countdown Time")
			set theSeconds to validate(input)
			if theSeconds is missing value then
				set errorText to "--> The entry must be a valid AppleScript time expression."
			else
				setCountdownTime(theSeconds)
				(timeMenu's itemWithTitle:timeSetting)'s setState:(current application's NSControlStateValueOff) -- old
				set my timeSetting to "Custom Time"
				sender's setState:(current application's NSControlStateValueOn) -- new
				exit repeat
			end if
		on error errmess number errnum
			if errnum is -128 then exit repeat
			oops("setCustomTime", errmess, errnum)
			set errorText to "--> the entry must be a valid AppleScript time expression"
		end try
	end repeat
end setCustomTime:

to setAlarm:sender -- (re)set the alarm action and menu item state
	set newAlarm to (sender's title) as text
	if newAlarm is "Run Script" then
		set current to ""
		if userScript is not "" then set current to "Script is currently set to " & quoted form of userScript & return & return
		activate me
		set response to chooseScript(current)
		if response is false then return
		set my userScript to response
		set my alarmSound to missing value
	else if newAlarm is not "Off" then -- set up sound
		set my alarmSound to (current application's NSSound's soundNamed:newAlarm)
		alarmSound's play() -- sample
		set my userScript to ""
	else
		set my alarmSound to missing value
		set my userScript to ""
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
				attrText's setAttributes:okColor range:{0, attrText's |length|()}
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

to startStop:sender -- start or stop the timer (tags are used due to different titles)
	set itemTitle to ""
	if sender is not missing value then set itemTitle to (sender's title as text)
	my reset:(missing value)
	if itemTitle is "Start Countdown" then
		set |paused| to false
		(statusMenu's itemWithTitle:"Reset Countdown")'s setEnabled:true
		(statusMenu's itemWithTag:100)'s setTitle:"Stop Countdown"
		(statusMenu's itemWithTag:200)'s setEnabled:true
	else -- stop timer
		set |paused| to true
		if alarmSound is not missing value then alarmSound's |stop|()
		(statusMenu's itemWithTitle:"Reset Countdown")'s setEnabled:false
		(statusMenu's itemWithTag:100)'s setTitle:"Start Countdown"
		(statusMenu's itemWithTag:200)'s setEnabled:false
		(statusMenu's itemWithTag:200)'s setTitle:"Pause"
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
	set title to "Set Color Intervals"
	activate me
	try
		set dialogResult to (display dialog prompt with title title default answer Intervals)
	on error errmess number errnum -- skip
		if errnum is -128 then return
		oops("editIntervals", errmess, errnum)
		return
	end try
	set input to paragraphs of text returned of dialogResult
	repeat with anItem from 1 to 2
		try
			set interval to (item anItem of input) as real
			if interval > 1 then set interval to (interval / 100)
			if interval ≥ 0 and interval ≤ 1 then set item anItem of my colorIntervals to interval
		on error errmess number errnum -- skip item
			-- oops("editIntervals", errmess, errnum)
			-- set item anItem of my colorIntervals to 0.0
		end try
	end repeat
	if item 1 of colorIntervals < item 2 of colorIntervals then tell colorIntervals to set {item 1, item 2} to {item 2, item 1}
end editIntervals


##############################
# Utility Handlers           #
##############################

to chooseScript(prefix)
	tell application "System Events"
		set scriptPaths to POSIX path of files of disk item userScriptsFolder whose type identifier is "com.apple.applescript.script"
		if scriptPaths is {} then
			display dialog "No scripts found - please place a script in the '" & userScriptsFolder & "' folder and try again." with title "Set Alarm Script" buttons {"OK"} default button 1
			return false
		end if
		set scriptNames to {}
		repeat with anItem in scriptPaths
			set end of scriptNames to name of disk item anItem
		end repeat
	end tell
	set response to (matchChoices from scriptNames into scriptPaths without multipleItems given title:"Set Alarm Script", prompt:prefix & "Choose a script to run when the timer ends:")
	if response is false then return false
	return first item of response
end chooseScript

to matchChoices from choiceList into matchList given prompt:prompt : "", title:title : "", OKButton:OKButton : "OK", multipleItems:multipleItems : true -- given parameters are optional
	if matchList is {} or (count choiceList) > (count matchList) then return false -- list counts don't match
	set {dialogList, outputList, prefix} to {{}, {}, ""}
	set {spacer, divider} to {character id 8203, character id 8204} -- zero width space and non-joiner
	repeat with anItem in choiceList -- add prefix characters for indexing and to allow duplicates
		set prefix to prefix & spacer
		set the end of dialogList to (prefix & divider & anItem)
	end repeat
	set choices to (choose from list dialogList with title title with prompt prompt OK button name OKButton multiple selections allowed multipleItems)
	if choices is false then return false -- "Cancel"
	repeat with anItem in choices -- the dialog result will always be a list
		set indx to (offset of spacer & divider in anItem) -- get indexing character count
		set the end of outputList to contents of item (indx as integer) of matchList
	end repeat
	return outputList
end matchChoices

to formatTime(theSeconds) -- return formatted string (hh:mm:ss) from seconds
	if class of theSeconds is integer then tell "000000" & ¬
		(10000 * (theSeconds mod days div hours) ¬
			+ 100 * (theSeconds mod hours div minutes) ¬
			+ (theSeconds mod minutes)) ¬
			to set theSeconds to (text -6 thru -5) & ":" & (text -4 thru -3) & ":" & (text -2 thru -1)
	return theSeconds -- wraps at 24 hours
end formatTime

to setCountdownTime(theSeconds) -- set the countdown time
	if theSeconds > 86399 then set theSeconds to 86399 -- 24 hours
	if theSeconds ≤ 0 then set theSeconds to 0
	set my countdownTime to theSeconds
	statusItem's button's setTitle:formatTime(countdownTime)
	my startStop:(missing value)
end setCountdownTime

to validate(timeExpr) -- validation of the time expression
	try
		repeat with aWord in (words of timeExpr) -- check for allowed words or integer values
			if aWord is not in {"hours", "minutes", "+"} then aWord as integer
		end repeat
		set theResult to (run script timeExpr) as integer -- must return integer seconds < 86400 (24 hrs)
		if theResult > 86399 then error "time result must be less than 24 hours"
		return theResult
	on error errmess number errnum -- syntax error, or something is not a number or allowed word
		oops("validate", errmess, errnum)
		return missing value
	end try
end validate

on oops(theHandler, errmess, errnum) -- common error dialog
	if showErrors is not true then return
	activate me
	set handlerText to ""
	if theHandler is not in {"", missing value} then set handlerText to " in the " & quoted form of theHandler & " handler."
	display alert "Script Error" & handlerText message errmess & " (" & errnum & ")"
end oops

