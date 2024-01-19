
(*
	This script provides a formatted "hh:mm:ss" countdown timer in a menu bar statusItem.  It includes menu items to adjust the countdown or alarm time and action to perform when the countdown expires.  To keep the statusItem title and time settings consistent, the title and countdown/alarm time date pickers use a 24-hour format.  The various timer settings are made from menu selections and popover dialogs.
	
	• The statusItem title will show a time with an icon (and tooltip) indicating if it is a countdown or alarm - if set to an alarm, the alarm time is shown when the timer is stopped, but will change to the time remaining when the timer is started.  Note that while the countdown and alarm times both wrap at 24 hours, the countdown time will be from when the timer is started, while the alarm time will only match one time per day.

	• While the timer is running, the time remaining is shown in normal (green), caution (orange), and warning (red) colors, which are adjustable percentages of the countdown setting, or the alarm time from midnight.
	
	• Preset (menu item) times can be customized by placing the desired items in the list for the timeMenuItems property.  The items must be a value followed by "Hours", "Minutes", or "Seconds" - be sure to set the timeSetting and countdownTime properties for the matching initial default.

	• Preset (menu item) sounds can also be customized by placing the desired names in the list for the actionMenuItems property.  Names (minus the extension) of items from any of the <system|local|user>/Library/Sounds folders can be used, but the sounds must be .aiff audio files.  Be sure to set the alarmSetting property for the matching initial default.  If using an alarm sound, when the countdown reaches 0 it will repeatedly play and the statusItem will flash until the timer is stopped or restarted.

	• In addition to playing an alarm sound, a user script can be run when the countdown reaches 0.  Although the application is not sandboxed (and AppleScriptObjC can't use NSAppleScriptTask anyway), it still expects scripts to be placed in the user's ~/Library/Application Scripts/<bundle-identifier> folder.  The app/script will create this folder as needed, and it can also be viewed when setting the script.
	      Scripts should be tested with the timer app to pre-approve any permissions.
	      A script can also provide feedback when it completes (otherwise the timer just stops):
	         Returning "quit" will cause the timer application to quit.
	         Returning "restart" will restart the timer (unless using an alarm time, since it will have expired).
	         
	• A preference (optionClick) is included to enable different functionality when option/right-clicking the statusItem.  When true, a handler (doOptionClick) will be called instead of showing the menu.  This can be used for something separate from the menu such as an about panel (default), help/instructions, etc.

	• Save as a stay-open application, and code sign or make the script read-only to keep accessibility permissions.
	• Add a LSUIElement key to the application's Info.plist to make an agent (no app menu or dock tile).
	
	• Multiple timers can be created by making multiple copies of the application with different names and bundle identifiers to keep the title, preferences, and scripts folder separate.

	Finally, note that when running from a script editor, if the script is recompiled, any statusItem left in the menu bar will remain - but will no longer function - until the script editor is restarted.  Also, errors will fail silently, so when debugging you can add beep or try statements, display a dialog, etc.
*)


use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions

# App properties - these are used when running in the Script Editor to access the appropriate user scripts folder.
# The actual application bundle identifiers must be different for multiple copies, and should use the reverse-dns form idPrefix.appName
property idPrefix : "com.yourcompany" -- com.apple.ScriptEditor.id  (or whatever)
property appName : "Menubar Timer" -- also used as a title for the first menu item (disabled)
property version : 3.2

# Cocoa API references
property thisApp : current application
property onState : a reference to thisApp's NSControlStateValueOn -- 1
property offState : a reference to thisApp's NSControlStateValueOff -- 0

# User defaults (preferences)
property colorIntervals : {0.35, 0.15} -- normal-to-caution and caution-to-warning color change percentages
property countdownTime : 3600 -- current countdown time (seconds of the custom or selected countdown time)
property alarmTime : 0 -- current target time (overrides countdownTime if not expired)
property timeSetting : "1 Hour" -- current time setting (from timeMenuItems list) + "Alarm Time…" and "Custom Countdown…"
property alarmSetting : "Basso" -- current alarm setting (from actionMenuItems list) + "Run Script…"
property userScript : "" -- POSIX path to a user script
property optionClick : false -- support statusItem button option/right-click? (see the doOptionClick handler)

# Menu item outlets and settings
property statusItem : missing value -- this will be the status bar item
property statusMenu : missing value -- this will be a menu for the statusItem
property timeMenu : missing value -- this will be a menu of the countdown times
property alarmMenu : missing value -- this will be a menu of the alarm settings
property timer : missing value -- this will be a repeating timer
property attrText : missing value -- this will be an attributed string for the statusItem title
property alarmSound : missing value -- this will be the sound
property timeMenuItems : {"10 Minutes", "30 Minutes", "1 Hour", "2 Hours", "4 Hours"}
property actionMenuItems : {"Basso", "Blow", "Funk", "Glass", "Hero", "Morse", "Ping", "Sosumi", "Submarine"}

# Popover outlets
property positioningWindow : missing value -- this will be a window for the popover's positioning view
property popover : missing value -- this will be the popover
property viewController : missing value -- this will be the view for the current popover controls
property popoverControls : {} -- this will be a list of the current popover controls


# Script properties and globals
property userScriptsFolder : missing value -- where the user scripts are located
property titleFont : missing value -- font used by the statusItem button title
property colorAttributes : missing value -- statusItem text color attributes
property testing : false -- a flag to indicate testing so that preferences are not updated, etc

global countdown -- the current countdown time (seconds)
global |paused| -- a flag for pausing the timer update (note that 'paused' is a Script Debugger term and must be escaped)
global flasher -- a flag used to flash the statusItem button title


##############################
# Main Handlers              #
##############################

on run -- example will run as an app and from a script editor for testing
	if (name of thisApp) contains "Script" then set my testing to true
	if thisApp's NSThread's isMainThread() as boolean then -- app
		initialize()
	else -- running from a script editor
		my performSelectorOnMainThread:"initialize" withObject:(missing value) waitUntilDone:true
	end if
end run

to initialize() -- set up the app/script
	readDefaults()
	setScriptsFolder()
	set {|paused|, flasher} to {true, false}
	set {countdown, my colorAttributes} to {countdownTime, {}}
	repeat with aColor in {(thisApp's NSColor's systemGreenColor), (thisApp's NSColor's systemOrangeColor), (thisApp's NSColor's systemRedColor), (thisApp's NSColor's grayColor)} --  normal, caution, warning, flashing
		set end of my colorAttributes to contents of aColor
	end repeat
	set my titleFont to thisApp's NSFont's fontWithName:"Courier New Bold" |size|:16 -- boldSystemFontOfSize:14
	set my attrText to thisApp's NSMutableAttributedString's alloc's initWithString:""
	attrText's addAttribute:(thisApp's NSFontAttributeName) value:titleFont range:{0, attrText's |length|()}
	buildStatusItem()
	setPopoverStuff()
	my resetCountdown()
end initialize

to performAction() -- do something when the countdown reaches 0
	if alarmSetting is "Run Script…" then
		runScript()
	else
		if alarmSetting is not "Off" and alarmSound is not missing value then alarmSound's play()
		setAttributedTitle(countdown) -- update statusItem title (flash)
	end if
end performAction

to runScript() -- run a script and get the result (if any)
	try
		do shell script "open -g /System/Library/CoreServices/ScriptMonitor.app" -- shows script progress in the menu bar
		set response to (do shell script "osascript -P " & quoted form of userScript) -- better path handling
		if response is in {"quit"} then
			terminate()
		else if response is in {"restart"} and timeSetting is not "Alarm Time…" then
			if timer is not missing value then timer's invalidate() -- use a new timer
			set my timer to missing value
			my startStop:{title:"Start"} -- reset the countdown and continue
		else -- stop the countdown
			my startStop:(missing value)
		end if
	on error errmess number errnum -- script error
		oops for "runScript" given errmess:errmess, errnum:errnum
		my startStop:(missing value) -- stop the countdown
	end try
end runScript

to readDefaults()
	tell standardUserDefaults() of thisApp's NSUserDefaults
		its registerDefaults:{alarmSetting:alarmSetting, colorIntervals:colorIntervals, countdownTime:countdownTime, alarmTime:alarmTime, timeSetting:timeSetting, userScript:userScript, optionClick:optionClick}
		tell (its valueForKey:"AlarmSetting") to if it ≠ missing value then set my alarmSetting to (it as text)
		tell (its valueForKey:"Intervals") to if it ≠ missing value then set my colorIntervals to (it as list)
		tell (its valueForKey:"Countdown") to if it ≠ missing value then set my countdownTime to (it as integer)
		tell (its valueForKey:"AlarmTime") to if it ≠ missing value then set my alarmTime to (it as integer)
		tell (its valueForKey:"TimeSetting") to if it ≠ missing value then set my timeSetting to (it as text)
		tell (its valueForKey:"ScriptPath") to if it ≠ missing value then set my userScript to (it as text)
		tell (its valueForKey:"OptionClick") to if it ≠ missing value then set my optionClick to (it as boolean)
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
		its setValue:(optionClick as boolean) forKey:"OptionClick"
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
# Delegate Handlers          #
##############################

on menuDidClose:_sender
	if optionClick then statusItem's setMenu:(missing value) -- clear menu setting when using option/right-click
end menuDidClose:

on popoverDidClose:_notification
	popoverWindow's |close|()
	set my viewController to missing value
	set my popoverControls to {}
end popoverDidClose:


##############################
# Menu Handlers              #
##############################

to buildStatusItem() -- build the menu bar status item
	buildMenu()
	tell (thisApp's NSStatusBar's systemStatusBar's statusItemWithLength:(thisApp's NSVariableStatusItemLength))
		if optionClick then -- menu is set in in the button action
			its (button's setTarget:me)
			its (button's setAction:"statusItemAction:")
			its (button's sendActionOn:15) -- probably more than needed, but mask combinations act a bit odd
		else
			its setMenu:statusMenu
		end if
		its (button's setFont:titleFont)
		its (button's setTitle:(my formatTime(countdownTime)))
		set my statusItem to it
	end tell
end buildStatusItem

to buildMenu() -- build a menu for the status item
	tell (thisApp's NSMenu's alloc's initWithTitle:"")
		its setDelegate:me -- to handle an option/right-click
		its setAutoenablesItems:false
		my (addMenuItem to it without enable given title:appName) -- show the app name as the first item (disabled)
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Start", action:"startStop:", tag:100)
		my (addMenuItem to it without enable given title:"Pause", action:"pauseContinue:", tag:200)
		my (addMenuItem to it without enable given title:"Reset", action:"resetCountdown")
		my (addMenuItem to it)
		my addTimeMenu(it)
		my addAlarmMenu(it)
		my (addMenuItem to it given title:"Color Intervals…", action:"setIntervals")
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Quit", action:"terminate")
		set my statusMenu to it
	end tell
end buildMenu

to addAlarmMenu(theMenu) -- submenu for the alarm actions
	tell (thisApp's NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		my (addMenuItem to it given title:"Off", action:"setAlarm:", state:(alarmSetting is "Off"))
		my (addMenuItem to it)
		repeat with aName in actionMenuItems -- must be a name from one of the /Library/Sounds/ folders
			set state to alarmSetting is (aName as text)
			my (addMenuItem to it given title:aName, action:"setAlarm:", state:state)
			if state then set my alarmSound to (thisApp's NSSound's soundNamed:aName)
		end repeat
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Run Script…", action:"setAlarm:", state:(alarmSetting is "Run Script…"))
		set my alarmMenu to it
	end tell
	(theMenu's addItemWithTitle:"Action" action:(missing value) keyEquivalent:"")'s setSubmenu:alarmMenu
end addAlarmMenu

to addTimeMenu(theMenu) -- submenu for the countdown times
	tell (thisApp's NSMenu's alloc's initWithTitle:"")
		its setAutoenablesItems:false
		if testing and timeMenuItems does not contain "10 Seconds" then set beginning of timeMenuItems to "10 Seconds"
		repeat with aTitle in timeMenuItems -- must be a value followed by "Seconds", "Minutes", or "Hours"
			my (addMenuItem to it given title:aTitle, action:"setMenuTime:", state:(timeSetting is (aTitle as text)))
		end repeat
		my (addMenuItem to it)
		my (addMenuItem to it given title:"Custom Countdown…", action:"getCustomTime:", state:(timeSetting is "Custom Countdown…"))
		my (addMenuItem to it given title:"Alarm Time…", action:"getAlarmTime:", state:(timeSetting is "Alarm Time…"))
		set my timeMenu to it
	end tell
	(theMenu's addItemWithTitle:"Countdown" action:(missing value) keyEquivalent:"")'s setSubmenu:timeMenu
end addTimeMenu

to setAttributedTitle(theTime) -- set the statusItem button's attributed string title (for colors)
	attrText's replaceCharactersInRange:{0, attrText's |length|()} withString:formatTime(theTime)
	set targetTime to item (((alarmTime > 0 and timeSetting is "Alarm Time…") as integer) + 1) of {countdownTime, alarmTime}
	tell colorIntervals to if theTime > 0 and theTime ≥ ((its first item) * targetTime) then
		attrText's addAttribute:"NSColor" value:(first item of colorAttributes) range:{0, attrText's |length|()} -- normal
	else if theTime > 0 and theTime < ((its first item) * targetTime) and theTime ≥ ((its second item) * targetTime) then
		attrText's addAttribute:"NSColor" value:(second item of colorAttributes) range:{0, attrText's |length|()} -- caution
	else
		attrText's addAttribute:"NSColor" value:(third item of colorAttributes) range:{0, attrText's |length|()} -- warning
		if theTime ≤ 0 then -- alarm time remaining can be < 0
			set flasher to not flasher -- flash the title background when countdown expires
			if not flasher then
				attrText's addAttribute:"NSBackgroundColor" value:(last item of colorAttributes) range:{0, attrText's |length|()}
			else
				attrText's removeAttribute:"NSBackgroundColor" range:{0, attrText's |length|()}
			end if
		end if
	end if
	statusItem's button's setAttributedTitle:attrText
end setAttributedTitle


##############################
# Popover Handlers           #
##############################

to setPopoverStuff()
	set screen to first item of ((thisApp's NSScreen's screens) as list) -- the screen with the menu
	set fullScreen to second item of ((screen's frame) as list)
	tell (thisApp's NSWindow's alloc()'s initWithContentRect:{fullScreen, {116, 24}} styleMask:0 backing:2 defer:true) -- same size as statusItem
		its setReleasedWhenClosed:false
		set my positioningWindow to it -- the popover's positioning window
	end tell
	tell thisApp's NSPopover's alloc's init()
		its setBehavior:(thisApp's NSPopoverBehaviorTransient) -- close when interacting outside the popover
		its setDelegate:me -- for close notification
		set my popover to it
	end tell
end setPopoverStuff

to setPopoverViews for controls given title:title : "", representedObject:representedObject : {}
	set my popoverControls to {}
	set my viewController to thisApp's NSViewController's alloc's init -- new controller
	if representedObject is not missing value then viewController's setRepresentedObject:representedObject
	viewController's setTitle:(title as text)
	tell (thisApp's NSView's alloc's initWithFrame:{{0, 0}, {0, 0}}) -- new view
		viewController's setView:it
		set {maxWidth, maxHeight} to {0, 0}
		repeat with aControl in (controls as list) -- adjust size to fit controls
			set {{originX, originY}, {width, height}} to aControl's frame() as list
			set {newWidth, newHeight} to {originX + width, originY + height}
			if newWidth > maxWidth then set maxWidth to newWidth
			if newHeight > maxHeight then set maxHeight to newHeight
			(viewController's view's addSubview:aControl)
			set klass to thisApp's NSStringFromClass(aControl's |class|()) as text
			set end of my popoverControls to {klass, contents of aControl} -- new list of controls in the order declared
		end repeat
		viewController's view's setFrameSize:{maxWidth + 11, maxHeight + 13} -- extra padding at the ends
		popover's setContentViewController:viewController
		popover's setContentSize:(second item of viewController's view's frame())
	end tell
end setPopoverViews

to buildTimeControls(prompt) -- build the controls for a time popover
	set theTime to item (((prompt is "Countdown") as integer) + 1) of {alarmTime, countdownTime}
	set promptLabel to makeLabel at {15, 50} given stringValue:prompt & ":"
	set datePicker to makeDatePicker at {100, 46} given dimensions:{80, 24}, dateValue:theTime
	set cancelButton to makeButton at {11, 15} given dimensions:{85, 24}, title:"Cancel", action:"timePopover:", keyEquivalent:(character id 27)
	set setButton to makeButton at {100, 15} given dimensions:{85, 24}, title:"Set", action:"timePopover:", keyEquivalent:return
	setPopoverViews for {promptLabel, datePicker, cancelButton, setButton} given title:prompt
end buildTimeControls

to buildScriptControls() -- build the controls for a script popover - returns boolean if successful
	set {current, lexicon} to getUserScripts()
	if current is in {"", missing value} or lexicon is missing value then set my userScript to ""
	if lexicon is missing value then return false -- no scripts found
	if current is in {"", missing value} then set current to "– No script selected –"
	set promptLabel to makeLabel at {15, 50} given stringValue:"Action script:"
	set popup to makePopupButton at {103, 44} given maxWidth:224, itemList:(lexicon's allKeys()) as list, title:current
	set cancelButton to makeButton at {10, 15} given title:"Cancel", action:"scriptPopover:", keyEquivalent:(character id 27)
	set showButton to makeButton at {120, 15} given title:"Show Folder", action:"scriptPopover:"
	set setButton to makeButton at {230, 15} given title:"Set", action:"scriptPopover:", keyEquivalent:return
	setPopoverViews for {promptLabel, popup, cancelButton, showButton, setButton} given representedObject:lexicon -- have the controller retain the dictionary of scripts
	return true -- success
end buildScriptControls

to buildIntervalControls() -- build the controls for an interval popover
	set {cautionValue, warningValue} to colorIntervals
	set cautionLabel to makeLabel at {15, 71} given stringValue:"Caution:  " & cautionValue & "  "
	set warningLabel to makeLabel at {15, 46} given stringValue:"Warning: " & warningValue & "  "
	set cautionSlider to makeSlider at {110, 66} given floatValue:cautionValue, trackColor:(second item of colorAttributes)
	set warningSlider to makeSlider at {110, 41} given floatValue:warningValue, trackColor:(third item of colorAttributes)
	set cancelButton to makeButton at {10, 15} given title:"Cancel", action:"intervalsPopover:", keyEquivalent:(character id 27)
	set defaultsButton to makeButton at {120, 15} given title:"Defaults", action:"intervalsPopover:"
	set setButton to makeButton at {230, 15} given title:"Set", action:"intervalsPopover:", keyEquivalent:return
	setPopoverViews for {cautionLabel, warningLabel, cautionSlider, warningSlider, cancelButton, defaultsButton, setButton}
end buildIntervalControls



##############################
# UI Object Handlers         #
##############################

to makeLabel at origin given stringValue:stringValue : ""
	tell (thisApp's NSTextField's labelWithString:stringValue)
		its setFrameOrigin:origin
		its sizeToFit()
		return it
	end tell
end makeLabel

to makeButton at origin given dimensions:dimensions : {100, 24}, title:title : "Button", action:action : (missing value), keyEquivalent:keyEquivalent : ""
	tell (thisApp's NSButton's buttonWithTitle:title target:me action:action)
		its setFrame:{origin, dimensions}
		if keyEquivalent is not in {"", missing value} then its setKeyEquivalent:keyEquivalent
		return it
	end tell
end makeButton

on makeDatePicker at origin given dimensions:dimensions : {80, 24}, dateValue:dateValue : missing value
	tell (thisApp's NSDatePicker's alloc()'s initWithFrame:{origin, dimensions})
		its setDatePickerStyle:(thisApp's NSDatePickerStyleTextFieldAndStepper)
		its setDatePickerElements:((thisApp's NSDatePickerElementFlagHourMinuteSecond as integer))
		its setBezeled:false
		its setLocale:(thisApp's NSLocale's alloc's initWithLocaleIdentifier:"en_GB") -- for 24-hour
		if dateValue is not missing value then -- AppleScript date is bridged with NSDate
			tell (current date) to set {now, its time} to {it, dateValue as integer}
			its setDateValue:(thisApp's NSDate's dateWithTimeInterval:0 sinceDate:now)
		end if
		return it
	end tell
end makeDatePicker

to makePopupButton at origin given maxWidth:maxWidth : missing value, itemList:itemList : {}, title:title : "", action:action : "updatePopup:"
	if maxWidth < 0 or maxWidth is in {false, missing value} then set maxWidth to 0
	tell (current application's NSPopUpButton's alloc's initWithFrame:{origin, {maxWidth, 25}} pullsDown:true)
		its setLineBreakMode:(thisApp's NSLineBreakByTruncatingMiddle)
		its addItemsWithTitles:itemList
		its insertItemWithTitle:"" atIndex:0 -- placeholder for title
		if title is not "" then its setTitle:title
		if action is not missing value then
			its setTarget:me
			its setAction:(action as text)
		end if
		if maxWidth is 0 then -- auto
			set theSize to width of (its |menu|'s |size| as record)
			its setFrameSize:{theSize + 10, 25} -- adjust for checkmark space
		end if
		return it
	end tell
end makePopupButton

to makeSlider at origin given dimensions:dimensions : {215, 24}, floatValue:floatValue : 0, trackColor:trackColor : missing value, action:action : "updateSlider:"
	tell (current application's NSSlider's sliderWithTarget:me action:action)
		its setFrame:{origin, dimensions}
		its setControlSize:(thisApp's NSControlSizeMini)
		its setContinuous:true -- also its sendActionOn:(thisApp's NSEventMaskLeftMouseUp)
		its setFloatValue:floatValue
		if trackColor is not missing value then its setTrackFillColor:trackColor
		return it
	end tell
end makeSlider


##############################
# Action Handlers            #
##############################

on statusItemAction:sender -- handle option/right-click
	if not optionClick then return
	set eventType to (thisApp's NSApp's currentEvent's |type|) as integer
	if eventType is (thisApp's NSEventTypeLeftMouseDown) as integer then -- normal/left
		statusItem's setMenu:statusMenu -- add menu to button...
		statusItem's button's performClick:me -- ...and click it
	else if eventType is (thisApp's NSEventTypeRightMouseDown) as integer then -- option/right
		doOptionClick()
	end if
end statusItemAction:

to updateCountdown:_sender -- update the statusItem title (called by timer)
	if |paused| then return
	if countdown ≤ 0 then -- alarm time remaining can be < 0
		performAction()
	else
		if alarmTime > 0 and timeSetting is "Alarm Time…" then -- calculate time remaining to alarm
			set countdown to alarmTime - (time of (current date))
		else -- continue countdown
			set countdown to countdown - 1 -- update ≈ 1 second or whenever the UI gets updated
		end if
		setAttributedTitle(countdown)
	end if
end updateCountdown:

to setMenuTime:sender -- update the time menu selection
	set setting to (sender's title) as text
	set interval to (first word of setting) as integer
	if setting contains "Minute" or setting contains "Hour" then set interval to item (((setting contains "Minute") as integer) + 1) of {interval * hours, interval * minutes}
	set my countdownTime to interval mod 86400
	resetTimeMenuState(setting)
end setMenuTime:

to setAlarm:sender -- update the alarm selection
	tell (sender's title as text) to if it is "Run Script…" then -- get alarm script
		if not my buildScriptControls() then return -- no scripts
		my showPopover()
		return -- menu state updated by popover
	else if it is not "Off" then -- set up sound
		set my alarmSound to (thisApp's NSSound's soundNamed:it) -- NSSound works better with the timer
		alarmSound's play() -- sample
	end if
	resetAlarmMenuState((sender's title) as text)
end setAlarm:

to startStop:sender -- (re)set the timer and main menu titles (tags are used for dynamic titles)
	set {|paused|, itemTitle} to {false, ""}
	if sender is not missing value then set itemTitle to (sender's title as text)
	my resetCountdown()
	(statusMenu's itemWithTag:200)'s setTitle:"Pause"
	if itemTitle is "Start" then
		(statusMenu's itemWithTag:100)'s setTitle:"Stop"
		set state to item (((timeSetting is "Alarm Time…") as integer) + 1) of {true, false}
		(statusMenu's itemWithTitle:"Reset")'s setEnabled:state
		(statusMenu's itemWithTag:200)'s setEnabled:state
		statusItem's button's setToolTip:(item (((not state) as integer) + 1) of {"Countdown Remaining", "Time Until Alarm"})
		if timer is not missing value then return
		set my timer to thisApp's NSTimer's timerWithTimeInterval:1 target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true -- restart with new timer
		thisApp's NSRunLoop's mainRunLoop's addTimer:timer forMode:(thisApp's NSDefaultRunLoopMode)
	else
		if alarmSound is not missing value then alarmSound's |stop|()
		(statusMenu's itemWithTitle:"Reset")'s setEnabled:false
		(statusMenu's itemWithTag:100)'s setTitle:"Start"
		(statusMenu's itemWithTag:200)'s setEnabled:false
		if timer is not missing value then timer's invalidate() -- don't leave a timer running
		set my timer to missing value
	end if
end startStop:

to pauseContinue:sender -- pause or continue the countdown
	set itemTitle to sender's title as text
	set |paused| to (item (((itemTitle is "Pause") as integer) + 1) of {false, true})
	sender's setTitle:(item (((itemTitle is "Pause") as integer) + 1) of {"Pause", "Continue"})
end pauseContinue:

to getAlarmTime:_sender -- get an alarm time
	buildTimeControls("Alarm Time")
	showPopover()
end getAlarmTime:

to getCustomTime:_sender -- get a custom countdown
	buildTimeControls("Countdown")
	showPopover()
end getCustomTime:

on timePopover:sender -- handle buttons from the date picker popover
	if ((sender's title) as text) is not "Cancel" then
		set theTime to (time of (((first item of getPopoverControls("NSDatePicker"))'s dateValue) as date))
		tell (popover's contentViewController's title) as text to if it is "Countdown" then
			set my countdownTime to theTime
			my resetTimeMenuState("Custom Countdown…")
		else if it is "Alarm Time" then
			my setAlarmTime(theTime)
		end if
	end if
	tell popover to |close|()
end timePopover:

to updatePopup:sender -- update popup button changes
	sender's setTitle:(sender's titleOfSelectedItem) -- note that there may not always be a selection
end updatePopup:

on scriptPopover:sender -- handle buttons from the popup popover
	tell (sender's title) as text to if it is "Show Folder" then
		tell application "Finder"
			activate
			reveal (userScriptsFolder as POSIX file)
		end tell
	else if it is not "Cancel" then
		set lexicon to popover's contentViewController's representedObject -- dictionary of scripts
		set selected to (title of (first item of my getPopoverControls("NSPopupButton"))) as text
		if selected is not in {"", "– No script selected –"} then -- check for previous setting
			set my userScript to (lexicon's objectForKey:selected) as text
			my resetAlarmMenuState("Run Script…")
		end if
	end if
	tell popover to |close|()
end scriptPopover:

to updateSlider:sender -- update slider changes (not continuous)
	set {cautionLabel, warningLabel, cautionSlider, warningSlider} to getPopoverControls({"NSTextField", "NSSlider"})
	if sender is in {missing value, cautionSlider} then cautionLabel's setStringValue:("Caution:  " & (round (((cautionSlider's floatValue) as real) * 100)) / 100)
	if sender is in {missing value, warningSlider} then warningLabel's setStringValue:("Warning: " & (round (((warningSlider's floatValue) as real) * 100)) / 100)
end updateSlider:

on intervalsPopover:sender -- handle buttons from the slider popover
	set {cautionSlider, warningSlider} to my getPopoverControls("NSSlider")
	tell (sender's title) as text to if it is "Defaults" then
		cautionSlider's setFloatValue:0.35
		warningSlider's setFloatValue:0.15
		my updateSlider:(missing value)
		return -- leave the popover open
	else if it is not "Cancel" then
		set cautionValue to (round (((cautionSlider's floatValue) as real) * 100)) / 100
		set warningValue to (round (((warningSlider's floatValue) as real) * 100)) / 100
		if cautionValue < warningValue then set {cautionValue, warningValue} to {warningValue, cautionValue}
		set my colorIntervals to {cautionValue, warningValue}
	end if
	tell popover to |close|()
end intervalsPopover:


##############################
# Utility Handlers           #
##############################

to showPopover() -- show the popover at the statusItem location
	activate me
	tell positioningWindow
		set location to first item of first item of ((statusItem's button's |window|'s frame) as list) -- x coordinate
		set origin to first item of (its frame as list)
		its setFrameOrigin:{location, second item of origin} -- same as statusItem
		its makeKeyAndOrderFront:me
		popover's showRelativeToRect:(thisApp's NSZeroRect) ofView:(its contentView) preferredEdge:7 -- MinY of bounds
	end tell
end showPopover

to getPopoverControls(controlClasses) -- get all controls from a popover view that match the specified class
	set theControls to {}
	repeat with aControl in popoverControls
		if controlClasses is in {{}, missing value} or first item of aControl is in (controlClasses as list) then set end of theControls to second item of aControl -- items are in the declared order
	end repeat
	return theControls
end getPopoverControls

to setAlarmTime(theSeconds)
	set my alarmTime to theSeconds -- keep the setting regardless
	if (theSeconds - (time of (current date))) < 0 then -- note that the alarm time has passed
		activate me
		display alert "Setting Alarm Time" message "The specified alarm time has been saved, but note that it is earlier than the current time." giving up after 10
	end if
	resetTimeMenuState("Alarm Time…")
end setAlarmTime

to resetCountdown() -- reset the countdown to the current setting (does not stop or reset the timer)
	set {flasher, indx} to {false, ((timeSetting is "Alarm Time…") as integer) + 1}
	set countdown to item indx of {countdownTime, alarmTime}
	statusItem's button's setTitle:formatTime(countdown) -- plain text
	statusItem's button's setImage:(thisApp's NSImage's imageNamed:(item indx of {"NSTouchBarHistoryTemplate", "NSTouchBarAlarmTemplate"}))
	statusItem's button's setToolTip:(item indx of {"Countdown", "Alarm Time"})
end resetCountdown

to resetTimeMenuState(setting) -- (re)set state for a new time menu setting
	(timeMenu's itemWithTitle:timeSetting)'s setState:offState -- old
	set my timeSetting to setting
	my resetCountdown()
	(timeMenu's itemWithTitle:timeSetting)'s setState:onState -- new
	my startStop:(missing value)
end resetTimeMenuState

to resetAlarmMenuState(setting) -- (re)set state for a new alarm menu setting
	(alarmMenu's itemWithTitle:alarmSetting)'s setState:offState -- old
	set my alarmSetting to setting
	(alarmMenu's itemWithTitle:alarmSetting)'s setState:onState -- new
end resetAlarmMenuState

to setIntervals() -- get normal > caution and caution > warning interval percentages (0-1)
	buildIntervalControls()
	showPopover()
end setIntervals

to getUserScripts() -- get user scripts - returns the current name and a dictionary of scripts
	set lexicon to thisApp's NSMutableDictionary's alloc()'s init() -- dictionary of name:posixPath
	set current to missing value
	repeat with anItem in (thisApp's NSFileManager's defaultManager's enumeratorAtURL:(thisApp's NSURL's fileURLWithPath:userScriptsFolder) includingPropertiesForKeys:{"NSURLTypeIdentifierKey"} options:7 errorHandler:(missing value))'s allObjects() -- no directories, package contents, or hidden files
		set {theResult, value} to (anItem's getResourceValue:(reference) forKey:"NSURLTypeIdentifierKey" |error|:(missing value)) -- (NSURLTypeIdentifierKey deprecated in Big Sur)
		if theResult and ((value as text) is "com.apple.applescript.script") then -- only compiled scripts
			set {theName, thePath} to {text 1 thru -6 of (anItem's lastPathComponent as text), (anItem's |path| as text)}
			if thePath is userScript then set current to theName -- name of current script setting
			(lexicon's setObject:thePath forKey:theName)
		end if
	end repeat
	if lexicon's |count|() is 0 then
		activate me
		display alert "Error Finding Scripts" message "No compiled user scripts were found - please place a script in the '" & userScriptsFolder & "' folder and try again." buttons {"Show Folder", "OK"} giving up after 10
		if button returned of result is "Show Folder" then tell application "Finder" to reveal (userScriptsFolder as POSIX file)
		return {missing value, missing value}
	end if
	return {current, lexicon}
end getUserScripts

to doOptionClick() -- handle statusItem button option/right-click
	try -- for debugging
		activate me
		thisApp's NSApp's orderFrontStandardAboutPanel:me -- or whatever
		# Note that this can be called multiple times, so it should check to see if whatever is still running.
	on error errmess number errnum
		oops for "doOptionClick" given errmess:errmess, errnum:errnum, givingUpAfter:5
	end try
end doOptionClick


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

to formatTime(theSeconds) -- return formatted 24 hour string (hh:mm:ss) from the seconds
	if theSeconds < 0 then set theSeconds to 0
	if class of theSeconds is integer then tell "000000" & (10000 * (theSeconds mod days div hours) ¬
		+ 100 * (theSeconds mod hours div minutes) + (theSeconds mod minutes)) ¬
		to return (text -6 thru -5) & ":" & (text -4 thru -3) & ":" & (text -2 thru -1) -- wraps at 24 hours
end formatTime

on oops for theHandler given errmess:errmess, errnum:errnum : "", givingUpAfter:giveUpTime : 0 -- common error dialog
	set handlerText to ""
	if theHandler is not in {"", missing value} then set handlerText to " in the " & quoted form of theHandler & " handler."
	if errnum is not in {"", missing value} then set errnum to " (" & errnum & ")"
	if class of giveUpTime is not integer then set giveUpTime to 0
	activate me
	display alert "Script Error" & handlerText message errmess & errnum giving up after giveUpTime
end oops

