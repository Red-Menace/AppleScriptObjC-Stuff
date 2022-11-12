
# NSAlert dialogs - simple and with support for fonts, countdown timer, and an accessory view.
# An example follows the handler and script object.


use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


# Minimal handler to make and return an NSAlert (or its button result).
# Button titles ending with return have destructiveAction set.
to makeAlert for messageText given infoText:infoText : (missing value), buttons:buttons : {"OK"}, icon:icon : missing value, showing:showing : false
	tell current application's NSAlert's alloc's init()
		if messageText is not missing value then its setMessageText:(messageText as text)
		if infoText is not missing value then its setInformativeText:(infoText as text)
		repeat with aButton in (buttons as list)
			set theButton to (its addButtonWithTitle:aButton)
		end repeat
		if icon is not missing value then -- set icon
			set candidate to current application's NSImage's alloc's initByReferencingFile:icon
			if (candidate's isValid as boolean) then -- file
				its setIcon:candidate
			else if icon is "critical" then -- critical style, otherwise informational
				its setAlertStyle:(current application's NSCriticalAlertStyle)
			end if
		end if
		if showing is true then -- show the alert?
			return its runModal() as integer -- the button result (starts at 1000)
		else
			return it -- just the NSAlert object
		end if
	end tell
end makeAlert


# A script object/class for creating/displaying an enhanced NSAlert.
# The caller handles any accessory view.
script AlertController
	
	property okButton : "OK" -- a name for the OK button
	property cancelButton : "Cancel" -- the cancel button name
	
	property alert : missing value -- this will be the alert object
	property timerField : missing value -- this will be a countdown textField
	property giveUpTime : missing value -- this will be the give up time (in seconds)
	property countdown : missing value -- this will be the remaining time before alert is dismissed
	property buttonList : missing value -- this will be a list of the button names
	property buttonPressed : missing value -- this will be the name of the button pressed
	
	# The main handler to configure and perform an alert.
	# The buttonPressed property will be the name of the button pressed (or 'gave up' if time has expired).
	to performAlert for messageText given messageFont:messageFont : missing value, messageColor:messageColor : missing value, infoText:infoText : "", infoFont:infoFont : missing value, infoColor:infoColor : missing value, buttons:buttons : {"OK"}, icon:icon : missing value, accessory:accessory : missing value, givingUpAfter:givingUpAfter : missing value
		set my alert to current application's NSAlert's alloc's init()
		alert's |window|'s setAutorecalculatesKeyViewLoop:true -- hook any added views into the key-view loop
		alert's setMessageText:adjustFonts(messageText, {messageFont, messageColor, infoFont, infoColor})
		if infoText is not missing value then alert's setInformativeText:(infoText as text)
		if givingUpAfter is not in {0, missing value} then set my giveUpTime to givingUpAfter
		set my buttonList to setButtons(buttons) -- use updated button names (destructive action, etc)
		if icon is not missing value then setIcon(icon)
		if accessory is not missing value then alert's setAccessoryView:accessory
		showAlert()
	end performAlert
	
	# Show the current alert and get the button pressed.
	# This handler is kept separate so that the alert can be shown again.
	to showAlert()
		set button to getButtonPress(setupTimer(giveUpTime)) -- do it
		if button < 0 then
			set button to "gave up"
		else
			set button to item button of buttonList -- index using button number
		end if
		set my buttonPressed to button
	end showAlert
	
	##################################################
	#	Alert response handlers
	##################################################
	
	# Get the number of the button pressed - a negative number is returned if timed out (gave up).
	to getButtonPress(timer)
		if timer is not missing value then current application's NSRunLoop's mainRunLoop's addTimer:timer forMode:(current application's NSModalPanelRunLoopMode) -- start it
		set button to (alert's runModal() as integer) - 999 -- first button returns 1000
		if timer is not missing value then -- reset for next time
			timer's invalidate()
			set {timer, timerField, countdown} to {missing value, missing value, missing value}
		end if
		return button
	end getButtonPress
	
	##################################################
	#	Alert set up handlers
	##################################################
	
	# Adjust the message and informative text field font and colors.
	to adjustFonts(messageText, fontInfo)
		set {messageFont, messageColor, infoFont, infoColor} to fontInfo
		tell alert's |window|'s contentView's subviews's item 5
			if messageText is in {missing value, ""} then -- can't be nil, so just make it really small
				set messageText to ""
				its setFont:(current application's NSFont's systemFontOfSize:0.25)
			else
				if messageFont is not missing value then its setFont:messageFont
				if messageColor is not missing value then its setTextColor:messageColor
			end if
		end tell
		tell alert's |window|'s contentView's subviews's item 6
			if infoFont is not missing value then its setFont:infoFont
			if infoColor is not missing value then its setTextColor:infoColor
		end tell
		return messageText as text
	end adjustFonts
	
	# Set the alert button(s).
	# The key equivalent for the first button is return, any button titled "Cancel" is escape.
	# Button names ending with return have their hasDestructiveAction property set.
	to setButtons(buttons)
		set buttonNames to {}
		set buttons to (current application's NSOrderedSet's orderedSetWithArray:(buttons as list))'s allObjects() as list -- remove duplicates
		repeat with aButton in buttons
			set aButton to aButton as text
			set destructive to (aButton ends with return)
			if destructive then set aButton to text 1 thru -2 of aButton
			if aButton is not in {"", "missing value"} then -- skip missing titles
				set end of buttonNames to aButton
				set theButton to (alert's addButtonWithTitle:aButton)
				if destructive and (theButton's respondsToSelector:"hasDestructiveAction") then (theButton's setHasDestructiveAction:true)
			end if
		end repeat
		if buttonNames is {} then -- make sure there is at least one
			set end of buttonNames to okButton
			set theButton to (alert's addButtonWithTitle:okButton)
		end if
		alert's |window|'s setInitialFirstResponder:theButton
		return buttonNames
	end setButtons
	
	# Set the alert icon to one of the defaults or an image file.
	to setIcon(icon)
		if icon is missing value then return
		if icon is "critical" then
			alert's setAlertStyle:(current application's NSCriticalAlertStyle)
		else if icon is in {"informational", "warning"} then
			alert's setAlertStyle:(current application's NSInformationalAlertStyle)
		else -- from a file
			set iconImage to current application's NSImage's alloc's initByReferencingFile:(icon as text)
			if (iconImage is not missing value) and (iconImage's isValid as boolean) then set alert's icon to iconImage
		end if
	end setIcon
	
	# Set up the timer textField and give up timer.
	to setupTimer(giveUpTime)
		if class of giveUpTime is not in {integer, real} or giveUpTime < 1 then return missing value
		set my timerField to current application's NSTextField's alloc's initWithFrame:{{0, 0}, {40, 20}}
		timerField's setBordered:false
		timerField's setDrawsBackground:false
		timerField's setFont:(current application's NSFont's fontWithName:"Menlo Bold" |size|:14)
		timerField's setEditable:false
		timerField's setAlignment:(current application's NSCenterTextAlignment)
		timerField's setToolTip:"Time Remaining"
		positionTimerField(timerField)
		tell (current application's NSTimer's timerWithTimeInterval:1 target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true)
			set countdown to (giveUpTime as integer)
			timerField's setStringValue:(countdown as text)
			return it
		end tell
	end setupTimer
	
	# Set up the timer textField's frame for the icon location.
	# Icon is centered at the top for Big Sur and later,
	# to the left of the text fields for previous versions.
	to positionTimerField(timerField)
		if timerField is missing value then return
		set padding to 13
		alert's layout() -- get current layout
		set spacing to first item of ((first item of alert's |window|'s contentView's subviews)'s frame as list)
		timerField's setFrameOrigin:{(first item of spacing) + padding, (second item of spacing) - 18}
		alert's |window|'s contentView's addSubview:timerField
	end positionTimerField
	
	# Update the countdown timer display.
	to updateCountdown:timer
		set countdown to countdown - 1
		if countdown ≤ 0 then -- stop and reset for next time
			timer's invalidate()
			set {timer, my timerField, my countdown} to {missing value, missing value, missing value}
			current application's NSApp's abortModal()
		else
			timerField's setStringValue:(countdown as text)
		end if
	end updateCountdown:
	
end script


(*
	----- Examples -----
	
	Typical operation for script object/class:
		• set up accessory view as needed
		• create/show the alert
		• get accessory values as needed
		
	Note that an NSAlert can be shown at a specified location by first showing
	its window (this is included in the example), but since alerts are typically
	centered this is left up to the user.
	
	The NSAlert window will also increase its width to contain an accessory view,
	but this can get ugly with the center alignment and vertical orientation.

*)


property response : missing value -- performSelectorOnMainThread doesn't return anything

on run -- example can be run as app and from Script Editor
	if current application's NSThread's isMainThread() as boolean then
		doStuff()
	else
		my performSelectorOnMainThread:"doStuff" withObject:(missing value) waitUntilDone:true
	end if
	return response
end run

to doStuff() -- UI stuff needs to be done on the main thread
	try
		# use 'makeAlert' handler
		set theButtons to {"One", "Two", "Cancel"}
		
		set theAlert to (makeAlert for "Simple Alert" given infoText:"whatever", icon:"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns", buttons:theButtons)
		theAlert's setAccessoryView:(current application's NSView's alloc's ¬
			initWithFrame:(current application's NSMakeRect(0, 0, 800, 0))) -- make wider
		theAlert's |window|'s orderFront:me -- show it
		theAlert's |window|'s setFrameOrigin:{0, 300} -- move it
		set indx to (theAlert's runModal() as integer) - 999 -- run it (the first button is 1000)
		if item indx of theButtons is AlertController's cancelButton then error number -128 -- manually cancel
		
		# use AlertController script object/class
		set theButtons to {"OK", "Test" & return, missing value, "One", "One", "One"}
		set loremText to "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque vestibulum venenatis velit, non commodo diam pretium sed. Etiam viverra erat a lacus molestie id euismod magna lacinia. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vestibulum ac augue magna, eu pharetra leo. Donec tortor tortor, tristique in ornare nec, feugiat vel justo. Nunc iaculis interdum pellentesque. Quisque vel rutrum nibh. Phasellus malesuada ipsum quis diam ullamcorper rutrum. Nullam tincidunt porta ante, in aliquet odio molestie eget. Donec mollis, nibh euismod pulvinar fermentum, magna nunc consectetur risus, id dictum odio leo non velit. Vestibulum vitae nunc pulvinar augue commodo sollicitudin."
		
		set accessory to makeButtonGroup at {0, 0} with radio given boxWidth:350, itemList:{"foo", "bar 0123456789012345678901234567890" & return, "baz"} -- example
		AlertController's (performAlert for "Alert" given infoText:loremText, infoColor:(current application's NSColor's orangeColor), buttons:theButtons, accessory:accessory, givingUpAfter:10)
		# performSelectorOnMainThread doesn't return anything
		set response to {AlertController's buttonPressed, accessoryValues(accessory)} -- whatever
		
		tell AlertController's alert -- alter the script's NSAlert object
			its setMessageText:"AlertController's alert can be altered and run again" -- use API
			its setInformativeText:""
		end tell
		AlertController's showAlert() -- use script to show it again and update button pressed
		set response to {AlertController's buttonPressed, accessoryValues(accessory)} -- whatever
		log response -- whatever
		
	on error errmess
		display alert "Error with doing stuff" message errmess
	end try
end doStuff


##################################################
#	Example accessory view handlers
##################################################

# Return a record (or list of records) for the accessory view item(s).
# Customized for the accessory view UI item(s) created in the makeButtonGroup handler below.
on accessoryValues(accessory)
	if accessory is missing value then return missing value
	set values to current application's NSMutableDictionary's alloc's init()
	repeat with aView in (accessory's contentView's subviews)
		tell values to setValue:(aView's state) forKey:(aView's title)
	end repeat
	return values as record
end accessoryValues

# Make and return an NSBox containing a group of checkbox or radio buttons.
on makeButtonGroup at origin given radio:radio : true, boxWidth:boxWidth : 100, itemList:itemList : {}, title:title : "", titlePosition:titlePosition : 0, lineBreakMode:lineBreakMode : 5, baseTag:baseTag : missing value, action:action : "buttonGroupAction:", target:target : missing value
	set {buttonHeight, padding, tag} to {24, 15, missing value}
	set boxHeight to (count itemList) * buttonHeight + padding
	if titlePosition is not 0 then set boxHeight to boxHeight + 12 -- box + default label height
	set theBox to current application's NSBox's alloc's initWithFrame:{origin, {boxWidth, boxHeight}}
	if title is not in {"", missing value} then theBox's setTitle:(title as text)
	theBox's setTitlePosition:titlePosition
	set itemList to (current application's NSOrderedSet's orderedSetWithArray:itemList)'s allObjects() as list -- remove duplicates
	repeat with itemIndex from 1 to (count itemList)
		if baseTag is not missing value then set tag to baseTag + itemIndex -- group using a base tag
		tell (makeGroupButton at origin given radio:radio, buttonName:(item itemIndex of itemList), lineBreakMode:lineBreakMode, tag:tag, action:action, target:target)
			(its setFrame:{{padding, (itemIndex - 1) * buttonHeight}, {boxWidth - (padding * 2), buttonHeight}})
			(theBox's addSubview:it)
		end tell
	end repeat
	return theBox
end makeButtonGroup

# Make an individual checkbox or radio button.
to makeGroupButton at origin given radio:radio : true, width:width : 100, buttonName:buttonName : "Button", lineBreakMode:lineBreakMode : 5, tag:tag : missing value, action:action : "buttonGroupAction:", target:target : missing value
	if action is not missing value and target is missing value then set target to me
	if radio then
		set button to current application's NSButton's radioButtonWithTitle:"" target:target action:(action as text)
	else
		set button to current application's NSButton's checkboxWithTitle:"" target:target action:(action as text)
	end if
	set buttonName to buttonName as text
	if buttonName ends with return then -- set/check the button
		button's setState:(current application's NSOnState) # NSControlStateValueOn
		set buttonName to text 1 thru -2 of buttonName
	end if
	button's setTitle:buttonName
	button's setFrame:{origin, {width, 24}}
	button's setLineBreakMode:lineBreakMode
	if tag is not missing value then button's setTag:tag
	if action is not missing value then
		if target is missing value then set target to me -- 'me' can't be used as an optional default
		button's setTarget:target
		button's setAction:(action as text)
	end if
	return button
end makeGroupButton

# Perform an action when a button in the group is pressed (required for radio buttons in a matrix).
on buttonGroupAction:sender
	-- whatever
end buttonGroupAction:

# Return a record of the button titles and states from the enclosing box.
to getGroupButtons from buttonGroupView given onlySelected:onlySelected : true
	set buttons to current application's NSMutableDictionary's alloc's init()
	repeat with anItem in buttonGroupView's contentView's subviews
		if (anItem's state) as integer is 1 or onlySelected is false then ¬
			tell buttons to setValue:(anItem's state) forKey:(anItem's title)
	end repeat
	return buttons as record
end getGroupButtons

