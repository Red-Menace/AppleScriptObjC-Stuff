
(*
	Provides a countdown timer in a menu bar status item with adjustable times and alarm actions.  Note that when running from a script editor, if the script is recompiled, any instances still in the menu bar will remain (and not be functional) until the script editor quits.

	A custom countdown time in seconds can be set by using a valid AppleScript expression, where the terms "hours" and "minutes" can be used for the number of seconds in an hour or minute, respectively - for example:
         300 -- the number of seconds in 5 minutes, shown as 00:05:00
         3 * hours -- evaluates to 3 hours (10800), shown as 03:00:00
         3 * hours + 5 * minutes -- evaluates to 3 hours and 5 minutes (11100), shown as 03:05:00
   An expression can be also be used to specify an alarm time of day (the number of seconds past midnight), where additional terms such as "AM", "PM", "time", and "date" will be accepted - for example:
         10 * hours + 30 * minutes -- 10:30 AM (37800), shown as 10:30:00
         time of date "11:00 PM" -- (82800), shown as 23:00:00
         (date "0:15 AM")'s time -- 15 minutes (900) past midnight, shown as 00:15:00
         (date "12:15 AM")'s time -- same as above

   The statusItem will initially show the alarm time as the countdown, but will change to the time remaining when the countdown starts - if the countdown is started when the alarm time has passed, it will immediately reach 0 and perform the alarm action.
   Note that the countdown and alarm times wrap at 24 hours.

	A user script can also be run when the countdown reaches 0 - although it uses scripts from the user's Application Scripts folder, the application is not sandboxed.
         Scripts should be tested with the timer app to pre-approve any permissions.
         If the script returns "quit" the application will quit.
         If the script returns "restart" the timer will restart unless using an alarm time.

	Sound names from any of the <system|local|user>/Library/Sounds folder can be added to the actionMenuItems property, but must be .aiff audio files.
   An alarm sound will continue until the timer is stopped or restarted.

	Save as a stay-open application, and code sign or make the script read-only to keep accessibility permissions.
	Multiple timers can be created by making multiple copies of the application - note that the name/bundle identifier must be different for preferences and the scripts folder.
	Add a LSUIElement key to the application's Info.plist to make an agent (no app menu or dock tile).
*)


use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

# App properties - these are used when running in the Script Editor to access the appropriate user scripts folder.
# The actual application bundle identifiers must be different for multiple copies, and set using the
# reverse-dns form idPrefix.appName
property idPrefix : "com.yourcompany" -- com.apple.ScriptEditor.id or whatever
property appName : "Menubar Timer"
property version : 2.0

# Cocoa API references
property NSMenu : a reference to current application's NSMenu
property NSDictionary : a reference to current application's NSDictionary
property NSUserDefaults : a reference to current application's NSUserDefaults
property NSStatusBar : a reference to current application's NSStatusBar
property NSColor : a reference to current application's NSColor
property onState : a reference to current application's NSControlStateValueOn
property offState : a reference to current application's NSControlStateValueOff

# User defaults (preferences)
property colorIntervals : {0.35, 0.15} -- OK-to-caution and caution-to-warning color change percentages
property countdownTime : 3600 -- current countdown time (seconds of the custom or selected countdown time)
property alarmTime : 0 -- a target time (overrides countdownTime if not expired)
property timeSetting : "1 Hour" -- the current time menu setting (from timeMenuItems property)
property alarmSetting : "Hero" -- the current alarm menu setting (from actionMenuItems property)
property userScript : "" -- POSIX path to a user script

# User interface items
property statusItem : missing value -- this will be the status bar item
property statusMenu : missing value -- this will be a menu for the statusItem
property timeMenu : missing value -- this will be a menu of the countdown times
property alarmMenu : missing value -- this will be a menu of the alarm settings
property timer : missing value -- this will be a repeating timer
property alarmSound : missing value -- this will be the sound (NSSound works better with the timer)
property timeMenuItems : {"10 Minutes", "30 Minutes", "1 Hour", "2 Hours", "4 Hours"}
property actionMenuItems : {"Basso", "Blow", "Glass", "Hero", "Ping", "Sosumi", "Tink"}

# Script properties and globals
property thisApp : current application
property updateInterval : 1 -- the time between updates (seconds)
property userScriptsFolder : missing value -- where the user scripts are placed
property showErrors : true -- show error alerts?
property testing : false -- don't try to update preferences when testing

global countdown -- the current countdown time (seconds)
global |paused| -- a flag for pausing the timer update (note that 'paused' is a term in Script Debugger)
global titleFont -- font used by the statusItem button title
global okColor, cautionColor, warningColor -- statusItem text colors


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
		set countdown to countdownTime
		set |paused| to true
		set titleFont to thisApp's NSFont's fontWithName:"Courier New Bold" |size|:16 -- boldSystemFontOfSize:14
		set okColor to NSDictionary's dictionaryWithObject:(NSColor's systemGreenColor) forKey:"NSColor"
		set cautionColor to NSDictionary's dictionaryWithObject:(NSColor's systemYellowColor) forKey:"NSColor"
		set warningColor to NSDictionary's dictionaryWithObject:(NSColor's systemRedColor) forKey:"NSColor"
		buildStatusItem()
		my reset:(missing value)
		set my timer to thisApp's NSTimer's timerWithTimeInterval:updateInterval target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true
		thisApp's NSRunLoop's mainRunLoop's addTimer:timer forMode:(thisApp's NSDefaultRunLoopMode)
	on error errmess number errnum
		oops("setup", errmess, errnum)
		terminate()
	end try
end initialize

to performAction() -- do something when the countdown reaches 0
	try
		if alarmSetting is "Off" then -- nothing
			return my startStop:(missing value) -- stop countdown
		else if alarmSetting is "Run Script" then -- run a script and get the result (if any)
			set response to (do shell script "osascript " & quoted form of userScript) -- better path handling
			if response is in {"quit"} then
				terminate()
			else if response is in {"restart"} then
				if timeSetting is "Alarm Time" then
					my startStop:(missing value) -- the alarm time has passed, so don't try to restart
				else
					my startStop:{title:"Start Countdown"} -- restart timer and continue
				end if
			else -- stop countdown
				my startStop:(missing value)
			end if
		else -- play sound (default)
			if alarmSound is not missing value then alarmSound's play() -- continues until timer is stopped
		end if
	on error errmess number errnum
		oops("performAction", errmess, errnum)
		return my startStop:(missing value) -- stop countdown
	end try
end performAction

to readDefaults()
	tell standardUserDefaults() of NSUserDefaults
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
	tell standardUserDefaults() of NSUserDefaults
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
	NSStatusBar's systemStatusBar's removeStatusItem:statusItem
	if name of thisApp does not start with "Script" then -- don't update or quit script editor
		writeDefaults()
		continue quit
	end if
end quit

to setScriptsFolder() -- set the user scripts folder
	tell (id of thisApp) to if it does not start with idPrefix then -- running from Script Editor
		set bundleID to (do shell script "/usr/bin/env ruby -e 'puts \"" & idPrefix & "." & appName & "\".gsub(/[^a-zA-Z0-9.]/, \"-\").downcase'") -- illegal characters replaced by dashes
	else
		set bundleID to it
	end if
	set my userScriptsFolder to POSIX path of ((path to library folder from user domain) as text) & "Application Scripts/" & bundleID & "/"
	tell application "System Events" to if not (exists folder userScriptsFolder) then do shell script "mkdir -p " & quoted form of userScriptsFolder
end setScriptsFolder


##############################
# UI Handlers                #
##############################

to buildStatusItem() -- build the menu bar status item
	buildMenu()
	tell (NSStatusBar's systemStatusBar's statusItemWithLength:(thisApp's NSVariableStatusItemLength))
		its (button's setFont:titleFont)
		its (button's setTitle:(my formatTime(countdownTime)))
		its setMenu:statusMenu
		set my statusItem to it
	end tell
end buildStatusItem

to buildMenu() -- build a menu for the status item
	tell (NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		my (addMenuItem to it without enable given title:appName)
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Start Countdown", action:"startStop:", tag:100)
		my (addMenuItem to it without enable given title:"Pause", action:"pauseContinue:", tag:200)
		my (addMenuItem to it without enable given title:"Reset Countdown", action:"reset:")
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Color Intervals…", action:"editIntervals")
		my (addAlarmMenu to it)
		my (addTimeMenu to it)
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Quit", action:"terminate")
		set my statusMenu to it
	end tell
end buildMenu

to addTimeMenu to theMenu -- submenu for the countdown times
	tell (NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		repeat with anItem in timeMenuItems -- must be a value followed by "Minutes" or "Hours"
			my (addMenuItem to it given title:anItem, action:"setCountdownTime:", state:((anItem as text) is timeSetting))
		end repeat
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Custom Countdown", action:"setCustomTime:", state:(timeSetting is "Custom Countdown"))
		my (addMenuItem to it given title:"Alarm Time", action:"setAlarmTime:", state:(timeSetting is "Alarm Time"))
		set my timeMenu to it
	end tell
	(theMenu's addItemWithTitle:"Countdown Time" action:(missing value) keyEquivalent:"")'s setSubmenu:timeMenu
end addTimeMenu

to addAlarmMenu to theMenu -- submenu for the alarm actions
	tell (NSMenu's alloc's initWithTitle:"")
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

to setStatusTitle(theTime) -- set the statusItem button's attributed string title
	set attrText to thisApp's NSMutableAttributedString's alloc's initWithString:formatTime(theTime)
	tell colorIntervals to if theTime ≥ ((its first item) * countdownTime) then
		attrText's setAttributes:okColor range:{0, attrText's |length|()}
	else if theTime < ((its first item) * countdownTime) and theTime ≥ ((its second item) * countdownTime) then
		attrText's setAttributes:cautionColor range:{0, attrText's |length|()}
	else
		attrText's setAttributes:warningColor range:{0, attrText's |length|()}
	end if
	attrText's addAttribute:(thisApp's NSFontAttributeName) value:titleFont range:{0, attrText's |length|()}
	statusItem's button's setAttributedTitle:attrText
end setStatusTitle

to resetCountdown(theSeconds) -- reset the countdown time
	if theSeconds > 86399 then set theSeconds to theSeconds mod 86400 -- 24 hours
	if theSeconds < 0 then set theSeconds to 0
	set my countdownTime to theSeconds
	statusItem's button's setTitle:formatTime(theSeconds)
	my startStop:(missing value)
end resetCountdown


##############################
# Action Handlers            #
##############################

to setCountdownTime:sender -- set the countdown time and menu item state
	(timeMenu's itemWithTitle:timeSetting)'s setState:offState -- old
	set newTime to (sender's title) as text
	set my timeSetting to newTime
	set interval to (first word of newTime) as integer
	resetCountdown(item (((newTime contains "Minute") as integer) + 1) of {interval * hours, interval * minutes})
	sender's setState:onState -- new
end setCountdownTime:

to setAlarmTime:sender -- set an alarm time
	set theSeconds to getTime("alarm")
	if theSeconds is not missing value then
		set my alarmTime to theSeconds -- keep the setting regardless
		set timeToGo to theSeconds - (time of (current date))
		if timeToGo < 0 then -- alarm time has passed
			(thisApp's NSSpeechSynthesizer's alloc's initWithVoice:(missing value))'s startSpeakingString:"beep" -- no delay
			say "beep"
			activate me
			display dialog "The specified time is valid and has been saved, but note that it is earlier than the current time." with title "Set Alarm Time" buttons {"OK"} default button 1 giving up after 4
		end if
		(timeMenu's itemWithTitle:timeSetting)'s setState:offState -- old
		set my timeSetting to "Alarm Time"
		resetCountdown(theSeconds)
		sender's setState:onState -- new
		statusItem's button's setToolTip:"Alarm Time"
	end if
end setAlarmTime:

to setCustomTime:sender -- set a custom countdown time
	set theSeconds to getTime("countdown")
	if theSeconds is not missing value then
		(timeMenu's itemWithTitle:timeSetting)'s setState:offState -- old
		set my countdownTime to theSeconds
		set my timeSetting to "Custom Countdown"
		resetCountdown(theSeconds)
		sender's setState:onState -- new
		statusItem's button's setToolTip:"Countdown Time"
	end if
end setCustomTime:

to setAlarm:sender -- set the alarm action and menu item state
	set newAlarm to (sender's title) as text
	if newAlarm is "Run Script" then
		set current to ""
		if userScript is not "" then set current to "Script is currently set to " & quoted form of userScript & return & return
		set response to chooseScript(current)
		if response is false then return
		set my userScript to response
	else if newAlarm is not "Off" then -- set up sound
		set my alarmSound to (thisApp's NSSound's soundNamed:newAlarm)
		alarmSound's play() -- sample
	end if
	(alarmMenu's itemWithTitle:alarmSetting)'s setState:offState -- old
	set my alarmSetting to newAlarm
	sender's setState:onState -- new
end setAlarm:

to updateCountdown:sender -- called by the timer to update the menu title
	if |paused| then return
	if countdown ≤ 0 then
		performAction()
	else
		if timeSetting is "Alarm Time" and alarmTime > 0 then -- calculate time remaining to alarm
			set countdown to alarmTime - (time of (current date))
			statusItem's button's setToolTip:"Time Until Alarm"
		else -- continue countdown
			set countdown to countdown - updateInterval
			statusItem's button's setToolTip:"Time Remaining"
		end if
		setStatusTitle(countdown)
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

to reset:_sender -- reset the countdown to the current setting
	if timeSetting is "Alarm Time" then
		set countdown to alarmTime
		set tooltip to "Alarm Time"
	else
		set countdown to countdownTime
		set tooltip to "Countdown Time"
	end if
	statusItem's button's setTitle:formatTime(countdown) -- plain text
	statusItem's button's setToolTip:tooltip
end reset:


##############################
# Utility Handlers           #
##############################

to editIntervals() -- single dialog for multiple item edit
	set {tempTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, return}
	set {Intervals, AppleScript's text item delimiters} to {colorIntervals as text, tempTID}
	set prompt to "Edit the following interval values as desired - items are separated by carriage returns:

• Percentage for color change from OK to caution
• Percentage for color change from caution to warning"
	set title to "Set Color Intervals"
	try
		activate me
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

to chooseScript(prefix)
	tell application "System Events"
		set scriptPaths to POSIX path of files of disk item userScriptsFolder whose type identifier is "com.apple.applescript.script"
		if scriptPaths is {} then
			activate me
			display dialog "No scripts found - please place a script in the '" & userScriptsFolder & "' folder and try again." with title "Set Alarm Script" buttons {"OK"} default button 1 giving up after 4
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

to getTime(what) -- get a time for countdown or alarm
	set capWhat to (do shell script "echo " & text 1 of what & " | tr [:lower:] [:upper:]") & text 2 thru -1 of what
	set errorText to ""
	if what is "countdown" then set theTime to countdownTime
	if what is "alarm" then set theTime to alarmTime
	repeat
		try
			activate me
			set response to (text returned of (display dialog "The current " & what & " time is " & formatTime(theTime) & " (hh:mm:ss)" & return & errorText & return & "Enter a new " & what & " time in seconds:" default answer "" & theTime with title "Set " & capWhat & " Time" buttons {"Cancel", "Set " & capWhat} default button 2))
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
	if title is missing value then return theMenu's addItem:(thisApp's NSMenuItem's separatorItem)
	tell (theMenu's addItemWithTitle:title action:action keyEquivalent:theKey)
		if action is not missing value then its setTarget:me
		if tag is not missing value then its setTag:(tag as integer)
		if enable is not missing value then its setEnabled:(enable as boolean)
		if state is not missing value then its setState:(item ((state as integer) + 1) of {offState, onState})
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

to formatTime(theSeconds) -- return formatted string (hh:mm:ss) from seconds
	if theSeconds < 0 then set theSeconds to 0
	if class of theSeconds is integer then tell "000000" & ¬
		(10000 * (theSeconds mod days div hours) ¬
			+ 100 * (theSeconds mod hours div minutes) ¬
			+ (theSeconds mod minutes)) ¬
			to set theSeconds to (text -6 thru -5) & ":" & (text -4 thru -3) & ":" & (text -2 thru -1)
	return theSeconds -- wraps at 24 hours
end formatTime

to validate(timeExpr, extra) -- validation of a time expression (to catch errors and random script input)
	try
		set extraTerms to {} -- countdown expression
		if extra then set extraTerms to {"time", "of", "date", ":", "s", "AM", "PM"} -- alarm time expression
		repeat with aWord in (words of timeExpr) -- check for allowed words/characters or integer values
			if aWord is not in {"hours", "minutes", "+"} & extraTerms then aWord as integer
		end repeat
		set theResult to (run script timeExpr) as integer -- must return integer seconds < 86400 (24 hrs)
		if theResult > 86399 then set theResult to theResult mod 86400 -- wrap at 24 hours
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

