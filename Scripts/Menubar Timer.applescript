
(*
	Provides a countdown timer in a menu bar statusItem that includes a menu to adjust times and alarm actions.  The statusItem title shows the timer setting (or remaining time) in the form hh:mm:ss (24 hour), and when the timer is running, the remaining time is shown in normal (green), caution (yellow), and warning (red) colors using adjustable percentages.  The statusItem will also flash when the countdown expires, even when the alarm action is set to "Off".
	
	• A custom countdown time (in seconds) can be set by using a valid AppleScript expression, where the terms "hours" and "minutes" can be used for the number of seconds in an hour or minute, respectively - for example:
	      300 -- the number of seconds in 5 minutes, shown as 00:05:00
	      3 * hours -- evaluates to 3 hours (10800), shown as 03:00:00
	      3 * hours + 5 * minutes -- evaluates to 3 hours and 5 minutes (11100), shown as 03:05:00
	• A valid date expression can be also be used to specify an alarm time of day (the number of seconds past midnight), where additional terms such as "AM", "PM", "time", and "date" will be accepted - for example:
	      10 * hours + 30 * minutes -- 10:30 AM (37800), shown as 10:30:00
	      time of date "0:15 AM" -- evaluates to 15 minutes past midnight (900), shown as 00:15:00
	      time of date "12:15 AM" -- same as above
	      (date "11:00 PM")'s time -- another way that evaluates to 11:00 PM (82800), shown as 23:00:00

	• A tooltip for the statusItem will be set to indicate a countdown or alarm time.
	• The statusItem will initially show an alarm time as the countdown, but will change to the time remaining when the countdown starts - if the countdown is started when the alarm time has passed, it will immediately reach 0 and perform the alarm action.
	• Note that while the countdown and alarm times both wrap at 24 hours (86400 seconds), the countdown time will be from when the timer is started, while the alarm time will only match one time per day.
	
	• The preset times can be customised by placing the desired items in the list for the timeMenuItems property.  The items must be a value followed by "Minutes" or "Hours" - be sure to set the timeSetting and countdownTime properties for the matching initial default.
		
	• The preset sounds can also be customised by placing the desired names in the list for the actionMenuItems property.  Names (minus the extension) of items from any of the <system|local|user>/Library/Sounds folders can be used, but the sounds must be .aiff audio files.  Be sure to set the alarmSetting property for the matching initial default.
	• If using an alarm sound, it will play when the countdown reaches 0 and the statusItem will flash until the timer is stopped or restarted.
	
	• A user script can be run when the countdown reaches 0.  Although the application is not sandboxed (and AppleScriptObjC can't use NSAppleScriptTask anyway), it still expects scripts to be placed in the user's ~/Library/Application Scripts/<bundle-identifier> folder (running the app/script will create it).
	      Scripts should be tested with the timer app to pre-approve any permissions.
	      A script can provide feedback to the application when it completes:
	         Returning "quit" will cause the application to quit.
	         Returning "restart" will restart the timer (unless using an alarm time, since it will have expired).
	
	• Save as a stay-open application, and code sign or make the script read-only to keep accessibility permissions.
	• Multiple timers can be created by making multiple copies of the application - note that the name/bundle identifier must be different for preferences and the scripts folder.
	• Add a LSUIElement key to the application's Info.plist to make an agent (no app menu or dock tile).
	
	Finally, note that when running from a script editor, if the script is recompiled, any statusItem left in the menu bar will remain - but will no longer function - until the script editor is restarted.
*)


use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

# App properties - these are used when running in the Script Editor to access the appropriate user scripts folder.
# The actual application bundle identifiers must be different for multiple copies, and should use the reverse-dns form idPrefix.appName
property idPrefix : "com.yourcompany" -- com.apple.ScriptEditor.id or whatever
property appName : "Menubar Timer"
property version : 2.0

# Cocoa API references
property thisApp : current application
property onState : a reference to thisApp's NSControlStateValueOn -- 1
property offState : a reference to thisApp's NSControlStateValueOff -- 0

# User defaults (preferences)
property colorIntervals : {0.35, 0.15} -- normal-to-caution and caution-to-warning color change percentages
property countdownTime : 3600 -- current countdown time (seconds of the custom or selected countdown time)
property alarmTime : 0 -- current target time (overrides countdownTime if not expired)
property timeSetting : "1 Hour" -- the current time menu setting (from timeMenuItems list) + "Alarm Time" and "Custom Time"
property alarmSetting : "Basso" -- the current alarm menu setting (from actionMenuItems list) + "Run Script"
property userScript : "" -- POSIX path to a user script

# User interface items
property statusItem : missing value -- this will be the status bar item
property statusMenu : missing value -- this will be a menu for the statusItem
property timeMenu : missing value -- this will be a menu of the countdown times
property alarmMenu : missing value -- this will be a menu of the alarm settings
property timer : missing value -- this will be a repeating timer
property alarmSound : missing value -- this will be the sound
property timeMenuItems : {"10 Minutes", "30 Minutes", "1 Hour", "2 Hours", "4 Hours"}
property actionMenuItems : {"Basso", "Blow", "Funk", "Glass", "Hero", "Morse", "Ping", "Sosumi", "Submarine"}

# Script properties and globals
property userScriptsFolder : missing value -- where the user scripts are placed
property showErrors : true -- show error alerts?
property testing : false -- don't try to update preferences when testing

global countdown -- the current countdown time (seconds)
global |paused| -- a flag for pausing the timer update (note that 'paused' is a term in Script Debugger)
global titleFont -- font used by the statusItem button title
global flasher -- a flag used to flash the statusItem button title
global normalColor, cautionColor, warningColor -- statusItem text colors


##############################
# Main Handlers              #
##############################

on run -- example will run as an app and from the Script Editor for testing
	if (name of thisApp) contains "Script" then set my testing to true
	if thisApp's NSThread's isMainThread() as boolean then -- app
		initialize()
	else -- running from Script Editor
		my performSelectorOnMainThread:"initialize" withObject:(missing value) waitUntilDone:true
	end if
end run

to initialize() -- set up the app/script
	try
		readDefaults()
		setScriptsFolder()
		set {|paused|, flasher} to {true, false}
		set countdown to countdownTime
		set titleFont to thisApp's NSFont's fontWithName:"Courier New Bold" |size|:16 -- boldSystemFontOfSize:14
		set normalColor to thisApp's NSDictionary's dictionaryWithObject:(thisApp's NSColor's systemGreenColor) forKey:"NSColor"
		set cautionColor to thisApp's NSDictionary's dictionaryWithObject:(thisApp's NSColor's systemYellowColor) forKey:"NSColor"
		set warningColor to thisApp's NSDictionary's dictionaryWithObject:(thisApp's NSColor's systemRedColor) forKey:"NSColor"
		buildStatusItem()
		my resetCountdown:(missing value)
	on error errmess number errnum
		oops("setup", errmess, errnum)
		terminate()
	end try
end initialize

to performAction() -- do something when the countdown reaches 0
	if alarmSetting is "Off" then -- do nothing
		setAttributedTitle(countdown) -- update statusItem title
	else if alarmSetting is "Run Script" then
		runScript()
	else -- play sound (default) - continues until the timer is stopped
		if alarmSound is not missing value then alarmSound's play()
		setAttributedTitle(countdown) -- update statusItem title
	end if
end performAction

to runScript() -- run a script and get the result (if any)
	try
		set response to (do shell script "osascript " & quoted form of userScript) -- better path handling
		if response is in {"quit"} then
			terminate()
		else if response is in {"restart"} then
			if timeSetting is "Alarm Time" then
				my startStop:(missing value) -- the alarm time has passed, so don't try to restart
			else
				my startStop:{title:"Start Countdown"} -- reset the countdown and continue
			end if
		else -- stop the countdown
			my startStop:(missing value)
		end if
	on error errmess number errnum -- script error
		oops("runScript", errmess, errnum)
		return my startStop:(missing value) -- stop the countdown
	end try
end runScript

to readDefaults()
	tell standardUserDefaults() of thisApp's NSUserDefaults
		its registerDefaults:{alarmSetting:alarmSetting, colorIntervals:colorIntervals, countdownTime:countdownTime, alarmTime:alarmTime, timeSetting:timeSetting, userScript:userScript}
		tell (its valueForKey:"AlarmSetting") to if it ≠ missing value then set my alarmSetting to (it as text)
		tell (its valueForKey:"Intervals") to if it ≠ missing value then set my colorIntervals to (it as list)
		tell (its valueForKey:"Countdown") to if it ≠ missing value then set my countdownTime to (it as integer)
		tell (its valueForKey:"AlarmTime") to if it ≠ missing value then set my alarmTime to (it as integer)
		tell (its valueForKey:"TimeSetting") to if it ≠ missing value then set my timeSetting to (it as text)
		tell (its valueForKey:"ScriptPath") to if it ≠ missing value then set my userScript to (it as text)
	end tell
end readDefaults

to writeDefaults()
	if testing is true then return -- don't update preferences when testing
	tell standardUserDefaults() of thisApp's NSUserDefaults
		its setValue:(alarmSetting as text) forKey:"AlarmSetting"
		its setValue:(colorIntervals as list) forKey:"Intervals"
		its setValue:(countdownTime as integer) forKey:"Countdown"
		its setValue:(alarmTime as integer) forKey:"AlarmTime"
		its setValue:(timeSetting as text) forKey:"TimeSetting"
		its setValue:(userScript as text) forKey:"ScriptPath"
	end tell
end writeDefaults

to terminate() -- quit handler not called from statusItem
	quit
end terminate

on quit
	if timer is not missing value then timer's invalidate()
	thisApp's NSStatusBar's systemStatusBar's removeStatusItem:statusItem
	if name of thisApp does not start with "Script" then -- don't update or quit script editor
		writeDefaults()
		continue quit
	end if
end quit

to setScriptsFolder() -- set up the user scripts folder (uses NSFileManager instead of System Events)
	tell (id of thisApp) to if it does not start with idPrefix then -- running from Script Editor
		set bundleID to (do shell script "/usr/bin/env ruby -e 'puts \"" & idPrefix & "." & appName & "\".gsub(/[^a-zA-Z0-9.]/, \"-\").downcase'") -- illegal characters replaced by dashes
	else
		set bundleID to it
	end if
	set my userScriptsFolder to POSIX path of ((path to library folder from user domain) as text) & "Application Scripts/" & bundleID & "/"
	thisApp's NSFileManager's defaultManager's createDirectoryAtPath:userScriptsFolder withIntermediateDirectories:true attributes:(missing value) |error|:(missing value)
end setScriptsFolder


##############################
# UI Handlers                #
##############################

to buildStatusItem() -- build the menu bar status item
	buildMenu()
	tell (thisApp's NSStatusBar's systemStatusBar's statusItemWithLength:(thisApp's NSVariableStatusItemLength))
		its (button's setFont:titleFont)
		its (button's setTitle:(my formatTime(countdownTime)))
		its setMenu:statusMenu
		set my statusItem to it
	end tell
end buildStatusItem

to buildMenu() -- build a menu for the status item
	tell (thisApp's NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		my (addMenuItem to it without enable given title:appName) -- show the app name as the first item (disabled)
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Start Countdown", action:"startStop:", tag:100)
		my (addMenuItem to it without enable given title:"Pause", action:"pauseContinue:", tag:200)
		my (addMenuItem to it without enable given title:"Reset Countdown", action:"resetCountdown:")
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Color Intervals…", action:"editIntervals")
		my (addAlarmMenu to it)
		my (addTimeMenu to it)
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Quit", action:"terminate")
		set my statusMenu to it
	end tell
end buildMenu

to addAlarmMenu to theMenu -- submenu for the alarm actions
	tell (thisApp's NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		my (addMenuItem to it given title:"Off", action:"setAlarm:", state:(alarmSetting is "Off"))
		my (addMenuItem to it)
		repeat with anItem in actionMenuItems -- must be a name from one of the /Library/Sounds/ folders
			set state to alarmSetting is (anItem as text)
			my (addMenuItem to it given title:anItem, action:"setAlarm:", state:state)
			if state then set my alarmSound to (thisApp's NSSound's soundNamed:anItem)
		end repeat
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Run Script", action:"setAlarm:", state:(alarmSetting is "Run Script"))
		set alarmMenu to it
	end tell
	(theMenu's addItemWithTitle:"Alarm Action" action:(missing value) keyEquivalent:"")'s setSubmenu:alarmMenu
end addAlarmMenu

to addTimeMenu to theMenu -- submenu for the countdown times
	tell (thisApp's NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		repeat with anItem in timeMenuItems -- must be a value followed by "Minutes" or "Hours"
			my (addMenuItem to it given title:anItem, action:"setMenuTime:", state:(timeSetting is (anItem as text)))
		end repeat
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Custom Countdown", action:"setCustomTime:", state:(timeSetting is "Custom Countdown"))
		my (addMenuItem to it given title:"Alarm Time", action:"setAlarmTime:", state:(timeSetting is "Alarm Time"))
		set my timeMenu to it
	end tell
	(theMenu's addItemWithTitle:"Countdown Time" action:(missing value) keyEquivalent:"")'s setSubmenu:timeMenu
end addTimeMenu

to setAttributedTitle(theTime) -- set the statusItem button's attributed string title
	set attrText to thisApp's NSMutableAttributedString's alloc's initWithString:formatTime(theTime)
	attrText's addAttribute:(thisApp's NSFontAttributeName) value:titleFont range:{0, attrText's |length|()}
	tell colorIntervals to if theTime > 0 and theTime ≥ ((its first item) * countdownTime) then
		attrText's setAttributes:normalColor range:{0, attrText's |length|()}
	else if theTime > 0 and theTime < ((its first item) * countdownTime) and theTime ≥ ((its second item) * countdownTime) then
		attrText's setAttributes:cautionColor range:{0, attrText's |length|()}
	else
		attrText's setAttributes:warningColor range:{0, attrText's |length|()}
		if theTime ≤ 0 then -- alarm time remaining may be < 0
			set flasher to not flasher -- flash the title background when countdown expires
			if not flasher then attrText's addAttribute:"NSBackgroundColor" value:(thisApp's NSColor's grayColor) range:{0, attrText's |length|()}
		end if
	end if
	statusItem's button's setAttributedTitle:attrText
end setAttributedTitle


##############################
# Action Handlers            #
##############################

to setMenuTime:sender -- set to one of the timeMenuItems and update the menu item state
	(timeMenu's itemWithTitle:timeSetting)'s setState:offState -- old
	set my timeSetting to (sender's title) as text
	set interval to (first word of timeSetting) as integer
	set my countdownTime to item (((timeSetting contains "Minute") as integer) + 1) of {interval * hours, interval * minutes}
	my resetCountdown:(missing value)
	sender's setState:onState -- new
	my startStop:(missing value)
end setMenuTime:

to setAlarmTime:sender -- set an alarm time and update the menu item state
	set theSeconds to getTime("alarm")
	if theSeconds is not missing value then
		set my alarmTime to theSeconds -- keep the setting regardless
		if (theSeconds - (time of (current date))) < 0 then -- alarm time has passed
			(thisApp's NSSpeechSynthesizer's alloc's initWithVoice:(missing value))'s startSpeakingString:"beep" -- asynchronous (NSSpeechSynthesizer deprecated in Sonoma)
			say "beep" -- for echo
			activate me
			display dialog "The specified time is valid and has been saved, but note that it is earlier than the current time." with title "Set Alarm Time" buttons {"OK"} default button 1 giving up after 5
		end if
		(timeMenu's itemWithTitle:timeSetting)'s setState:offState -- old
		set my timeSetting to "Alarm Time"
		my resetCountdown:(missing value)
		sender's setState:onState -- new
		my startStop:(missing value)
	end if
end setAlarmTime:

to setCustomTime:sender -- set a custom countdown time and update the menu item state
	set theSeconds to getTime("countdown")
	if theSeconds is not missing value then
		set my countdownTime to theSeconds
		(timeMenu's itemWithTitle:timeSetting)'s setState:offState -- old
		set my timeSetting to "Custom Countdown"
		my resetCountdown:(missing value)
		sender's setState:onState -- new
		my startStop:(missing value)
	end if
end setCustomTime:

to setAlarm:sender -- set the alarm action and update the menu item state
	tell (sender's title as text) to if it is "Run Script" then
		set current to ""
		if userScript is not "" then set current to "Script is currently set to " & quoted form of userScript & return & return
		set response to my chooseScript(current)
		if response is false then return
		set my userScript to response
	else if it is not "Off" then -- set up sound
		set my alarmSound to (thisApp's NSSound's soundNamed:it) -- NSSound works better with the timer
		alarmSound's play() -- sample
	end if
	(alarmMenu's itemWithTitle:alarmSetting)'s setState:offState -- old
	set my alarmSetting to (sender's title) as text
	sender's setState:onState -- new
end setAlarm:

to updateCountdown:sender -- called by the timer to update the statusItem title
	if |paused| then return
	if countdown ≤ 0 then -- alarm time remaining may be < 0
		performAction()
	else
		if alarmTime > 0 and timeSetting is "Alarm Time" then -- calculate time remaining to alarm
			set countdown to alarmTime - (time of (current date))
		else -- continue countdown
			set countdown to countdown - 1 -- 1 second interval
		end if
		setAttributedTitle(countdown)
	end if
end updateCountdown:

to startStop:sender -- start or stop the timer (tags are used for dynamic titles)
	set {|paused|, itemTitle} to {false, ""}
	if sender is not missing value then set itemTitle to (sender's title as text)
	my resetCountdown:(missing value)
	if itemTitle is "Start Countdown" then
		(statusMenu's itemWithTitle:"Reset Countdown")'s setEnabled:true
		(statusMenu's itemWithTag:100)'s setTitle:"Stop Countdown"
		(statusMenu's itemWithTag:200)'s setEnabled:true
		statusItem's button's setToolTip:(item (((timeSetting is "Alarm Time") as integer) + 1) of {"Time Remaining", "Time Until Alarm"})
		if timer is not missing value then return
		set my timer to thisApp's NSTimer's timerWithTimeInterval:1 target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true
		thisApp's NSRunLoop's mainRunLoop's addTimer:timer forMode:(thisApp's NSDefaultRunLoopMode)
	else -- stop timer
		if alarmSound is not missing value then alarmSound's |stop|()
		(statusMenu's itemWithTitle:"Reset Countdown")'s setEnabled:false
		(statusMenu's itemWithTag:100)'s setTitle:"Start Countdown"
		(statusMenu's itemWithTag:200)'s setEnabled:false
		(statusMenu's itemWithTag:200)'s setTitle:"Pause"
		if timer is not missing value then timer's invalidate()
		set my timer to missing value
	end if
end startStop:

to pauseContinue:sender -- pause or continue the timer
	set itemTitle to sender's title as text
	set |paused| to (item (((itemTitle is "Pause") as integer) + 1) of {false, true})
	sender's setTitle:(item (((itemTitle is "Pause") as integer) + 1) of {"Pause", "Continue"})
end pauseContinue:

to resetCountdown:_sender -- reset the countdown to the current setting
	set flasher to false
	set countdown to (item (((timeSetting is "Alarm Time") as integer) + 1) of {countdownTime, alarmTime})
	statusItem's button's setTitle:formatTime(countdown) -- plain text
	statusItem's button's setToolTip:(item (((timeSetting is "Alarm Time") as integer) + 1) of {"Countdown Time", "Alarm Time"})
end resetCountdown:


##############################
# Utility Handlers           #
##############################

to editIntervals() -- a single dialog for multiple item edit
	set {prevTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, return}
	set {intervals, AppleScript's text item delimiters} to {colorIntervals as text, prevTID}
	try
		activate me
		set response to (display dialog "Edit the following countdown color change percentages as desired - items are separated by carriage returns:" & return & return & "• Percentage for color change from normal to caution
• Percentage for color change from caution to warning" with title "Set Color Intervals" default answer intervals buttons {"Cancel", "Default", "OK"} default button 3)
	on error errmess number errnum
		if errnum is -128 then return -- cancel
		oops("editIntervals", errmess, errnum)
		return
	end try
	if button returned of response is "Default" then
		set my colorIntervals to {0.35, 0.15}
		return
	end if
	repeat with anItem from 1 to 2
		try
			set interval to (item anItem of (paragraphs of text returned of response)) as real
			if interval > 1 then set interval to (interval / 100)
			if interval ≥ 0 and interval ≤ 1 then set item anItem of my colorIntervals to interval
		end try -- skip item on error
	end repeat
	if item 1 of colorIntervals < item 2 of colorIntervals then tell my colorIntervals to set {item 1, item 2} to {item 2, item 1}
end editIntervals

to chooseScript(prefix) -- choose one of the scripts in the userScriptsFolder (uses NSFileManager instead of System Events)
	set {scriptPaths, scriptNames} to {{}, {}}
	repeat with anItem in (current application's NSFileManager's defaultManager's enumeratorAtURL:(current application's NSURL's fileURLWithPath:userScriptsFolder) includingPropertiesForKeys:{"NSURLTypeIdentifierKey"} options:7 errorHandler:(missing value))'s allObjects() -- no directories, package contents, or hidden files
		set {theResult, value} to (anItem's getResourceValue:(reference) forKey:"NSURLTypeIdentifierKey" |error|:(missing value)) -- (NSURLTypeIdentifierKey deprecated Big Sur)
		if theResult and (value as text) is "com.apple.applescript.script" then -- only compiled scripts
			set end of scriptPaths to (anItem's |path| as text)
			set end of scriptNames to (anItem's lastPathComponent as text)
		end if
	end repeat
	if scriptPaths is {} then
		activate me
		display dialog "No scripts found - please place a script in the '" & userScriptsFolder & "' folder and try again." with title "Set Alarm Script" buttons {"OK"} default button 1 giving up after 10
		return false
	end if
	set response to (matchChoices from scriptNames into scriptPaths without multipleItems given title:"Set Alarm Script", prompt:prefix & "Choose a script to run when the timer ends:")
	if response is not false then return first item of response
	return false
end chooseScript

to getTime(what) -- get a time for countdown or alarm
	set titledWhat to (do shell script "echo " & text 1 of what & " | tr [:lower:] [:upper:]") & text 2 thru -1 of what
	set errorText to ""
	set theTime to (item (((what is "alarm") as integer) + 1) of {countdownTime, alarmTime})
	repeat
		try
			activate me
			set response to (text returned of (display dialog "The current " & what & " time is " & formatTime(theTime) & " (hh:mm:ss)" & return & errorText & return & "Enter a new " & what & " time in seconds:" default answer "" & theTime with title "Set " & titledWhat & " Time" buttons {"Cancel", "Set " & titledWhat} default button 2))
			set theSeconds to validate(response, (what is "alarm"))
			if theSeconds is not missing value then return theSeconds
		on error errmess number errnum
			if errnum is -128 then exit repeat
			oops("getTime", errmess, errnum)
		end try
		set errorText to "--> the entry must be a valid AppleScript time expression"
	end repeat
	return missing value
end getTime


##############################
# General-purpose Handlers   #
##############################

to addMenuItem to theMenu given title:title : (missing value), action:action : (missing value), theKey:theKey : "", tag:tag : (missing value), enable:enable : (missing value), state:state : (missing value) -- given parameters are optional
	if title is in {"", missing value} then return theMenu's addItem:(thisApp's NSMenuItem's separatorItem)
	tell (theMenu's addItemWithTitle:title action:action keyEquivalent:theKey)
		if action is not missing value then its setTarget:me -- target will only be this script
		if tag is not missing value then its setTag:(tag as integer)
		if enable is not missing value then its setEnabled:(item (((enable is false) as integer) + 1) of {true, false})
		if state is not missing value then its setState:(item (((state is true) as integer) + 1) of {offState, onState})
		return it
	end tell
end addMenuItem

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

to formatTime(theSeconds) -- return formatted 24 hour string (hh:mm:ss) from the seconds
	if theSeconds < 0 then set theSeconds to 0
	if class of theSeconds is integer then tell "000000" & ¬
		(10000 * (theSeconds mod days div hours) ¬
			+ 100 * (theSeconds mod hours div minutes) ¬
			+ (theSeconds mod minutes)) ¬
			to set theSeconds to (text -6 thru -5) & ":" & (text -4 thru -3) & ":" & (text -2 thru -1)
	return theSeconds -- wraps at 24 hours
end formatTime

to validate(timeExpr, extra) -- validation of a user time expression (sanitize script input)
	try
		set extraTerms to {} -- countdown expression
		if extra then set extraTerms to {"time", "of", "date", ":", "s", "AM", "PM"} -- alarm time expression
		repeat with aWord in (words of timeExpr) -- check for allowed words/characters or integer values
			if aWord is not in {"hours", "minutes", "+"} & extraTerms then aWord as integer
		end repeat
		set theResult to (run script timeExpr) as integer -- must return integer seconds
		if theResult > 86399 then set theResult to theResult mod 86400 -- wrap at 24 hours
		if theResult < 0 then set theResult to 86399 - ((-theResult - 1) mod 86400)
		return theResult
	on error errmess number errnum -- syntax error, or something is not a number or allowed word
		oops("validate", errmess, errnum)
		return missing value
	end try
end validate

on oops(theHandler, errmess, errnum) -- common error dialog
	if showErrors is not true then return
	set handlerText to ""
	if theHandler is not in {"", missing value} then set handlerText to " in the " & quoted form of theHandler & " handler."
	activate me
	display alert "Script Error" & handlerText message errmess & " (" & errnum & ")"
end oops

