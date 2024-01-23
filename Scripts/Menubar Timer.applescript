
(*
	This script provides a formatted "hh:mm:ss" countdown timer in a menu bar statusItem.  It includes menu items to adjust the countdown or alarm time and action to perform when the countdown expires.  To keep the statusItem title and time settings consistent, the title and countdown/alarm time date pickers use a 24-hour format.  The various timer settings are made from menu selections and a variety of controls in popover dialogs.
	
		• The statusItem title will show a time with an icon and tooltip indicating if it is a countdown or alarm - if set to an alarm, the alarm time is shown when the timer is stopped, but will change to the time remaining when the timer is started.  Note that while the countdown and alarm times both wrap at 24 hours, the countdown time will be from when the timer is started, while the alarm time will only match one time per day.
	
		• While the timer is running, the time remaining is shown in normal (green), caution (orange), and warning (red) colors.  These are from adjustable percentages of the last hour (3600 seconds), or of the countdown setting if it is less than one hour.  The settings can be made with sliders or by choosing a preset from a combo button.
		
		• Preset (menu item) times can be customized by placing the desired items in the list for the timeMenuItems property.  The items must be a value followed by "Hours", "Minutes", or "Seconds" - be sure to set the timeSetting and countdownTime properties for the matching initial default.
	
		• Preset (menu item) sounds can also be customized by placing the desired names in the list for the actionMenuItems property - sounds can be in any of the /Library/Sounds folders, but must have different names.  
		• A property (allSounds) is included to add an alternative to using preset sounds.  When true, sound names (minus extension) will be gathered from the base of all of the /Library/Sounds folders.  These names are searched, sorted, and grouped by system > local > user, with separatorItems between and duplicate items removed.  Be sure to set the alarmSetting property for the matching initial default.  If using an alarm sound, when the countdown reaches 0 it will repeatedly play and the statusItem will flash until the timer is stopped or restarted.
	
		• As an alternative to playing an alarm sound, a user script can be run when the countdown reaches 0.  The system's ScriptMonitor application is also started - this shows a progress statusItem with a gear icon in the menu bar and is and available for the script to use.
		• Although the application is not sandboxed (and AppleScriptObjC can't use NSAppleScriptTask anyway), it still expects scripts to be placed in the user's ~/Library/Application Scripts/<bundle-identifier> folder.  The app/script will create this folder as needed, which can also be revealed when setting the script.
		      Scripts should be tested with the timer app to pre-approve any permissions.
		      A script can also provide feedback when it completes (otherwise the timer just stops):
		         Returning "quit" will cause the timer application to quit.
		         Returning "restart" will restart the timer (unless using an alarm time, since it will have expired).
		         Returning "continue" will let the countdown continue if using alternate actions (experimental).
		         
		• A property (optionClick) is included to enable different functionality when option/right-clicking the statusItem.  When true, a handler (doOptionClick) will be called instead of showing the menu.  This can be used for something separate from the menu such as an about panel (default), help/instructions, etc.
	
		• Save as a stay-open application, and code sign or make the script read-only to keep accessibility permissions.
		• Add a LSUIElement key to the application's Info.plist to make it an agent with no app menu or dock tile (background only).
		
		• Multiple timers are not supported, but multiple applications can be created with different names and bundle identifiers to keep the title, preferences, and script folders separate.
	
		Finally, note that when running from a script editor, if the script is recompiled, any statusItem left in the menu bar will remain - but will no longer function - until the script editor is restarted.  Also, errors will fail silently, so when debugging you can add beep or try statements, display a dialog, etc.
*)


use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions

# App properties - these are used when running in a script editor to access the appropriate user scripts folder.
# The actual application bundle identifiers must be different for multiple copies, and should use the reverse-dns form idPrefix.appName
property idPrefix : "com.yourcompany" -- com.apple.ScriptEditor.id (or whatever)
property appName : "Menubar Timer" -- also used as a title in the first menu item (disabled)
property version : 3.4

# Cocoa API references
property thisApp : current application
property onState : a reference to thisApp's NSControlStateValueOn -- 1
property offState : a reference to thisApp's NSControlStateValueOff -- 0

# User defaults (preferences)
property colorIntervals : {0.35, 0.1} -- normal-to-caution and caution-to-warning color change percentages
property countdownTime : 3600 -- current countdown time (seconds of the custom or selected countdown time)
property alarmTime : 0 -- current target time (overrides countdownTime if not expired)
property timeSetting : "1 Hour" -- current time setting (from timeMenuItems list) + "Custom Countdown…" and "Alarm Time…"
property alarmSetting : "Basso" -- current alarm setting (from actionMenuItems list) + "Off" and "Run Script…"
property userScript : "" -- POSIX path to a user script

# Option settings
property optionClick : false -- support statusItem button option/right-click? -- see the doOptionClick handler
property altActions : false -- experimental support for alternate actions -- see the doAltAction handler
property allSounds : false -- load all available sounds? -- can be a lot!
property testing : false -- a flag to indicate testing so that preferences are not updated, etc

# Menu item outlets and values
property statusItem : missing value -- this will be the status bar item
property statusMenu : missing value -- this will be a menu for the statusItem
property timeMenu : missing value -- this will be a menu of the countdown times
property alarmMenu : missing value -- this will be a menu of the alarm settings
property timer : missing value -- this will be a repeating timer
property attrText : missing value -- this will be an attributed string for the statusItem title
property alarmSound : missing value -- this will be the selected sound

# Presets
property intervalsMenuItems : {{0.35, 0.1}, {0.5, 0.2}, {0.5, 0.166}, {0.25, 0.016}, {1.0, 0.25}} -- percentages
property actionMenuItems : {"Basso", "Blow", "Funk", "Glass", "Hero", "Morse", "Ping", "Sosumi", "Submarine"} -- see allSounds
property timeMenuItems : {"10 Minutes", "30 Minutes", "1 Hour", "2 Hours", "4 Hours"}

# Popover outlets
property positioningWindow : missing value -- this will be a window for the popover's positioning view
property popover : missing value -- this will be the popover
property viewController : missing value -- this will be the view controller and view for the current popover controls
property popoverControls : {} -- this will be a list of the current popover controls

global userScriptsFolder -- where the user scripts are located
global titleFont -- font used by the statusItem button title
global textColors -- statusItem text colors
global countdown -- the current countdown time (seconds)
global isPaused -- a flag for pausing the timer update
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
	set {isPaused, flasher} to {true, false}
	set {countdown, textColors} to {countdownTime, {}}
	if allSounds then getSounds() -- override preset
	tell thisApp's id to set bundleID to item (((it starts with idPrefix) as integer) + 1) of {my filterID(idPrefix & "." & appName), it}
	set userScriptsFolder to POSIX path of ((path to library folder from user domain) as text) & "Application Scripts/" & bundleID & "/"
	thisApp's NSFileManager's defaultManager's createDirectoryAtPath:userScriptsFolder withIntermediateDirectories:true attributes:(missing value) |error|:(missing value)
	repeat with aColor in {(thisApp's NSColor's systemGreenColor), (thisApp's NSColor's systemOrangeColor), (thisApp's NSColor's systemRedColor), (thisApp's NSColor's systemGrayColor)} --  normal, caution, warning, flashing
		set end of my textColors to contents of aColor
	end repeat
	set titleFont to thisApp's NSFont's fontWithName:"Courier New Bold" |size|:16 -- boldSystemFontOfSize:14
	set my attrText to thisApp's NSMutableAttributedString's alloc's initWithString:""
	attrText's addAttribute:(thisApp's NSFontAttributeName) value:titleFont range:{0, attrText's |length|()}
	buildStatusItem()
	setupPopoverStuff()
	my resetCountdown()
end initialize

to doAlarmAction() -- do something when the countdown reaches 0
	if alarmSetting is "Run Script…" then
		try
			runScript for userScript -- alarm script
		on error errmess number errnum -- handle a script error for this handler
			showAlert from "doAlarmAction" for errmess given errnum:errnum
			my startStop:(missing value) -- stop the countdown
		end try
	else
		if alarmSetting is not "Off" and alarmSound is not missing value then alarmSound's play()
		set countdown to countdown - 1 -- continue countdown
		setAttributedTitle(countdown) -- update statusItem title (flash)
	end if
end doAlarmAction

to runScript for posixPath given arguments:arguments : (missing value) -- script should be in the userScriptsFolder
	set args to ""
	if arguments is in {"", {}, missing value} then set arguments to {} -- nothing
	repeat with anItem in (arguments as list) -- prepare arguments for shell script
		set args to args & space & quoted form of (anItem as text)
	end repeat
	do shell script "open -g /System/Library/CoreServices/ScriptMonitor.app" -- shows script progress in the menu bar
	handleResults(do shell script "osascript -P " & quoted form of posixPath & args) -- better error and path handling
end runScript

to handleResults(response) -- handle script results (if any)
	set response to response as text
	if response is "restart" and timeSetting is not "Alarm Time…" then
		if timer is not missing value then timer's invalidate() -- use a new timer
		set my timer to missing value
		my startStop:{title:"Start"} -- reset the countdown and continue
	else if response is "continue" then
		# (experimental) if running a script before the countdown expires
	else if response is "quit" then
		terminate()
	else -- stop the countdown
		set response to missing value
		my startStop:(missing value)
	end if
	return response -- for running a script outside the doAlarmAction handler
end handleResults

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

to terminate() -- used as a selector for the scripting term "quit"
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
# StatusItem Handlers        #
##############################

to buildStatusItem() -- build the menu bar status item
	buildMenu()
	tell (thisApp's NSStatusBar's systemStatusBar's statusItemWithLength:(thisApp's NSVariableStatusItemLength))
		if optionClick then -- menu will be set in in the button action
			its (button's setTarget:me)
			its (button's setAction:"statusItemAction:")
			its (button's sendActionOn:15) -- probably more than needed, but mask combinations act different
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
		my (addMenuItem to it without enable given title:appName) -- show the app name for identification
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
		my (addMenuItem to it given title:"Run Script…", action:"setAlarm:", state:(alarmSetting is "Run Script…"))
		my (addMenuItem to it)
		repeat with aName in actionMenuItems -- placed at the end since sounds may extend the menu off the screen
			if aName is "" then -- separator
				my (addMenuItem to it)
			else -- must be the name of a sound file
				set state to alarmSetting is (aName as text)
				my (addMenuItem to it given title:aName, action:"setAlarm:", state:state)
				if state then set my alarmSound to (thisApp's NSSound's soundNamed:aName)
			end if
		end repeat
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
		my (addMenuItem to it given title:"Custom Countdown…", action:"getTime:", state:(timeSetting is "Custom Countdown…"))
		my (addMenuItem to it given title:"Alarm Time…", action:"getTime:", state:(timeSetting is "Alarm Time…"))
		set my timeMenu to it
	end tell
	(theMenu's addItemWithTitle:"Countdown" action:(missing value) keyEquivalent:"")'s setSubmenu:timeMenu
end addTimeMenu

to setAttributedTitle(theTime) -- set the statusItem button's attributed string title (for colors)
	attrText's replaceCharactersInRange:{0, attrText's |length|()} withString:formatTime(theTime)
	set targetTime to item (((timeSetting is "Alarm Time…" or countdownTime > 3600) as integer) + 1) of {countdownTime, hours} -- or 2*hours, etc - fixed time removes vagueness for alarms
	tell colorIntervals to if theTime > 0 and theTime ≥ ((its first item) * targetTime) then
		attrText's addAttribute:"NSColor" value:(first item of textColors) range:{0, attrText's |length|()} -- normal
	else if theTime > 0 and theTime < ((its first item) * targetTime) and theTime ≥ ((its second item) * targetTime) then
		attrText's addAttribute:"NSColor" value:(second item of textColors) range:{0, attrText's |length|()} -- caution
	else
		attrText's addAttribute:"NSColor" value:(third item of textColors) range:{0, attrText's |length|()} -- warning
		if theTime ≤ 0 then -- alarm time remaining can be < 0
			set flasher to not flasher -- flash the title background when countdown expires
			if not flasher then
				attrText's addAttribute:"NSBackgroundColor" value:(last item of textColors) range:{0, attrText's |length|()}
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

to setupPopoverStuff()
	tell (thisApp's NSWindow's alloc()'s initWithContentRect:{{0, 0}, {116, 24}} styleMask:0 backing:2 defer:true)
		its setReleasedWhenClosed:false
		its setAlphaValue:0.0 -- transparent
		set my positioningWindow to it -- borderless window same size as statusItem
	end tell
	tell thisApp's NSPopover's alloc's init()
		its setBehavior:(thisApp's NSPopoverBehaviorTransient) -- close when interacting outside the popover
		its setDelegate:me -- for close notification
		set my popover to it
	end tell
end setupPopoverStuff

to setPopoverViews for controls given title:title : "", representedObject:representedObject : {}
	set my popoverControls to {}
	set my viewController to thisApp's NSViewController's alloc's init -- new controller
	if representedObject is not missing value then viewController's setRepresentedObject:representedObject
	viewController's setTitle:(title as text)
	tell (thisApp's NSView's alloc's initWithFrame:{{0, 0}, {0, 0}}) -- view for controls
		viewController's setView:it
		set {maxWidth, maxHeight} to {0, 0}
		repeat with aControl in (controls as list) -- find maximum size to fit controls
			set {{originX, originY}, {width, height}} to aControl's frame() as list
			set {newWidth, newHeight} to {originX + width, originY + height}
			if newWidth > maxWidth then set maxWidth to newWidth
			if newHeight > maxHeight then set maxHeight to newHeight
			(viewController's view's addSubview:aControl)
			set klass to thisApp's NSStringFromClass(aControl's |class|()) as text
			set end of my popoverControls to {klass, contents of aControl} -- new list of controls in the order declared
		end repeat
		its setFrameSize:{maxWidth + 11, maxHeight + 13} -- extra padding at the ends
		popover's setContentSize:(second item of its frame())
	end tell
	popover's setContentViewController:viewController
end setPopoverViews

to showPopover() -- show the popover at the statusItem location
	set screen to first item of ((thisApp's NSScreen's screens) as list) -- the screen with the menu
	set {screenX, screenY} to second item of ((screen's frame) as list) -- screen size
	set {buttonX, buttonY} to first item of ((statusItem's button's |window|'s frame) as list) -- button origin
	activate me
	tell positioningWindow
		its setFrameOrigin:{buttonX, screenY} -- off top edge so that popover aligns with menu bar
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

to buildTimeControls(setting) -- build the controls for a time popover
	set theTime to item (((setting is "Countdown") as integer) + 1) of {alarmTime, countdownTime}
	set promptLabel to makeLabel at {15, 50} given stringValue:setting & ":"
	set datePicker to makeDatePicker at {100, 46} given dimensions:{80, 24}, dateValue:theTime
	set cancelButton to makeButton at {11, 15} given dimensions:{85, 24}, title:"Cancel", action:"timePopover:", keyEquivalent:(character id 27)
	set setButton to makeButton at {100, 15} given dimensions:{85, 24}, title:"Set", action:"timePopover:", keyEquivalent:return
	setPopoverViews for {promptLabel, datePicker, cancelButton, setButton} given title:setting
end buildTimeControls

to buildScriptControls() -- build the controls for a script popover - returns boolean for success
	set {current, lexicon} to getUserScripts()
	if current is in {"", missing value} or lexicon is missing value then set my userScript to ""
	if lexicon is missing value then return false -- no scripts found
	if current is in {"", missing value} then set current to "– No script selected –"
	set promptLabel to makeLabel at {15, 50} given stringValue:"Action script:"
	set popup to makePopupButton at {103, 44} given itemList:(lexicon's allKeys()) as list, title:current
	set cancelButton to makeButton at {10, 15} given title:"Cancel", action:"scriptPopover:", keyEquivalent:(character id 27)
	set showButton to makeButton at {120, 15} given title:"Show Folder", action:"scriptPopover:"
	set setButton to makeButton at {230, 15} given title:"Set", action:"scriptPopover:", keyEquivalent:return
	setPopoverViews for {promptLabel, popup, cancelButton, showButton, setButton} given representedObject:lexicon -- have the controller retain the dictionary of scripts
	return true -- success
end buildScriptControls

to buildIntervalControls() -- build the controls for an interval popover
	set {cautionValue, warningValue} to colorIntervals
	set cautionLabel to makeLabel at {15, 71} given stringValue:"Caution: " & formatFloat(cautionValue) & " "
	set warningLabel to makeLabel at {15, 46} given stringValue:"Warning: " & formatFloat(warningValue) & " "
	set cautionSlider to makeSlider at {115, 66} given floatValue:cautionValue, trackColor:(second item of textColors)
	set warningSlider to makeSlider at {115, 41} given floatValue:warningValue, trackColor:(third item of textColors)
	set cancelButton to makeButton at {10, 15} given title:"Cancel", action:"intervalPopover:", keyEquivalent:(character id 27)
	set defaultsButton to makeComboButton at {120, 15} for intervalsMenuItems given title:"Presets"
	set setButton to makeButton at {230, 15} given title:"Set", action:"intervalPopover:", keyEquivalent:return
	setPopoverViews for {cautionLabel, warningLabel, cautionSlider, warningSlider, cancelButton, defaultsButton, setButton}
end buildIntervalControls


##############################
# Action Handlers            #
##############################

# Be careful if using multiple editors - "type" is a term in Script Debugger, but Script Editor will remove any escaping
on statusItemAction:_sender -- handle option/right-click
	if not optionClick then return
	set eventType to (thisApp's NSApp's currentEvent's |type|) as integer -- pay attention to the escaping for "type"
	if eventType is (thisApp's NSEventTypeLeftMouseDown) as integer then -- normal/left
		statusItem's setMenu:statusMenu -- add menu to button...
		statusItem's button's performClick:me -- ...and click it
	else if eventType is (thisApp's NSEventTypeRightMouseDown) as integer then -- option/right
		doOptionClick()
	end if
end statusItemAction:

to updateCountdown:_sender -- update the statusItem title and check countdown (repeatedly called by timer)
	if isPaused then return
	if altActions then -- do something else for a specific condition (experimental)
		if doAltActions() then return -- the handler returns a boolean to exit the handler (or not)
	end if
	if countdown ≤ 0 then -- countdown can be < 0
		doAlarmAction()
		return
	else
		if alarmTime > 0 and timeSetting is "Alarm Time…" then -- calculate time remaining to alarm
			set countdown to alarmTime - (time of (current date)) -- can be well below 0
			if countdown < 0 then set countdown to 0 -- indicate expired
		else -- continue countdown
			set countdown to countdown - 1 -- about 1 second when the UI is allowed to update
		end if
		setAttributedTitle(countdown)
	end if
end updateCountdown:

to setMenuTime:sender -- update the time menu selection
	set setting to (sender's title as text)
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
	resetAlarmMenuState(sender's title as text)
end setAlarm:

to startStop:sender -- (re)set the timer and main menu titles (tags are used for dynamic titles)
	set {isPaused, itemTitle} to {false, ""}
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
	set itemTitle to (sender's title as text)
	set isPaused to item (((itemTitle is "Pause") as integer) + 1) of {false, true}
	sender's setTitle:(item (((itemTitle is "Pause") as integer) + 1) of {"Pause", "Continue"})
end pauseContinue:

to getTime:sender -- get alarm or countdown time
	set setting to item ((((sender's title as text) begins with "Alarm") as integer) + 1) of {"Countdown", "Alarm Time"}
	buildTimeControls(setting)
	showPopover()
end getTime:

on timePopover:sender -- handle buttons from the date picker popover
	if (sender's title as text) is not "Cancel" then
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
	tell (sender's title as text) to if it is "Show Folder" then
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

to updateSlider:sender -- update slider changes
	set {cautionLabel, warningLabel, cautionSlider, warningSlider} to getPopoverControls({"NSTextField", "NSSlider"})
	if sender is in {missing value, cautionSlider} then cautionLabel's setStringValue:("Caution: " & formatFloat(cautionSlider's floatValue))
	if sender is in {missing value, warningSlider} then warningLabel's setStringValue:("Warning: " & formatFloat(warningSlider's floatValue))
end updateSlider:

to updateIntervals:sender -- update sliders to combo button selection
	set {cautionSlider, warningSlider} to my getPopoverControls("NSSlider")
	set newIntervals to item (sender's tag) of intervalsMenuItems
	cautionSlider's setFloatValue:(first item of newIntervals)
	warningSlider's setFloatValue:(second item of newIntervals)
	my updateSlider:(missing value)
end updateIntervals:

on intervalPopover:sender -- handle buttons from the slider popover
	if (sender's title as text) is not "Cancel" then
		set {cautionSlider, warningSlider} to my getPopoverControls("NSSlider")
		set cautionValue to formatFloat(cautionSlider's floatValue) as real
		set warningValue to formatFloat(warningSlider's floatValue) as real
		if cautionValue < warningValue then set {cautionValue, warningValue} to {warningValue, cautionValue}
		set my colorIntervals to {cautionValue, warningValue}
	end if
	tell popover to |close|()
end intervalPopover:


##############################
# Utility Handlers           #
##############################

to setAlarmTime(theSeconds)
	set my alarmTime to theSeconds -- keep the setting regardless
	if (theSeconds - (time of (current date))) < 0 then -- note that the alarm time has passed
		activate me
		display alert "Setting Alarm Time" message "The specified alarm time has been saved, but note that it is earlier than the current time." giving up after 10
	end if
	resetTimeMenuState("Alarm Time…")
end setAlarmTime

to resetCountdown() -- reset the countdown to the current setting (does not stop a timer)
	attrText's removeAttribute:"NSBackgroundColor" range:{0, attrText's |length|()}
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
	repeat with anItem in ((thisApp's NSFileManager's defaultManager's enumeratorAtURL:(thisApp's NSURL's fileURLWithPath:userScriptsFolder) includingPropertiesForKeys:{"NSURLTypeIdentifierKey"} options:7 errorHandler:(missing value))'s allObjects()) -- no directories, package contents, or hidden files
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

to getSounds() -- get sound names from the system, local, and user sound libraries (NSSearchPathDomainMask of 11)
	tell thisApp's NSMutableArray to set {soundList, subList} to {its alloc's init(), its alloc's init()}
	set libraries to (thisApp's NSSearchPathForDirectoriesInDomains(thisApp's NSLibraryDirectory, 11, true))'s objectEnumerator()
	repeat with libraryPath in reverse of ((allObjects of libraries) as list)
		repeat with anItem in ((thisApp's NSFileManager's defaultManager)'s enumeratorAtURL:(thisApp's NSURL's fileURLWithPath:((thisApp's NSString's stringWithString:libraryPath)'s stringByAppendingPathComponent:"Sounds")) includingPropertiesForKeys:(missing value) options:7 errorHandler:(missing value))'s allObjects() -- no directories, package contents, or hidden files
			set anItem to (anItem's |path|)'s lastPathComponent
			if (anItem's pathExtension) as text is not in {"", missing value} then (subList's addObject:(anItem's stringByDeletingPathExtension as text))
		end repeat
		(subList's removeObjectsInArray:soundList) -- remove names if already in the list
		if (subList's |count|()) as integer is not 0 then
			(subList's setArray:(subList's sortedArrayUsingSelector:"compare:"))
			(subList's addObject:"") -- indicate a separatorItem
			(soundList's addObjectsFromArray:subList)
			subList's removeAllObjects()
		end if
	end repeat
	set my actionMenuItems to soundList as list
end getSounds


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
		its setFont:(current application's NSFont's fontWithName:"Menlo" |size|:12)
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

to makePopupButton at origin given maxWidth:maxWidth : 224, itemList:itemList : {}, title:title : "", action:action : "updatePopup:"
	if maxWidth < 0 or maxWidth is in {false, missing value} then set maxWidth to 0
	tell (thisApp's NSPopUpButton's alloc's initWithFrame:{origin, {maxWidth, 25}} pullsDown:true)
		its setLineBreakMode:(thisApp's NSLineBreakByTruncatingMiddle)
		its addItemsWithTitles:itemList
		its insertItemWithTitle:"" atIndex:0 -- placeholder for title
		if title is not "" then its setTitle:title
		if action is not missing value then
			its setTarget:me
			its setAction:(action as text)
		end if
		return it
	end tell
end makePopupButton

to makeSlider at origin given dimensions:dimensions : {210, 24}, floatValue:floatValue : 0, trackColor:trackColor : missing value, action:action : "updateSlider:"
	tell (thisApp's NSSlider's sliderWithTarget:me action:action)
		its setFrame:{origin, dimensions}
		its setControlSize:(thisApp's NSControlSizeMini)
		its setContinuous:true -- also its sendActionOn:(thisApp's NSEventMaskLeftMouseUp)
		its setFloatValue:floatValue
		if trackColor is not missing value then its setTrackFillColor:trackColor
		return it
	end tell
end makeSlider

on makeComboButton at origin for menuItems given dimensions:dimensions : {100, 24}, title:title : "Button", action:action : "updateIntervals:"
	tell (thisApp's NSMenu's alloc's initWithTitle:"")
		set {tag, menuTitles} to {0, {}}
		my (addMenuItem to it without enable given title:"Caution  Warning") -- title/header entry
		repeat with anItem in menuItems
			if class of anItem is list and contents of anItem is not {} then
				set tag to tag + 1 -- used as an index into the intervalsMenuItems list
				tell anItem to set anItem to " " & my formatFloat(item 1) & "    " & my formatFloat(item 2)
			end if
			my (addMenuItem to it given title:anItem, action:action, tag:tag)
		end repeat
		set menuActions to it
	end tell
	tell (thisApp's NSComboButton's comboButtonWithTitle:title |menu|:menuActions target:me action:(missing value))
		its setFrame:{origin, dimensions}
		its setStyle:1
		its setFont:(thisApp's NSFont's fontWithName:"Menlo" |size|:12) -- fixed width for formatting
		return it
	end tell
end makeComboButton


##############################
# General-purpose Handlers   #
##############################

to addMenuItem to theMenu given title:title : (missing value), action:action : (missing value), theKey:theKey : "", tag:tag : (missing value), enable:enable : (missing value), state:state : (missing value) -- given parameters are optional
	if title is in {"", missing value} then return theMenu's addItem:(current application's NSMenuItem's separatorItem)
	tell (theMenu's addItemWithTitle:title action:action keyEquivalent:theKey)
		if action is not missing value then its setTarget:me -- target will only be this script
		if tag is not missing value then its setTag:(tag as integer)
		if enable is not missing value then its setEnabled:(item (((enable is false) as integer) + 1) of {true, false})
		if state is not missing value then its setState:(item (((state is true) as integer) + 1) of {0, 1})
		return it
	end tell
end addMenuItem

to formatTime(theSeconds) -- return formatted 24 hour string (hh:mm:ss) from the seconds
	if theSeconds < 0 then set theSeconds to 0
	if class of theSeconds is integer then tell "000000" & (10000 * (theSeconds mod days div hours) ¬
		+ 100 * (theSeconds mod hours div minutes) + (theSeconds mod minutes)) ¬
		to return (text -6 thru -5) & ":" & (text -4 thru -3) & ":" & (text -2 thru -1) -- wraps at 24 hours
end formatTime

to formatFloat(float) -- format a floating point number, rounding away from 0
	tell current application's NSNumberFormatter's alloc's init()
		its setMinimumFractionDigits:3
		return its stringFromNumber:float
	end tell
end formatFloat

to filterID(candidate) -- filter a bundle ID to only lower case allowed characters
	set {theResult, charList} to {{}, characters of "-.etaoinshrdlucmfwgypbvkxjqz0123456789"} -- letters in frequency order
	repeat with aChar in (get characters of candidate)
		set output to "-" -- substitution character
		tell (contents of aChar) to if it is in charList then repeat with indx from 1 to 38 -- (count charList)
			set match to contents of (item indx of charList)
			if it is match then -- ignores case
				set output to match
				exit repeat
			end if
		end repeat
		set end of theResult to output
	end repeat
	return theResult as text
end filterID

to showAlert from aHandler for errmess given errnum:errnum : "", givingUpAfter:giveUpTime : 0 -- common error dialog
	set handlerText to ""
	if aHandler is not in {"", missing value} then set handlerText to " in the " & quoted form of aHandler & " handler."
	if errnum is not in {"", missing value} then set errnum to " (" & errnum & ")"
	if class of giveUpTime is not integer then set giveUpTime to 0 -- no giveUp if < 1
	activate me
	display alert "Script Error" & handlerText message errmess & errnum giving up after giveUpTime
end showAlert


##############################
# User Handlers              #
##############################

to doOptionClick() -- handle a statusItem button option/right-click
	try
		activate me
		thisApp's NSApp's orderFrontStandardAboutPanel:me -- or whatever
		# Note that this can be called multiple times, so it should check to see if whatever is still running.
	on error errmess number errnum
		showAlert from "doOptionClick" for errmess given errnum:errnum, givingUpAfter:5
	end try
end doOptionClick

to doAltActions() -- experimental support for user actions - repeatedly called by updateCountdown if altActions is true
	try -- condition expression should be specific - return true to exit the current update
		if countdown is -(10 * minutes) then -- example #1: check for a negative value (still running and late)
			display notification "Reminder: The countdown expired 10 minutes ago." with title appName sound name (some item of actionMenuItems) -- whatever - note that notifications for the script editor will need to be enabled
		end if
		if countdown is 5 then -- example #2: run a script at a specific countdown
			# if (runScript for userScript given arguments:countdown) is in {missing value, "restart"} then return true
			# note that the userScript property contains the POSIX path of the (saved) alarm script in the userScriptsFolder
		end if
	on error errmess number errnum -- handle a script or other error for this handler
		showAlert from "doAltActions" for errmess given errnum:errnum
		my startStop:(missing value) -- stop the countdown
		return true -- exit current update
	end try
	return false -- don't exit (default)
end doAltActions

