
(*
This script uses NSTimer to implement a repeating timer to count down seconds, and provides a formatted "hh:mm:ss" indication of time remaining in a NSStatusItem in the system menu bar, which includes a menu with items to adjust the duration or alarm time and an action to perform when the countdown expires.  Timer settings can be selected from preset menu items or set from NSDatePicker controls presented in popover dialogs (all settings and displays use a 24-hour format).  There are countdown mode settings for looping/repeating, a floating timer window, and for a countdown that can be paused or checks against the time it was started - note that NSTimer is not an exact real-time mechanism.

	• The status item title will show a countdown time with an icon and tooltip indicating if it is a duration or alarm time - the time setting will be shown when the timer is stopped, and will change to the time remaining when the timer is started.  The duration and alarm times both wrap at 24 hours, with the duration being from when the timer is started, while the alarm time will only match one time per day.
	• When the countdown reaches 0, the status item title will flash and a sound (if set) will play.  The script will then proceed according to the action setting and mode - if "Loop" mode is set, the countdown will automatically restart, otherwise if a sound has been set the flash and sound will continue until the timer is manually stopped or restarted, or if a script has been set it will be run (see below).  Loop mode is not saved, and is mutually exclusive of a "Run Script" action.

	• An optional floating window provides the same information and menu as the status item, only with a larger countdown display.  Unlike the loop and count modes, it can be turned on and off while the countdown is running.  An application will save the last timer window location, but there is also an alternate menu item to reset the window location to its initial location under the status item menu.

	• While the timer is running, the time remaining is shown in normal (green), caution (orange), and warning (red) colors.  These are determined from adjustable percentages of the time setting or the intervalThreshold (default 3600 seconds/1 hour), whichever is less.  A property (colorBackground) is also provided to color the background instead of the text in the optional timer window's textField.
	• Normal-to-caution and caution-to-warning interval settings can be made with sliders or by choosing from a "Presets" combo button (if available, otherwise the "Default" button will use the first item in the intervalMenuItems list).  Setting a percentage to zero will disable that color, and setting both to zero will disable all colors.

	• Preset times (menu item) can be customized by placing the desired items in the list for the timeMenuItems property.  These items must be a number followed by "Hours", "Minutes", or "Seconds" - set the timeSetting and durationTime properties for the matching initial default as desired.
	• If running in a script editor, a "10 Seconds" menu item will be added to the beginning of the list (for testing), unless that value already exists.
	• A custom duration setting that has the same value as one of the time menu items will select that item instead.
	• If you are running macOS 13.0 Ventura or later, the previous 5 alarm times and custom durations are available in a NSComboButton in the respective popover.  New and reused settings are placed at the top of the list before trimming.

	• Preset sounds (menu item) can also be customized by placing the desired names in the list for the actionMenuItems property - sounds can be in any of the /Library/Sounds folders, but should have different names, otherwise user sounds will have precedence.  The default preset is a select set of names from the standard system sounds, which are available in all current versions of macOS.  Set the actionSetting property for the matching initial default as desired.
	• Any sounds included in a script application's bundle in the /Contents/Resources/Sounds folder will also be added to the action menu - to avoid clashes with sounds that have the same name, the bundle names can contain invisible characters such as a zero width space (character id 8203, UTF-16 U+200B, UTF-8 0xE2 0x80 0x8B).
	• A property (allSounds) is used to choose an alternative to using preset/bundle sounds.  When true, sound names (minus extension) will be gathered from the base of all of the /Library/Sounds folders.  These names are sorted and grouped by system > local > user, with separator items and headers used between sections.  Duplicate names (e.g. different extensions) in a group will be removed.  Sound names that are already in system or local sound folders will also be removed, as user sounds will have precedence.
	• Pausing on the menu item for a sound will play a sample.
	• The Menubar Timer can also be metronome(ish) by setting the time to zero and using a short sound action (1 second or less for best results).

	• As an alternative to playing a sound, a user script can be run when the countdown reaches 0 - note that loop mode will be reset and the menu item disabled when a script is selected.  The script will be run using the osascript command after launching ScriptMonitor.app, which is a shared system application that shows a NSStatusItem with an animated gear icon in the menu bar, and is typically used for Script Menu items and Automator workflows.  Its entries contain a cancel button and may include progress (for example, completed workflow actions or if a script uses the built-in progress statements).
	• Although the application is not sandboxed (and AppleScriptObjC can't use NSUserAppleScriptTask's completion handler anyway), it still requires the scripts to be placed in the user's ~/Library/Application Scripts/<bundle-identifier> folder.  The app/script will create this folder as needed, which can also be revealed from the script setting popover.
	◆ Scripts can be AppleScript or JavaScript for Automation (JXA) .scpt files.
	◆ Scripts should be tested with the timer app to pre-approve any permissions.
	◆ The current countdown (seconds) is passed to scripts, and they can provide feedback to the timer app when they complete (otherwise the timer just stops):
		▫︎ Returning "quit" will cause the Menubar Timer application to quit.
		▫︎ Returning "restart" will restart the timer (unless using an alarm time, since it will have expired).
		▫︎ Returning "continue" will let the countdown continue if using alternate actions (experimental).

	• A property (optionClick) is included to enable different functionality when option/right-clicking the status item.  When true, a handler (doOptionClick) will be called instead of showing the menu.  This can be used for something separate from the menu such as an about panel (default), help/instructions, etc.

	• To make into an application, save as stay-open and code sign or make the script read-only to keep accessibility permissions.
	• If saved as an application there is no preferences dialog, but settings are kept from the various menu selections.  For rarely-used settings such as intervalThreshold and allSounds, the defaults shell command can be used.
	• If desired, add a LSUIElement key to the application's Info.plist to make it an agent with no app menu or dock tile (background).  The /Applications/Utilities/Activity Monitor.app can be used to quit invisible or background applications, but note that system processes should be left alone unless you really know what you are doing.

	• Multiple timers are not supported, but multiple applications can be created with different names and bundle identifiers to keep the title, preferences, and script folders separate (the appName property is used as the first menu item and timer window title).

	• AppKit classes used include the controls NSButton, NSComboButton, NSDatePicker, NSMenu, NSMenuItem, NSPopover, NSPopupButton, NSSlider, NSStatusBar, NSStatusItem, NSTextField, NSView, NSViewController, and NSWindow, with other UI items NSColor, NSEvent, NSScreen, and NSSound.  Foundation classes include NSDate, NSFileManager, NSMutableArray, NSMutableAttributedString, NSMutableDictionary, NSOrderedSet, NSTimer, and NSUserDefaults.

Finally, note that when running in a script editor, if the script is recompiled, previous statusItems left in the menu bar will remain (but will no longer function) until the script editor is restarted.  Also, errors may fail silently, so when debugging you can add say, beep, or try statements to display a dialog, etc.
*)


use AppleScript version "2.7" -- High Sierra (10.13) or later for newer enumerations and NSRect bridging to a list
use framework "Foundation"
use scripting additions

property |+| : current application -- just a shortcut (that it looks like a first aid kit is merely a coincidence)

# App properties - these are used when running in a script editor to access the appropriate user scripts folder.
# The app bundle identifier must be unique for multiple instances, and should use the reverse-dns form idPrefix.appName
property appName : "Menubar Timer" -- also used as the title for the timer window and the (disabled) first menu item
property idPrefix : "com.your-company" -- com.apple.ScriptEditor.id (or whatever)
property version : "3.17" -- macOS 13 Ventura or later for NSComboButton (alternate should run in earlier versions)

-->> User Defaults (persistent app preferences)
property actionSetting : "Basso" -- current action setting (from actionMenuItems list + "Off" and "Run Script…")
property alarmHistory : {} -- previous 5 alarm time settings
property alarmTime : 0 -- current target time-of-day (seconds)
property allSounds : false -- load sounds from all libraries instead of app/preset
property clockMode : true -- calculate from the time started vs a manual countdown when not paused
property colorBackground : false -- use interval colors for textField background instead of text
property colorIntervals : {0.35, 0.1} -- normal-to-caution and caution-to-warning color change percentages
property durationHistory : {} -- previous 5 custom duration settings
property durationTime : 3600 -- current countdown duration (seconds of the custom or selected duration)
property intervalThreshold : 3600 -- threshold before using the colorInterval percentages
property scriptPath : "" -- POSIX path to a user script
property timeSetting : "1 Hour" -- current time setting (from timeMenuItems list + "Custom Duration…" and "Alarm Time…")

-->> Option Settings
property altActions : false -- experimental support for alternate actions -- see the `doAltAction` handler
property optionClick : true -- support statusItem button option/right-click -- see the `doOptionClick` handler

-->> Menu Item Outlets
property actionMenu : missing value -- this will be a menu of the actions
property actionSound : missing value -- this will be the selected sound
property attrButtonText : missing value -- this will be an attributed string (font, color, etc) for the statusItem button
property buttonFont : missing value -- this will be the font used by the statusItem button title
property statusItem : missing value -- this will be the status bar item
property statusMenu : missing value -- this will be a menu for the statusItem
property timeMenu : missing value -- this will be a menu of the times
property timer : missing value -- this will be a repeating timer

-->> Popover Outlets
property popover : missing value -- this will be a popover for the various settings
property popoverControls : {} -- this will be a list of the current popover controls {control class, control}
property positioningWindow : missing value -- this will be a 1 point high window to position the popover
property viewController : missing value -- this will be the view controller and view for the current popover controls

--» Window Outlets
property attrWindowText : missing value -- this will be an attributed string (font, color, etc) for the window textField
property timerWindow : missing value -- this will be a supplementary window for the timer display
property titlebarController : missing value -- this will be a view controller for the window's titlebar image
property windowLabelField : missing value -- this will be a label text field in the window
property windowFont : missing value -- this will be the font used by the window textField

-->> Preset Values
property actionMenuItems : {"Basso", "Blow", "Funk", "Glass", "Hero", "Morse", "Ping", "Purr", "Sosumi", "Submarine"}
property bundleSounds : {} -- this will be a list of instances for any sounds from the application bundle
property intervalMenuItems : {{0.35, 0.1}, {0.5, 0.2}, {0.5, 0.166}, {0.25, 0.016}, {1.0, 0.25}} -- color change percentages
property soundExtensions : {"aac", "aiff", "m4a", "m4r", "mp3", "mp4", "wav"} -- acceptable sound file extensions
property soundTimeout : 0 -- seconds to discontinue alarm sound (0 to disable) - statusItem will still flash
property timeMenuItems : {"10 Minutes", "30 Minutes", "1 Hour", "2 Hours", "4 Hours"}

-->> Globals
global countdown -- the current countdown time (seconds)
global flashing -- a flag to flash the statusItem button title
global looping -- a flag indicating loop mode
global menuTimes -- a list of records for time menu item comparisons {menuTitle:title, itemSeconds:seconds}
global pausing -- a flag to pause the timer update
global standardColors -- a record of text and background colors
global showWindow -- a flag indicating to also show a (larger) timer window on the desktop
global soundSample -- a record for playing sound samples {instance:NSSound, timer:NSTimer}
global targetTime -- the duration timeout based on the countdown starting time (seconds) - see `clockMode` property
global textColors -- a record of statusItem text colors for the interval percentages
global userScriptsFolder -- where the user scripts are located
global usingEditor -- a flag to indicate running in a script editor


##############################
-->> Main Handlers
##############################

on run
	if |+|'s NSThread's isMainThread() as boolean then -- stay-open app
		initialize()
	else -- running in a script editor
		my performSelectorOnMainThread:"initialize" withObject:(missing value) waitUntilDone:true
	end if
end run

to initialize()
	set usingEditor to (name of |+|) is in {"Script Editor", "Script Debugger"}
	if not usingEditor then readDefaults() -- no preferences if running in a script editor
	getSounds()
	set soundSample to {instance:(missing value), timer:(missing value)} -- sample template
	set {pausing, flashing} to {true, false}
	set {countdown, menuTimes} to {durationTime, {}}
	set {looping, showWindow} to {false, false} -- loop and timer window modes are temporary
	tell (|+|'s id) as text to set bundleID to item ((((it begins with idPrefix) or (text 1 thru -2 of it is in {"com.apple.ScriptEditor", "com.latenightsw.ScriptDebugger"})) as integer) + 1) of {it, my filterID(idPrefix & "." & appName)} -- application bundle identifier (except script editors) or from the above app property settings
	set userScriptsFolder to POSIX path of ((path to library folder from user domain) as text) & "Application Scripts/" & bundleID & "/"
	|+|'s NSFileManager's defaultManager's createDirectoryAtPath:userScriptsFolder withIntermediateDirectories:true attributes:(missing value) |error|:(missing value)
	set standardColors to {textColor:(|+|'s NSColor's textColor), backgroundColor:(|+|'s NSColor's controlColor)}
	set textColors to {normal:(|+|'s NSColor's systemGreenColor), advise:(|+|'s NSColor's systemOrangeColor), warn:(|+|'s NSColor's systemRedColor), flash:(|+|'s NSColor's systemGrayColor)}
	set my buttonFont to |+|'s NSFont's fontWithName:"Avenir Heavy" |size|:15 -- fixed width digits
	set my attrButtonText to |+|'s NSMutableAttributedString's alloc()'s initWithString:(formatTime(0))
	attrButtonText's addAttribute:(|+|'s NSFontAttributeName) value:buttonFont range:{0, attrButtonText's |length|()}
	set my windowFont to |+|'s NSFont's fontWithName:"Avenir Roman" |size|:96 -- large enough to see at a distance
	set my attrWindowText to |+|'s NSMutableAttributedString's alloc()'s initWithString:(formatTime(0))
	attrWindowText's addAttribute:(|+|'s NSFontAttributeName) value:windowFont range:{0, attrWindowText's |length|()}
	buildStatusItem()
	setupPopoverStuff()
	makeTimerWindow()
	resetCountdown()
end initialize

to doAction() -- do something when the countdown expires (countdown will continue negative)
	if actionSetting is "Run Script…" then
		try
			runScript from scriptPath given arguments:countdown
		on error errmess number errnum -- handle a script error
			showAlert from "doAction" for errmess given errnum:errnum
			my startStop:(missing value) -- stop the countdown
		end try
	else
		if actionSetting is not "Off" and actionSound is not missing value then
			if (soundTimeout is 0) or ((soundTimeout + countdown) > 0) then actionSound's play() -- continue
		end if
		set countdown to countdown - 1 -- continue negative
		setAttributedStrings(countdown) -- continue to update (flash) - display times stop at zero
		if looping then my proceedWith:"restart"
	end if
end doAction

to runScript from (posixPath as text) given arguments:arguments as list : {} -- script must be in `userScriptsFolder`
	set args to {}
	repeat with anItem in arguments -- prepare arguments for the shell script
		set args to args & space & quoted form of (anItem as text)
	end repeat
	do shell script "open -g /System/Library/CoreServices/ScriptMonitor.app" -- system LSUIElement app...
	my proceedWith:(do shell script "osascript -P " & (quoted form of posixPath) & args) -- ...to show script activity
end runScript

to proceedWith:(response as text) -- handle loop restart or script results
	if (response is "restart") and (timeSetting is not "Alarm Time…") then
		if timer is not missing value then timer's invalidate() -- use a new timer
		set my timer to missing value
		my startStop:{title:"Start"} -- reset the countdown and continue
	else if response is "continue" then -- (experimental) for running a script at other countdown times
		my startStop:(missing value) -- just stop for now
	else if response is "quit" then
		terminate()
	else -- stop the countdown
		set response to missing value
		my startStop:(missing value)
	end if
	return response -- for a script running outside the doAction handler
end proceedWith:

to readDefaults()
	tell standardUserDefaults() of |+|'s NSUserDefaults
		its registerDefaults:{Action_Setting:actionSetting, Alarm_History:alarmHistory, Alarm_Time:alarmTime, All_Sounds:allSounds, Clock_Mode:clockMode, Color_Background:colorBackground, Color_Intervals:colorIntervals, Duration_History:durationHistory, Duration_Time:durationTime, Interval_Threshold:intervalThreshold, Script_Path:scriptPath, Time_Setting:timeSetting}
		set my actionSetting to (its objectForKey:"Action_Setting") as text
		set my alarmHistory to (its objectForKey:"Alarm_History") as list
		set my alarmTime to (its integerForKey:"Alarm_Time") as integer
		set my allSounds to (its boolForKey:"All_Sounds") as boolean
		set my clockMode to (its boolForKey:"Clock_Mode") as boolean
		set my colorBackground to (its boolForKey:"Color_Background") as boolean
		set my colorIntervals to (its objectForKey:"Color_Intervals") as list
		set my durationHistory to (its objectForKey:"Duration_History") as list
		set my durationTime to (its integerForKey:"Duration_Time") as integer
		set my intervalThreshold to (its integerForKey:"Interval_Threshold") as integer
		set my scriptPath to (its objectForKey:"Script_Path") as text
		set my timeSetting to (its objectForKey:"Time_Setting") as text
	end tell
end readDefaults

to writeDefaults()
	if usingEditor then return -- don't add to the script editor prefs
	tell standardUserDefaults() of |+|'s NSUserDefaults
		its setObject:actionSetting forKey:"Action_Setting" -- text
		its setObject:alarmHistory forKey:"Alarm_History" -- list
		its setInteger:alarmTime forKey:"Alarm_Time"
		its setBool:allSounds forKey:"All_Sounds"
		its setBool:clockMode forKey:"Clock_Mode"
		its setBool:colorBackground forKey:"Color_Background"
		its setObject:colorIntervals forKey:"Color_Intervals" -- list
		its setObject:durationHistory forKey:"Duration_History" -- list
		its setInteger:durationTime forKey:"Duration_Time"
		its setInteger:intervalThreshold forKey:"Interval_Threshold"
		its setObject:scriptPath forKey:"Script_Path" -- text
		its setObject:timeSetting forKey:"Time_Setting" -- text
	end tell
end writeDefaults

to terminate() -- used as a selector for the scripting term "quit"
	quit
end terminate

on quit
	if usingEditor then -- try to clean up if running in a script editor
		repeat with obj in {positioningWindow, timerWindow}
			(obj's setReleasedWhenClosed:true)
			obj's |close|()
		end repeat
		if timer is not missing value then timer's invalidate()
		|+|'s NSStatusBar's systemStatusBar's removeStatusItem:statusItem -- only the current item
	else
		writeDefaults()
	end if
	if not usingEditor then continue quit -- don't quit a script editor
end quit


##############################
-->> Delegate Handlers
##############################

# To handle an option/right-click without showing the statusItem menu, the statusItem menu is kept cleared
# and will be set in the button's action method according to the mouse event.
on menuDidClose:_sender
	if optionClick then statusItem's setMenu:(missing value)
end menuDidClose:

on |menu|:theMenu willHighlightItem:theItem -- set up a sound sample to play when a menu item is highlighted
	if (theMenu's title) as text is not "Action" then return -- not the other menus
	if ((theItem's title) as text) is in {"Off", "Run Script…"} then return -- not these, either
	tell soundSample
		if its instance is not missing value then its instance's |stop|() -- stop any previous
		if its timer is not missing value then its timer's invalidate() -- timer not fired yet
		if theItem is missing value then return
		set its instance to |+|'s NSSound's soundNamed:(theItem's title) -- set up a new sample
		set its timer to |+|'s NSTimer's timerWithTimeInterval:0.5 target:me selector:"oneshotSample:" userInfo:(missing value) repeats:false -- set up a new one-shot timer to play sample
		|+|'s NSRunLoop's mainRunLoop's addTimer:(its timer) forMode:(|+|'s NSEventTrackingRunLoopMode)
	end tell
end |menu|:willHighlightItem:

on popoverDidClose:_notification -- clear popover stuff
	popoverWindow's |close|()
	set my viewController to missing value
	set my popoverControls to {}
end popoverDidClose:

on windowWillClose:notification -- update menu item status
	my toggleWindow:((statusMenu's itemWithTitle:"Countdown Modes")'s submenu's itemWithTitle:"Timer Window")
end windowWillClose:


##############################
-->> StatusItem Handlers
##############################

to buildStatusItem() -- build the menu bar status item
	buildMenu()
	tell (|+|'s NSStatusBar's systemStatusBar's statusItemWithLength:(|+|'s NSVariableStatusItemLength))
		set my statusItem to it
		its (button's setFont:buttonFont)
		its (button's setImagePosition:(|+|'s NSImageLeft)) -- for clock and alarm clock images
		its (button's setTitle:(my formatTime(durationTime)))
		its (button's setToolTip:(item (((timeSetting is "Alarm Time…") as integer) + 1) of {"Countdown Duration", "Alarm Time"}))
		if optionClick then -- menu will be set in in the button action
			its (button's setTarget:me)
			its (button's setAction:"statusItemAction:")
			its (button's sendActionOn:10) -- NSEventMaskLeftMouseDown + NSEventMaskRightMouseDown
		else
			its setMenu:statusMenu
		end if
	end tell
end buildStatusItem

to buildMenu() -- build a menu for the status item
	tell (|+|'s NSMenu's alloc()'s initWithTitle:"")
		set my statusMenu to it
		its setDelegate:me -- for option/right-click
		its setAutoenablesItems:false -- manual enable/disable
		my (addMenuItem to it without enabled given title:appName) -- show the app name for identification
		my (addMenuItem to it) ---- separator menu item
		my (addMenuItem to it given title:"Start", action:"startStop:", tag:100) -- tags for dynamic titles
		my (addMenuItem to it without enabled given title:"Pause", action:"pauseContinue:", tag:200)
		my (addMenuItem to it without enabled given title:"Reset", action:"resetCountdown")
		my (addMenuItem to it) ----
		my addTimeMenu(it)
		my addActionMenu(it)
		my (addMenuItem to it) ----
		my addModeMenu(it)
		my (addMenuItem to it) ----
		my (addMenuItem to it given title:"Quit", action:"terminate")
	end tell
end buildMenu

to addTimeMenu(theMenu) -- submenu for the countdown times
	tell (|+|'s NSMenu's alloc()'s initWithTitle:"")
		set {my timeMenu, added} to {it, ""}
		its setAutoenablesItems:false -- manual enable/disable
		if usingEditor and (timeMenuItems does not contain "10 Seconds") then
			set beginning of timeMenuItems to "10 Seconds"
			set added to "Short Duration Added for Testing"
		end if
		repeat with aTitle in timeMenuItems -- must be a value followed by "Seconds", "Minutes", or "Hours"
			set aTitle to contents of aTitle
			my (addMenuItem to it given title:aTitle, action:"setMenuTime:", state:(timeSetting is (aTitle as text)))
			if (aTitle is "10 Seconds") and (added is not "") then (result's setToolTip:added)
			set end of menuTimes to {menuTitle:aTitle, itemSeconds:(my getSeconds(aTitle))} -- for date picker comparisons
		end repeat
		my (addMenuItem to it) ---- separator menu item
		my (addMenuItem to it given title:"Custom Duration…", action:"getTime:", state:(timeSetting is "Custom Duration…"))
		result's setToolTip:"Custom Countdown Duration"
		my (addMenuItem to it given title:"Alarm Time…", action:"getTime:", state:(timeSetting is "Alarm Time…"))
		result's setToolTip:"Time of Day"
	end tell
	(theMenu's addItemWithTitle:"Time" action:(missing value) keyEquivalent:"")'s setSubmenu:timeMenu
end addTimeMenu

to addActionMenu(theMenu) -- submenu for the actions
	tell (|+|'s NSMenu's alloc()'s initWithTitle:"Action")
		set my actionMenu to it
		its setDelegate:me -- for sound sample
		its setAutoenablesItems:false -- manual enable/disable
		my (addMenuItem to it given title:"Off", action:"setAlarm:", state:(actionSetting is "Off"))
		my (addMenuItem to it) ---- separator menu item
		my (addMenuItem to it given title:"Run Script…", action:"setAlarm:", state:(actionSetting is "Run Script…"))
		my (addMenuItem to it) ----
		repeat with aName in actionMenuItems -- placed at the end for possible menu items extending off the screen
			set aName to aName as text
			if aName is in {"", "Bundle Sounds", "Preset Sounds", "User Sounds", "Local Sounds", "System Sounds"} then
				my (addMenuItem to it) ----
				if aName is not "" then my (addMenuItem to it with header given title:aName) -- section header
			else -- must be the name of a sound file
				set state to (actionSetting is aName) and ((count actionSetting) is (count aName)) -- handle zero width spaces
				my (addMenuItem to it given title:aName, action:"setAlarm:", state:state)
				if state then set my actionSound to (|+|'s NSSound's soundNamed:aName)
			end if
		end repeat
	end tell
	(theMenu's addItemWithTitle:"Action" action:(missing value) keyEquivalent:"")'s setSubmenu:actionMenu
end addActionMenu

to addModeMenu(theMenu) -- submenu for modes
	tell (|+|'s NSMenu's alloc()'s initWithTitle:"")
		its setAutoenablesItems:false -- manual enable/disable
		my (addMenuItem to it given title:"Timer Window", action:"toggleWindow:")
		result's setToolTip:"Show a supplementary timer window"
		my (addMenuItem to it with alternate given title:"Timer Window Reset", action:"toggleWindow:", tag:300) -- tag for state
		result's setToolTip:"Reset the timer window location"
		my (addMenuItem to it given title:"Loop", action:"toggleLooping:", state:looping)
		result's setToolTip:"Automatically Restart Timer"
		my (addMenuItem to it) ---- separator menu item
		my (addMenuItem to it given title:"Count", action:"getCountdownMode:", state:(clockMode is false))
		result's setToolTip:"Manual Count Down When Not Paused"
		my (addMenuItem to it given title:"Clock", action:"getCountdownMode:", state:(clockMode is true))
		result's setToolTip:"Count Down Using the Time Started"
		(theMenu's addItemWithTitle:"Countdown Modes" action:(missing value) keyEquivalent:"")'s setSubmenu:it
	end tell
	my (addMenuItem to theMenu given title:"Set Color Intervals…", action:"setIntervals")
end addModeMenu

to setAttributedStrings(theTime) -- set the statusItem button and window textField attributed strings (for colors)
	repeat with obj in {attrButtonText, attrWindowText}
		(obj's replaceCharactersInRange:{0, obj's |length|()} withString:formatTime(theTime))
	end repeat
	set intervalTime to item ((((timeSetting is "Alarm Time…") or (durationTime > intervalThreshold)) as integer) + 1) of {durationTime, intervalThreshold} -- current duration or `intervalThreshold` for color changes
	set theColor to textColor of standardColors
	tell colorIntervals to if it is not {0.0, 0.0} then -- overwrite to allow individual color disable
		set theColor to (normal of textColors)
		if (first item is not 0.0) and (theTime ≤ ((first item) * intervalTime)) then set theColor to (advise of textColors)
		if (last item is not 0.0) and (theTime ≤ ((last item) * intervalTime)) then set theColor to (warn of textColors)
	end if
	applyAttribute("NSColor", theColor)
	if colorBackground then windowLabelField's setBackgroundColor:(item (((colorIntervals is not {0.0, 0.0}) as integer) + 1) of {backgroundColor of standardColors, theColor})
	if theTime < 1 then
		set flashing to not flashing
		if flashing then -- flash background colors when countdown is expired
			applyAttribute("NSBackgroundColor", flash of textColors)
			if colorBackground then windowLabelField's setBackgroundColor:(item (((colorIntervals is not {0.0, 0.0}) as integer) + 1) of {flash of textColors, theColor})
		else
			applyAttribute("NSBackgroundColor", null)
			if colorBackground then windowLabelField's setBackgroundColor:(backgroundColor of standardColors)
		end if
	end if
	statusItem's button's setAttributedTitle:attrButtonText
	windowLabelField's setAttributedStringValue:attrWindowText
end setAttributedStrings

to applyAttribute(attribute, value) -- add or remove attributes as appropriate
	repeat with obj in (item ((colorBackground as integer) + 1) of {{attrButtonText, attrWindowText}, {attrButtonText}})
		if value is not in {missing value, null} then
			(obj's addAttribute:attribute value:value range:{0, obj's |length|()})
		else
			(obj's removeAttribute:attribute range:{0, obj's |length|()})
		end if
	end repeat
end applyAttribute


##############################
-->> Popover Handlers
##############################

to setupPopoverStuff() -- popover and transparent positioning window the same width as the statusItem 
	set {buttonWidth, buttonHeight} to last item of ((statusItem's button's frame) as list) -- button size
	tell (|+|'s NSWindow's alloc()'s initWithContentRect:{{0, 0}, {buttonWidth, 1}} styleMask:0 backing:2 defer:true)
		set my positioningWindow to it
		its setReleasedWhenClosed:false
		its setAlphaValue:0.0 -- clear
	end tell
	tell |+|'s NSPopover's alloc()'s init()
		set my popover to it
		its setDelegate:me -- for close notification
		its setBehavior:(|+|'s NSPopoverBehaviorTransient) -- close when interacting outside the popover
	end tell
end setupPopoverStuff

to setPopoverViews for (controls as list) given title:title as text : "", representedObject:representedObject : missing value -- any representedObject will be a dictionary of scripts from the scripts popover
	set my popoverControls to {} -- clear previous
	set my viewController to |+|'s NSViewController's alloc()'s init() -- new controller
	if representedObject is not missing value then viewController's setRepresentedObject:representedObject
	viewController's setTitle:title
	tell (|+|'s NSView's alloc's initWithFrame:{{0, 0}, {0, 0}}) -- view for controls
		viewController's setView:it
		set {maxWidth, maxHeight} to {0, 0}
		repeat with aControl in controls -- size to fit all the controls
			set {{originX, originY}, {width, height}} to ((aControl's frame()) as list)
			set {newWidth, newHeight} to {originX + width, originY + height}
			if newWidth > maxWidth then set maxWidth to newWidth
			if newHeight > maxHeight then set maxHeight to newHeight
			(viewController's view's addSubview:aControl)
			set klass to |+|'s NSStringFromClass(aControl's |class|()) as text
			set end of my popoverControls to {klass, contents of aControl} -- new list of controls in the order declared
		end repeat
		its setFrameSize:{maxWidth + 11, maxHeight + 13} -- padding at top and right
		popover's setContentSize:(last item of ((its frame()) as list))
	end tell
	popover's setContentViewController:viewController
end setPopoverViews

to locateStatusItem() -- get the current statusItem location
	set screen to first item of ((|+|'s NSScreen's screens) as list) -- the screen with the menu
	set {screenX, screenY} to last item of ((screen's frame) as list) -- screen size
	set {buttonX, buttonY} to first item of ((statusItem's button's |window|'s frame) as list) -- button origin
	return {buttonX + 10, screenY - 25} -- center of button, off bottom edge of menu bar
end locateStatusItem

to showPopover()
	activate me
	tell positioningWindow
		its setFrameOrigin:(my locateStatusItem())
		its makeKeyAndOrderFront:me
		popover's showRelativeToRect:(|+|'s NSZeroRect) ofView:(its contentView) preferredEdge:7 -- MinY of bounds
	end tell
	# tell application "System Events" to keystroke tab -- highlight minutes
end showPopover

to getPopoverControls(controlClasses) -- get all controls from a popover view that match the specified class
	set theControls to {}
	repeat with aControl in popoverControls -- set list of {control class, the control} to all or matching controls
		if (controlClasses is in {{}, missing value}) or (first item of aControl is in (controlClasses as list)) then ¬
			set end of theControls to last item of aControl -- items are in the declared order
	end repeat
	return theControls
end getPopoverControls

to buildTimeControls(setting) -- build controls for the time popover
	set theTime to item (((setting is "Duration") as integer) + 1) of {alarmTime, durationTime}
	set promptLabel to makeLabel at {15, 50} given stringValue:setting & ":"
	set datePicker to makeDatePicker at {100, 46} given dimensions:{80, 24}, dateValue:theTime
	set cancelButton to makeButton at {11, 15} given dimensions:{85, 24}, title:"Cancel", action:"timePopover:", keyEquivalent:(character id 27)
	set history to item (((setting is "Duration") as integer) + 1) of {alarmHistory, durationHistory}
	if history is not {} then -- use combo button for previous custom times if available
		set setButton to makeComboButton at {100, 15} for history given headerTitle:" Previous", dimensions:{85, 24}, title:"Set", defaultTitle:"Set", buttonStyle:0, menuAction:"timePopover:", buttonAction:"timePopover:"
	else -- regular button
		set setButton to makeButton at {100, 15} given dimensions:{85, 24}, title:"Set", action:"timePopover:", keyEquivalent:return
	end if
	setPopoverViews for {promptLabel, datePicker, cancelButton, setButton} given title:setting
end buildTimeControls

to buildScriptControls() -- build controls for the script popover - returns boolean for scripts found
	set {current, dictionary} to getUserScripts()
	if (current is in {"", missing value}) or (dictionary is missing value) then set my scriptPath to ""
	if dictionary is missing value then return false -- no scripts found
	if current is in {"", missing value} then set current to "– No script selected –"
	set promptLabel to makeLabel at {15, 50} given stringValue:"Action script:"
	set popup to makePopupButton at {103, 44} given itemList:(dictionary's allKeys()) as list, title:current
	set cancelButton to makeButton at {10, 15} given dimensions:{95, 24}, title:"Cancel", action:"scriptPopover:", keyEquivalent:(character id 27)
	set showButton to makeButton at {110, 15} given dimensions:{120, 24}, title:"Show Folder", action:"scriptPopover:"
	set setButton to makeButton at {235, 15} given dimensions:{95, 24}, title:"Set", action:"scriptPopover:", keyEquivalent:return
	setPopoverViews for {promptLabel, popup, cancelButton, showButton, setButton} given representedObject:dictionary -- have the controller retain the dictionary of scripts
	return true -- success
end buildScriptControls

to buildIntervalControls() -- build controls for the interval popover
	set {cautionValue, warningValue} to colorIntervals
	set cautionLabel to makeLabel at {15, 71} given stringValue:"Caution: " & formatFloat(cautionValue) & " "
	cautionLabel's setToolTip:"Percentage for Normal to Caution"
	set warningLabel to makeLabel at {15, 46} given stringValue:"Warning: " & formatFloat(warningValue) & " "
	warningLabel's setToolTip:"Percentage for Caution to Warning"
	set cautionSlider to makeSlider at {115, 66} given floatValue:cautionValue, trackColor:(advise of textColors)
	set warningSlider to makeSlider at {115, 41} given floatValue:warningValue, trackColor:(warn of textColors)
	set cancelButton to makeButton at {10, 15} given title:"Cancel", action:"intervalPopover:", keyEquivalent:(character id 27)
	set itemList to {}
	repeat with anItem in intervalMenuItems
		if (class of anItem is list) and (contents of anItem is not {}) then
			tell anItem to set end of itemList to " " & my formatFloat(first item) & "   " & my formatFloat(last item)
		end if
	end repeat
	set defaultsButton to makeComboButton at {120, 15} for itemList given title:"Presets", headerTitle:" Caution     Warning", menuAction:"updateIntervals:" -- use combo button for preset percentages if available
	set setButton to makeButton at {230, 15} given title:"Set", action:"intervalPopover:", keyEquivalent:return
	setPopoverViews for {cautionLabel, warningLabel, cautionSlider, warningSlider, cancelButton, defaultsButton, setButton}
end buildIntervalControls


##############################
-->> Action Handlers
##############################

# Handle option/right-click - the statusItem menu needs to be set to select it using keyboard navigation.
# Note that the NSEventMask used to send the action is different than the NSEventType.
on statusItemAction:_sender -- handle option/right-click
	if not optionClick then return
	# `run script` is used in the following statement to handle NSEvent's `type` property with multiple editors - in Script Debugger the term needs to be escaped, while Script Editor will remove any escaping.
	set eventType to (run script "use framework \"Foundation\"
	return current application's NSApp's currentEvent's |type|") as integer -- avoids different editor escaping for `type`
	if eventType is (|+|'s NSEventTypeLeftMouseDown) as integer then -- (1) normal left click, so...
		statusItem's setMenu:statusMenu -- ...add menu to button...
		statusItem's button's performClick:me -- ...then click it again to show the menu
	else if eventType is (|+|'s NSEventTypeRightMouseDown) as integer then -- (3) option/right click, so do something else
		doOptionClick()
	end if
end statusItemAction:

to updateCountdown:_timer -- update statusItem and timer window and check countdown (repeatedly called by the timer)
	if pausing then return
	if altActions then -- do something else for a specific condition (experimental)
		if doAltActions() then return -- the handler returns a boolean to exit the handler (or not)
	end if
	if countdown ≤ 1 then -- action - note that the countdown can be negative
		doAction()
	else -- continue
		if (alarmTime ≥ 1) and (timeSetting is "Alarm Time…") then -- calculate time remaining to alarm
			set countdown to alarmTime - (time of (current date))
		else -- duration countdown - by 1 (count mode) or calculate time from start (clock mode)
			set countdown to (item ((clockMode as integer) + 1) of {countdown - 1, targetTime - (current date)})
		end if
		if countdown < 1 then set {countdown, targetTime} to {0, (current date)} -- reset for counting past expiration
		setAttributedStrings(countdown)
	end if
end updateCountdown:

on oneshotSample:_timer -- play a single sound sample
	tell soundSample
		its instance's play()
		set its timer to missing value -- invalidated when fired
	end tell
end oneshotSample:

to setMenuTime:sender -- update the time menu selection
	set setting to (sender's title as text)
	set my durationTime to getSeconds(setting)
	resetTimeMenuState(setting)
end setMenuTime:

to setAlarm:sender -- update the action selection
	tell (sender's title as text) to if it is "Run Script…" then -- get action script
		if not my buildScriptControls() then return -- no scripts
		my showPopover()
		return -- menu state updated by popover
	else if it is not "Off" then -- set up sound
		set my actionSound to (|+|'s NSSound's soundNamed:it) -- NSSound is asynchronous
		actionSound's play() -- sample
	end if
	resetActionMenuState(sender's title as text)
end setAlarm:

to startStop:sender -- (re)set the timer and main menu properties - tags are used for dynamic titles
	set {pausing, itemTitle} to {false, ""}
	if sender is not missing value then set itemTitle to (sender's title as text)
	(statusMenu's itemWithTag:200)'s setTitle:"Pause" -- pause/continue
	if itemTitle is "Start" then
		set state to item (((clockMode or (timeSetting is "Alarm Time…")) as integer) + 1) of {true, false}
		(statusMenu's itemWithTitle:"Reset")'s setEnabled:state
		(statusMenu's itemWithTag:100)'s setTitle:"Stop" -- start/stop
		(statusMenu's itemWithTag:200)'s setEnabled:state -- pause/continue
		statusItem's button's setToolTip:(item (((timeSetting is "Alarm Time…") as integer) + 1) of {"Countdown Remaining", "Time Until Alarm"})
	else
		if actionSound is not missing value then actionSound's |stop|()
		(statusMenu's itemWithTitle:"Reset")'s setEnabled:false
		(statusMenu's itemWithTag:100)'s setTitle:"Start" -- start/stop
		(statusMenu's itemWithTag:200)'s setEnabled:false -- pause/continue
		statusItem's button's setToolTip:(item (((timeSetting is "Alarm Time…") as integer) + 1) of {"Countdown Duration", "Alarm Time"})
	end if
	repeat with mode in ((statusMenu's itemWithTitle:"Countdown Modes")'s submenu's itemArray) as list
		if (mode's title) as text does not contain "Timer Window" then (mode's setEnabled:(itemTitle is not "Start"))
	end repeat
	my resetCountdown()
	resetTimer(itemTitle)
end startStop:

to pauseContinue:sender -- pause or continue the countdown
	set itemTitle to (sender's title as text)
	set pausing to item (((itemTitle is "Pause") as integer) + 1) of {false, true}
	sender's setTitle:(item (((itemTitle is "Pause") as integer) + 1) of {"Pause", "Continue"})
end pauseContinue:

to getCountdownMode:sender -- mode for countdown duration
	(sender's |menu|'s itemWithTitle:"Clock")'s setState:false
	(sender's |menu|'s itemWithTitle:"Count")'s setState:false
	set my clockMode to ((sender's title as text) is "Clock")
	sender's setState:true
end getCountdownMode:

to toggleLooping:sender
	set looping to not looping
	sender's setState:looping
end toggleLooping:

to toggleWindow:sender -- tag is used for alternate menuItem state
	set {x, y} to locateStatusItem()
	if ((sender's title) as text) contains "Reset" then ¬
		return timerWindow's setFrame:{{x - 156, y - 250}, {396, 128}} display:true animate:true
	set showWindow to not showWindow
	sender's setState:showWindow
	((statusMenu's itemWithTitle:"Countdown Modes")'s submenu's itemWithTag:300)'s setState:showWindow -- alternate
	if showWindow then
		if (first item of ((timerWindow's frame) as list) is {0, 0}) and not (timerWindow's setFrameUsingName:"TimerWindow") then timerWindow's setFrameTopLeftPoint:{x - 156, y - 122}
		timerWindow's orderFront:me
		timerWindow's display()
	else
		timerWindow's orderOut:me
	end if
end toggleWindow:

to getTime:sender -- get alarm or countdown time
	set setting to item ((((sender's title as text) contains "Alarm") as integer) + 1) of {"Duration", "Alarm Time"}
	buildTimeControls(setting)
	showPopover()
end getTime:

on timePopover:sender -- handle buttons from the date picker popover
	set {buttonTitle, custom} to {(sender's title) as text, true}
	if buttonTitle is not "Cancel" then
		if buttonTitle is "Set" then
			set theTime to (time of (((first item of getPopoverControls("NSDatePicker"))'s dateValue) as date))
		else
			set theTime to unformatTime(buttonTitle)
		end if
		tell (popover's contentViewController's title) as text to if it is "Duration" then
			repeat with anItem in menuTimes
				if theTime is anItem's itemSeconds then -- time equals one of the menu settings
					(my setMenuTime:{title:(anItem's menuTitle)}) -- select the menu item instead (durationTime is updated)
					set custom to false
					exit repeat
				end if
			end repeat
			if durationTime is not theTime then -- update custom duration
				set my durationTime to theTime
				set my durationHistory to my updateHistory(theTime, durationHistory)
			end if
			if custom then my resetTimeMenuState("Custom Duration…")
		else if it is "Alarm Time" then
			my setAlarmTime(theTime)
		end if
	end if
	tell popover to |close|()
end timePopover:

to updatePopup:sender -- update popup button changes
	sender's setTitle:(sender's titleOfSelectedItem) -- note that there may not always be a selection
end updatePopup:

on scriptPopover:sender -- handle buttons from the script selection popover
	tell (sender's title as text) to if it is "Show Folder" then
		tell application "Finder"
			activate
			reveal (userScriptsFolder as POSIX file)
		end tell
	else if it is not "Cancel" then
		set dictionary to popover's contentViewController's representedObject -- dictionary of scripts
		set selected to (title of (first item of my getPopoverControls("NSPopupButton"))) as text
		if selected is not in {"", "– No script selected –"} then
			set my scriptPath to (dictionary's objectForKey:selected) as text
			my resetActionMenuState("Run Script…")
		end if
	end if
	tell popover to |close|()
end scriptPopover:

to updateSlider:sender -- update slider changes
	set {cautionLabel, warningLabel, cautionSlider, warningSlider} to getPopoverControls({"NSTextField", "NSSlider"})
	if sender is in {missing value, cautionSlider} then cautionLabel's setStringValue:("Caution: " & formatFloat(cautionSlider's floatValue))
	if sender is in {missing value, warningSlider} then warningLabel's setStringValue:("Warning: " & formatFloat(warningSlider's floatValue))
end updateSlider:

to updateIntervals:sender -- update sliders to combo button selection or first item of `intervalMenuItems`
	set {cautionSlider, warningSlider} to my getPopoverControls("NSSlider")
	set theItem to item (((|+|'s NSClassFromString("NSComboButton") is missing value) as integer) + 1) of {sender's tag, 1}
	set newIntervals to item theItem of intervalMenuItems
	cautionSlider's setFloatValue:(first item of newIntervals)
	warningSlider's setFloatValue:(last item of newIntervals)
	my updateSlider:(missing value)
end updateIntervals:

on intervalPopover:sender -- handle buttons from the slider popover
	if (sender's title as text) is not "Cancel" then
		set {cautionSlider, warningSlider} to my getPopoverControls("NSSlider")
		set cautionValue to formatFloat(cautionSlider's floatValue) as real
		set warningValue to formatFloat(warningSlider's floatValue) as real
		set my colorIntervals to {cautionValue, warningValue}
	end if
	tell popover to |close|()
end intervalPopover:


##############################
-->> Utility Handlers
##############################

to setAlarmTime(theSeconds as integer)
	try -- skip setting if cancel or give up
		if (theSeconds - (time of (current date))) < 0 then -- note that the alarm time has passed
			activate me
			display alert "Setting Alarm Time" message "The specified alarm time may be set, but note that it is earlier than the current time." buttons {"Cancel", "OK"} cancel button "Cancel" default button "OK" giving up after 15
			if gave up of the result then error -- skip
		end if
		set my alarmTime to theSeconds
		set my alarmHistory to my updateHistory(theSeconds, alarmHistory)
		resetTimeMenuState("Alarm Time…")
	end try
end setAlarmTime

to resetCountdown() -- reset the countdown to the current setting (does not stop any timer)
	applyAttribute("NSBackgroundColor", null)
	set {flashing, indx} to {false, ((timeSetting is "Alarm Time…") as integer) + 1}
	set countdown to item indx of {durationTime, alarmTime}
	statusItem's button's setTitle:formatTime(countdown) -- plain text
	windowLabelField's setStringValue:formatTime(countdown)
	windowLabelField's setBackgroundColor:(backgroundColor of standardColors)
	set image to |+|'s NSImage's imageNamed:(item indx of {"NSTouchBarHistoryTemplate", "NSTouchBarAlarmTemplate"})
	statusItem's button's setImage:image -- clock and alarm clock templates from NSTouchBarItem
	titlebarController's view's setImage:image
end resetCountdown

to resetTimeMenuState(setting) -- reset state for a new time menu setting
	tell (timeMenu's itemWithTitle:timeSetting) to if it is not missing value then its setState:false -- old
	set my timeSetting to setting
	my resetCountdown()
	(timeMenu's itemWithTitle:timeSetting)'s setState:true -- new
	my startStop:(missing value)
end resetTimeMenuState

to resetActionMenuState(setting) -- reset state for a new action menu setting
	tell (actionMenu's itemWithTitle:actionSetting) to if it is not missing value then its setState:false -- old
	set my actionSetting to setting
	(actionMenu's itemWithTitle:actionSetting)'s setState:true -- new
	set loopMenuItem to (statusMenu's itemWithTitle:"Countdown Modes")'s submenu's itemWithTitle:"Loop"
	if actionSetting is "Run Script…" then
		set looping to false -- loop mode and run script are mutually exclusive
		loopMenuItem's setState:false
		loopMenuItem's setEnabled:false
	else
		loopMenuItem's setEnabled:true
	end if
end resetActionMenuState

to resetTimer(mode as text)
	if mode is "Start" then
		if timer is not missing value then return
		set my timer to |+|'s NSTimer's timerWithTimeInterval:1 target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true -- restart with new timer
		|+|'s NSRunLoop's currentRunLoop's addTimer:timer forMode:(|+|'s NSRunLoopCommonModes)
		tell (current date) to set targetTime to it + durationTime -- see `clockMode`
	else
		if timer is not missing value then timer's invalidate() -- don't leave the timer running
		set {my timer, targetTime} to {missing value, 0}
	end if
end resetTimer

to setIntervals() -- get normal > caution and caution > warning interval percentages (0.0-1.0)
	buildIntervalControls()
	showPopover()
end setIntervals

to updateHistory(value, history) -- update previous custom duration or alarm settings
	copy history to newHistory
	set beginning of newHistory to formatTime(value) -- add entry to the beginning, orderedSet will only add objects once
	set newHistory to ((|+|'s NSOrderedSet's orderedSetWithArray:newHistory)'s array()) as list
	tell newHistory to if (count it) > 5 then set newHistory to items 1 thru 5
	return newHistory
end updateHistory

to getSeconds(setting as text) -- get seconds from time setting text
	set interval to (first word of setting) as integer -- default to "Seconds"
	if (setting contains "Minute") or (setting contains "Hour") then set interval to item (((setting contains "Minute") as integer) + 1) of {interval * hours, interval * minutes}
	return interval mod 86400 -- wrap at 24 hours
end getSeconds

to getUserScripts() -- get user scripts - returns the current name and a dictionary of scripts
	set dictionary to |+|'s NSMutableDictionary's alloc()'s init() -- dictionary of name:posixPath
	set current to missing value
	repeat with anItem in (getFolderContents from userScriptsFolder given resourceKeys:{"NSURLTypeIdentifierKey"})
		set {theResult, value} to (anItem's getResourceValue:(reference) forKey:"NSURLTypeIdentifierKey" |error|:(missing value)) -- (NSURLTypeIdentifierKey is deprecated in Big Sur)
		if theResult and ((value as text) is "com.apple.applescript.script") then -- only compiled scripts
			set {theName, thePath} to {(anItem's lastPathComponent's stringByDeletingPathExtension) as text, (anItem's |path| as text)}
			if thePath is scriptPath then set current to theName -- name of current script setting
			(dictionary's setObject:thePath forKey:theName)
		end if
	end repeat
	if dictionary's |count|() is 0 then
		activate me
		display alert "Error Finding Scripts" message "No compiled user scripts were found - please place a script in the '" & userScriptsFolder & "' folder and try again." buttons {"Show Folder", "OK"} giving up after 20
		if button returned of result is "Show Folder" then tell application "Finder" to reveal (userScriptsFolder as POSIX file)
		return {missing value, missing value}
	end if
	return {current, dictionary}
end getUserScripts

to getAllSounds() -- get sound names from sound libraries (NSSearchPathDomainMask of 11)
	tell |+|'s NSMutableArray to set {soundList, subList} to {its alloc()'s init(), its alloc()'s init()}
	repeat with libraryPath in reverse of (((|+|'s NSSearchPathForDirectoriesInDomains(|+|'s NSLibraryDirectory, 11, true))'s objectEnumerator())'s allObjects as list) -- /System/Library, /Library, /Users/<user>/Library
		repeat with anItem in (getFolderContents from libraryPath given subfolder:"Sounds")
			tell anItem's |path| to if ((its pathExtension) as text) is in soundExtensions then
				set candidate to (its lastPathComponent's stringByDeletingPathExtension) as text
				if not (subList's containsObject:candidate) then (subList's addObject:candidate) -- skip duplicate names
			end if
		end repeat
		(subList's removeObjectsInArray:soundList) -- remove sounds already in the main list (from previous directories)
		if (subList's |count|()) as integer is not 0 then
			(subList's setArray:(subList's sortedArrayUsingSelector:"compare:"))
			set source to (first word of libraryPath)
			if source ends with "s" then set source to text 1 thru -2 of source -- "User"
			if source is "Library" then set source to "Local"
			(subList's insertObject:(source & " Sounds") atIndex:0) -- section header - see `addActionMenu`
			(soundList's addObjectsFromArray:subList)
			subList's removeAllObjects()
		end if
	end repeat
	set my actionMenuItems to soundList as list
end getAllSounds

to getSounds() -- add from the app bundle (if present) or from all sound libraries if option is set
	if allSounds then return getAllSounds() -- override preset
	set soundList to |+|'s NSMutableArray's alloc()'s init()
	repeat with anItem in (getFolderContents from (|+|'s NSBundle's mainBundle's resourcePath) given subfolder:"Sounds")
		tell anItem's |path| to if ((its pathExtension) as text) is in soundExtensions then
			set justTheName to (its lastPathComponent)'s stringByDeletingPathExtension
			(soundList's addObject:justTheName)
			tell (|+|'s NSSound's alloc's initWithContentsOfFile:it byReference:true)
				set end of bundleSounds to it -- the NSSound instance
				(its setName:justTheName) -- to use with `soundNamed`
			end tell
		end if
	end repeat
	if (soundList's |count|()) as integer is not 0 then
		(soundList's setArray:(soundList's sortedArrayUsingSelector:"compare:"))
		soundList's insertObject:"Bundle Sounds" atIndex:0
		set beginning of actionMenuItems to "Preset Sounds" -- section header - see `addActionMenu`
		set actionMenuItems to actionMenuItems & (soundList as list)
	end if
end getSounds


##############################
-->> UI Object Handlers
##############################

to makeLabel at (origin as list) given stringValue:stringValue as text : ""
	tell (|+|'s NSTextField's labelWithString:stringValue)
		its setFrameOrigin:origin
		its sizeToFit()
		return it
	end tell
end makeLabel

to makeButton at (origin as list) given dimensions:dimensions as list : {100, 24}, title:title as text : "Button", action:action : (missing value), keyEquivalent:keyEquivalent as text : ""
	tell (|+|'s NSButton's buttonWithTitle:title target:me action:action)
		its setFrame:{origin, dimensions}
		if keyEquivalent is not "" then its setKeyEquivalent:keyEquivalent
		its setFont:(|+|'s NSFont's fontWithName:"Menlo" |size|:12)
		return it
	end tell
end makeButton

to makePopupButton at (origin as list) given maxWidth:maxWidth as integer : 224, itemList:itemList as list : {}, title:title as text : "", action:action : "updatePopup:"
	if maxWidth < 0 then set maxWidth to 0
	set itemList to ((|+|'s NSOrderedSet's orderedSetWithArray:itemList)'s array()) as list
	tell (|+|'s NSPopUpButton's alloc()'s initWithFrame:{origin, {maxWidth, 25}} pullsDown:true)
		its setLineBreakMode:(|+|'s NSLineBreakByTruncatingMiddle)
		its addItemsWithTitles:itemList
		its insertItemWithTitle:"" atIndex:0 -- placeholder for title
		if title is not "" then its setTitle:title
		if action is not missing value then
			its setTarget:me
			its setAction:action
		end if
		return it
	end tell
end makePopupButton

on makeComboButton at (origin as list) for itemList given headerTitle:headerTitle as text : "", dimensions:dimensions as list : {100, 24}, title:title as text : "Button", defaultTitle:defaultTitle as text : "Default", buttonStyle:buttonStyle as integer : 1, menuAction:menuAction : missing value, buttonAction:buttonAction : missing value -- macOS 13 Ventura and later
	if |+|'s NSClassFromString("NSComboButton") is missing value then return (makeButton at origin given dimensions:dimensions, title:defaultTitle, action:menuAction, keyEquivalent:return) -- framework not available, so just return a regular button
	set itemList to ((|+|'s NSOrderedSet's orderedSetWithArray:itemList)'s array()) as list -- orderedSet will only add objects once
	tell (|+|'s NSMenu's alloc()'s initWithTitle:"")
		set menuActions to it
		set tag to 0
		if headerTitle is not "" then my (addMenuItem to it with header without enabled given title:headerTitle)
		repeat with anItem in itemList
			set tag to tag + 1 -- used as an index into the item list
			my (addMenuItem to it given title:anItem, action:menuAction, tag:tag)
		end repeat
	end tell
	tell (|+|'s NSComboButton's comboButtonWithTitle:title |menu|:menuActions target:me action:buttonAction)
		its setFrame:{origin, dimensions}
		its setStyle:buttonStyle
		its setFont:(|+|'s NSFont's fontWithName:"Menlo" |size|:12) -- fixed width for formatting
		return it
	end tell
end makeComboButton

on makeDatePicker at (origin as list) given dimensions:dimensions as list : {80, 24}, dateValue:dateValue : missing value
	tell (|+|'s NSDatePicker's alloc()'s initWithFrame:{origin, dimensions})
		its setDatePickerStyle:(|+|'s NSDatePickerStyleTextFieldAndStepper)
		its setDatePickerElements:((|+|'s NSDatePickerElementFlagHourMinuteSecond as integer))
		its setBezeled:false
		its setLocale:(|+|'s NSLocale's alloc()'s initWithLocaleIdentifier:"en_GB") -- for 24-hour
		if dateValue is not missing value then -- set specified time, otherwise the current time is used
			tell (current date) to set {now, its time} to {it, dateValue as integer}
			its setDateValue:(|+|'s NSDate's dateWithTimeInterval:0 sinceDate:now) -- AppleScript date is bridged with NSDate
		end if
		return it
	end tell
end makeDatePicker

to makeSlider at (origin as list) given dimensions:dimensions as list : {210, 24}, floatValue:floatValue as real : 0, trackColor:trackColor : missing value, action:action as text : "updateSlider:"
	if action is in {"", "missing value"} then set action to missing value
	tell (|+|'s NSSlider's sliderWithTarget:me action:action)
		its setFrame:{origin, dimensions}
		its setControlSize:(|+|'s NSControlSizeMini)
		its setContinuous:true
		its setFloatValue:floatValue
		if trackColor is not missing value then its setTrackFillColor:trackColor
		return it
	end tell
end makeSlider

to makeTimerWindow() -- make and return a supplementary window for the statusItem countdown
	tell ((|+|'s NSWindow's alloc)'s initWithContentRect:{{0, 0}, {398, 100}} styleMask:3 backing:2 defer:false)
		set my timerWindow to it
		its setReleasedWhenClosed:false
		its setTitlebarAppearsTransparent:true
		its setLevel:(|+|'s NSModalPanelWindowLevel)
		its setAlphaValue:0.94
		its setAnimationBehavior:(|+|'s NSWindowAnimationBehaviorDocumentWindow)
		its setDelegate:me -- for `windowWillClose` notification
		its setTitle:(appName)
		its addTitlebarAccessoryViewController:(my makeTitlebarController())
		if not usingEditor then its setFrameAutosaveName:"TimerWindow" -- window location is also saved to defaults
		its (contentView's addSubview:(my makeTimerLabel()))
		its (contentView's setMenu:statusMenu)
		return it
	end tell
end makeTimerWindow

to makeTitlebarController() -- make and return a titlebar controller for clock images in the window titlebar
	set titlebarView to |+|'s NSImageView's alloc()'s initWithFrame:{{0, 0}, {34, 34}}
	tell |+|'s NSTitlebarAccessoryViewController's alloc()'s init()
		set my titlebarController to it
		its setView:titlebarView
		its setLayoutAttribute:(|+|'s NSLayoutAttributeRight)
		return it
	end tell
end makeTitlebarController

to makeTimerLabel() -- make and return a label text field in a view for the timer window countdown
	tell (|+|'s NSTextField's labelWithAttributedString:attrWindowText)
		its setFrame:{{0, -14}, {378, 120}}
		set my windowLabelField to it
		its setFont:windowFont
		its setToolTip:(item (((timeSetting is "Alarm Time…") as integer) + 1) of {"Countdown Duration", "Alarm Time"})
		its setDrawsBackground:true -- label is used for attributed string, but need to draw colorBackground
		its setBackgroundColor:(backgroundColor of standardColors)
	end tell
	tell (|+|'s NSView's alloc()'s initWithFrame:{{10, 10}, {388, 90}})
		its setClipsToBounds:true -- use the view to trim the label field background a bit
		its addSubview:windowLabelField
		return it
	end tell
end makeTimerLabel


##############################
-->> General-purpose Handlers
##############################

# Add a menuItem to a menu - `sectionHeaderWithTitle` convenience method is for macOS 14+, so an attributedString is used.
to addMenuItem to theMenu given title:(title as text) : "", header:(header as boolean) : false, alternate:(alternate as boolean) : false, action:(action as text) : "", theKey:(theKey as text) : "", tag:(tag as integer) : 0, enabled:(enabled as boolean) : true, state:(state as integer) : 0 -- given parameters are optional
	if title is "" then return theMenu's addItem:(|+|'s NSMenuItem's separatorItem)
	if header then tell (theMenu's addItemWithTitle:"" action:(missing value) keyEquivalent:"")
		set attrTitle to |+|'s NSMutableAttributedString's alloc()'s initWithString:title
		attrTitle's addAttribute:(|+|'s NSFontAttributeName) value:(|+|'s NSFont's fontWithName:"System Font Bold" |size|:11) range:{0, attrTitle's |length|()}
		its setAttributedTitle:attrTitle
		its setEnabled:false
		return it
	end tell
	tell (theMenu's addItemWithTitle:title action:action keyEquivalent:theKey)
		if action is not "" then its setTarget:me -- target will only be current script
		if tag > 0 then its setTag:tag
		its setEnabled:enabled
		its setState:state -- 0 = off (false), 1 = on (true), -1 = mixed
		if alternate then
			its setAlternate:true
			its setKeyEquivalentModifierMask:524288 -- NSEventModifierFlagOption
		end if
		return it
	end tell
end addMenuItem

# Get the contents of a folder - `options` 7 is no hidden items, package contents, or subfolders.
to getFolderContents from (posixPath as text) given subfolder:subfolder as text : "", resourceKeys:resourceKeys as list : {}, options:options as integer : 7 -- given parameters are optional
	if posixPath begins with "/System/Cryptexes" then return {} -- skip cryptographically sealed extensions
	return ((|+|'s NSFileManager's defaultManager)'s enumeratorAtURL:(|+|'s NSURL's fileURLWithPath:((|+|'s NSString's stringWithString:posixPath)'s stringByAppendingPathComponent:subfolder)) includingPropertiesForKeys:resourceKeys options:options errorHandler:(missing value))'s allObjects()
end getFolderContents

# Return a formatted 24 hour string (hh:mm:ss) from a number of seconds -- see `unformatTime`.
to formatTime(theSeconds as integer)
	if theSeconds < 0 then set theSeconds to 0
	tell "000000" & (10000 * (theSeconds mod days div hours) + ¬
		100 * (theSeconds mod hours div minutes) + ¬
		(theSeconds mod minutes)) ¬
		to return (text -6 thru -5) & ":" & (text -4 thru -3) & ":" & (text -2 thru -1) -- wraps at 24 hours
end formatTime

# Return a number of seconds from a formatted 24 hour string - see `formatTime`.
to unformatTime(formattedString as text)
	tell formattedString to set {hh, mm, ss} to {text 1 thru 2, text 4 thru 5, text 7 thru 8}
	return (hh * 3600) + (mm * 60) + ss
end unformatTime

# Format a floating point number for display, rounding away from 0.
to formatFloat(float as real)
	tell |+|'s NSNumberFormatter's alloc()'s init()
		its setMinimumFractionDigits:3
		return its stringFromNumber:float
	end tell
end formatFloat

# Filter a bundle ID candidate to only lower case and allowed characters.
to filterID(candidate as text)
	set {theResult, charList} to {"", characters of "-.etaoinshrdlucmfwgypbvkxjqz0123456789"} -- letters in frequency order
	repeat with aChar in (get characters of candidate)
		set output to "-" -- substitution character
		tell (contents of aChar) to if it is in charList then repeat with indx from 1 to 38 -- (count charList)
			set match to contents of (item indx of charList)
			if it is match then -- ignores case
				set output to match
				exit repeat
			end if
		end repeat
		set theResult to theResult & output
	end repeat
	return theResult
end filterID

# Common error dialog.
to showAlert from (aHandler as text) for (errmess as text) given errnum:errnum as text : "", givingUpAfter:giveUpTime as integer : 0 -- given parameters are optional
	set handlerText to ""
	if aHandler is not in {"", missing value} then set handlerText to " in the " & quoted form of aHandler & " handler."
	if errnum is not "" then set errnum to " (" & errnum & ")"
	activate me
	display alert "Script Error" & handlerText message errmess & errnum giving up after giveUpTime
end showAlert


##############################
-->> User Handlers
##############################

to doOptionClick() -- handle a statusItem button option/right-click - the regular menu is not shown
	try
		activate me
		|+|'s NSApp's orderFrontStandardAboutPanel:me -- or whatever
		# This can be called multiple times, so it should check to see if whatever is still running.
	on error errmess number errnum
		showAlert from "doOptionClick" for errmess given errnum:errnum, givingUpAfter:5
	end try
end doOptionClick

to doAltActions() -- experimental support for user actions - repeatedly called by `updateCountdown` if `altActions` is true
	try -- condition expression should be specific to prevent repeated script runs - return true to exit the current update
		return false -- still experimenting...
		if countdown is -(10 * minutes) then -- example #1: check for a negative value (still running and late)
			display notification "Reminder: The countdown expired 10 minutes ago." with title appName sound name "Basso" -- whatever - note that notifications for the script editor will need to be enabled
		end if
		if countdown is 5 then -- example #2: run the action script (assumes one of the Test scripts) at a specific countdown
			if (runScript from scriptPath given arguments:countdown) is in {missing value, "restart"} then return true
			# note that the `scriptPath` property contains the POSIX path of the (saved) user script in `userScriptsFolder`
		end if
	on error errmess number errnum -- handle a script or other error
		showAlert from "doAltActions" for errmess given errnum:errnum
		my startStop:(missing value) -- stop the countdown
		return true -- exit current update
	end try
	return false -- don't exit (default)
end doAltActions

