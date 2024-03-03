
# NSAlert dialogs - simple and with support for fonts, countdown timer, and an accessory view.
# An example follows the handler and script object.


use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


# Minimal handler to make and return an NSAlert (or its button result).
# Button titles ending with return have destructiveAction set.
to makeAlert for messageText as text : "" given infoText:infoText as text : "", buttons:buttons as list : {"OK"}, icon:icon as text : "", showing:showing as boolean : false
	tell current application's NSAlert's alloc()'s init()
		if messageText is not in {"", "missing value"} then its setMessageText:messageText
		if infoText is not in {"", "missing value"} then its setInformativeText:infoText
		repeat with aButton in buttons
			set theButton to (its addButtonWithTitle:aButton)
		end repeat
		if icon is not in {"", "missing value"} then -- set icon
			set candidate to current application's NSImage's alloc()'s initByReferencingFile:icon
			if (candidate's isValid as boolean) then -- file
				its setIcon:candidate
			else if icon is "critical" then -- critical style, otherwise informational
				its setAlertStyle:(current application's NSCriticalAlertStyle)
			end if
		end if
		if showing then -- show the alert?
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
	to performAlert for messageText as text : "" given messageFont:messageFont : missing value, messageColor:messageColor : missing value, infoText:infoText as text : "", infoFont:infoFont : missing value, infoColor:infoColor : missing value, buttons:buttons as list : {"OK"}, icon:icon as text : "", accessory:accessory : missing value, givingUpAfter:givingUpAfter as integer : 0
		set my alert to current application's NSAlert's alloc()'s init()
		alert's |window|'s setAutorecalculatesKeyViewLoop:true -- hook any added views into the key-view loop
		alert's setMessageText:adjustFonts(messageText, {messageFont, messageColor, infoFont, infoColor})
		if infoText is not in {"", "missing value"} then alert's setInformativeText:infoText
		if givingUpAfter > 0 then set my giveUpTime to givingUpAfter
		set my buttonList to setButtons(buttons) -- use updated button names (destructive action, etc)
		if icon is not in {"", "missing value"} then setIcon(icon)
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
			timerField's setStringValue:""
			set {timer, my countdown} to {missing value, missing value}
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
			if messageText is in {"", "missing value"} then -- can't be nil in earlier systems, so just make it really small
				set messageText to ""
				its setFont:(current application's NSFont's systemFontOfSize:0.1)
			else
				if messageFont is not missing value then its setFont:messageFont -- NSFont
				if messageColor is not missing value then its setTextColor:messageColor -- NSColor
			end if
		end tell
		tell alert's |window|'s contentView's subviews's item 6
			if infoFont is not missing value then its setFont:infoFont -- NSFont
			if infoColor is not missing value then its setTextColor:infoColor -- NSColor
		end tell
		return messageText
	end adjustFonts
	
	# Set the alert button(s).
	# Key equivalents are return for right/top button, escape for button titled "Cancel", first button has focus.
	# Button names ending with return have their hasDestructiveAction property set.
	to setButtons(buttons as list)
		set buttonNames to {}
		set buttons to (current application's NSOrderedSet's orderedSetWithArray:buttons)'s allObjects() as list -- remove duplicates
		if buttons is {} then set buttons to {okButton}
		repeat with indx from 1 to (count buttons)
			set aButton to (item indx of buttons) as text
			set destructive to (aButton ends with return)
			if destructive then set aButton to text 1 thru -2 of aButton
			if aButton is not in {"", "missing value"} then -- skip missing titles
				set end of buttonNames to aButton
				set theButton to (alert's addButtonWithTitle:aButton)
				if destructive and (theButton's respondsToSelector:"hasDestructiveAction") then (theButton's setHasDestructiveAction:true)
				if indx is 1 then (theButton's setKeyEquivalent:return)
			end if
		end repeat
		return buttonNames
	end setButtons
	
	# Set the alert icon to one of the defaults or an image file.
	to setIcon(icon as text)
		if icon is in {"", "missing value"} then return
		if icon is "critical" then
			alert's setAlertStyle:(current application's NSCriticalAlertStyle)
		else if icon is in {"informational", "warning"} then
			alert's setAlertStyle:(current application's NSInformationalAlertStyle)
		else if icon is "caution" then
			set alert's icon to current application's NSImage's imageNamed:(current application's NSImageNameCaution)
		else -- from a file
			set iconImage to current application's NSImage's alloc()'s initByReferencingFile:icon
			if (iconImage is not missing value) and (iconImage's isValid as boolean) then set alert's icon to iconImage
		end if
	end setIcon
	
	# Set up the timer textField and give up timer.
	to setupTimer(giveUpTime as integer)
		if giveUpTime < 1 then return missing value
		set my timerField to current application's NSTextField's alloc()'s initWithFrame:{{0, 0}, {40, 20}}
		timerField's setBordered:false
		timerField's setDrawsBackground:false
		timerField's setFont:(current application's NSFont's fontWithName:"Menlo Bold" |size|:14)
		timerField's setEditable:false
		timerField's setAlignment:(current application's NSCenterTextAlignment)
		timerField's setToolTip:"Time Remaining"
		positionTimerField(timerField)
		tell (current application's NSTimer's timerWithTimeInterval:1 target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true)
			set my countdown to giveUpTime
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
		set {{originX, originY}, {_, _}} to ((first item of alert's |window|'s contentView's subviews)'s frame as list)
		timerField's setFrameOrigin:{originX + padding, originY - 18}
		alert's |window|'s contentView's addSubview:timerField
	end positionTimerField
	
	# Update the countdown timer display.
	to updateCountdown:timer
		set my countdown to countdown - 1
		if countdown ≤ 0 then -- stop and reset for next time
			timer's invalidate()
			timerField's setStringValue:""
			set {timer, my countdown} to {missing value, missing value}
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
		set theButtons to {"Foo", "Bar", "Cancel"}
		
		tell (makeAlert for "Simple Alert" given infoText:"whatever", icon:"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns", buttons:theButtons)
			its setAccessoryView:(current application's NSView's alloc()'s ¬
				initWithFrame:(current application's NSMakeRect(0, 0, 800, 0))) -- make wider
			its (|window|'s orderFront:me) -- show it
			its (|window|'s setFrameOrigin:{0, 300}) -- move it
			set indx to (its runModal() as integer) - 999 -- run it (the first button is 1000)
			log item indx of theButtons
			if item indx of theButtons is "Cancel" then error number -128 -- manually cancel
		end tell
		
		# use AlertController script object/class
		set theButtons to {"OK", "Test" & return, missing value, "One", "Cancel", "One", "Foo", "Bar"}
		set loremText to "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque vestibulum venenatis velit, non commodo diam pretium sed. Etiam viverra erat a lacus molestie id euismod magna lacinia. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vestibulum ac augue magna, eu pharetra leo. Donec tortor tortor, tristique in ornare nec, feugiat vel justo. Nunc iaculis interdum pellentesque. Quisque vel rutrum nibh. Phasellus malesuada ipsum quis diam ullamcorper rutrum. Nullam tincidunt porta ante, in aliquet odio molestie eget. Donec mollis, nibh euismod pulvinar fermentum, magna nunc consectetur risus, id dictum odio leo non velit. Vestibulum vitae nunc pulvinar augue commodo sollicitudin."
		set accessory to makeButtonGroup at {0, 0} with radio given boxWidth:350, itemList:{"foo", "bar 0123456789012345678901234567890" & return, "baz", "One", "Two"} -- example
		
		tell AlertController
			# show initial alert
			its (performAlert for "Alert" given infoText:loremText, infoColor:(current application's NSColor's orangeColor), buttons:theButtons, accessory:accessory, givingUpAfter:10)
			my (setResponse from it given value:my accessoryValues(accessory))
			log response
			
			tell its alert -- alter the script's NSAlert object
				its setMessageText:"AlertController's alert can be altered and run again" -- use API
				its setInformativeText:""
				(its first item of buttons)'s setKeyEquivalent:return -- reset default and cancel key equivalents
				repeat with aButton in rest of (its buttons as list)
					if aButton's title as text is AlertController's cancelButton then
						(aButton's setKeyEquivalent:(character id 27))
						exit repeat
					end if
				end repeat
			end tell
			
			# show altered alert	
			its showAlert() -- use script to show it again and update button pressed
			my (setResponse from it without cancel given value:my accessoryValues(accessory))
			log response
		end tell
		
	on error errmess
		display alert "Error with doing stuff" message errmess
	end try
end doStuff


##################################################
#	Example accessory view handlers
##################################################

# Set the alert response - cancel argument determines if an error is thrown for the cancel button.
on setResponse from alert given value:value : missing value, cancel:cancel as boolean : true
	set value to item (((alert's buttonPressed is alert's cancelButton) as integer) + 1) of {value, missing value}
	set my response to {button:alert's buttonPressed, accessory:value} -- whatever
	if button of response is alert's cancelButton and cancel then error number -128 -- manual cancel
end setResponse

# Return a record (or list of records) for the accessory view item(s).
# Customized for the accessory view UI item(s) created in the makeButtonGroup handler below.
on accessoryValues(accessory)
	if accessory is missing value then return missing value
	set values to current application's NSMutableDictionary's alloc()'s init()
	repeat with aView in (accessory's contentView's subviews)
		tell values to setValue:(aView's state) forKey:(aView's title)
	end repeat
	return values as record
end accessoryValues

# Make and return an NSBox containing a group of checkbox or radio buttons.
on makeButtonGroup at origin as list given radio:radio as boolean : true, boxWidth:boxWidth : 100, itemList:itemList as list : {}, title:title as text : "", titlePosition:titlePosition as integer : 0, lineBreakMode:lineBreakMode as integer : 5, baseTag:baseTag as integer : 0, action:action as text : "buttonGroupAction:", target:target : missing value
	set {buttonHeight, padding, tag} to {24, 15, 0}
	set boxHeight to (count itemList) * buttonHeight + padding
	if titlePosition is not 0 then set boxHeight to boxHeight + 12 -- box + default label height
	set theBox to current application's NSBox's alloc()'s initWithFrame:{origin, {boxWidth, boxHeight}}
	if title is not in {"", "missing value"} then theBox's setTitle:title
	theBox's setTitlePosition:titlePosition
	set itemList to (current application's NSOrderedSet's orderedSetWithArray:itemList)'s allObjects() as list -- remove duplicates
	repeat with itemIndex from 1 to (count itemList)
		if baseTag is not 0 then set tag to baseTag + itemIndex -- group using a base tag
		tell (makeGroupButton at origin given radio:radio, buttonName:(item itemIndex of itemList), lineBreakMode:lineBreakMode, tag:tag, action:action, target:target)
			(its setFrame:{{padding, (itemIndex - 1) * buttonHeight}, {boxWidth - (padding * 2), buttonHeight}})
			(theBox's addSubview:it)
		end tell
	end repeat
	return theBox
end makeButtonGroup

# Make an individual checkbox or radio button.
to makeGroupButton at origin given radio:radio as boolean : true, width:width as real : 100, buttonName:buttonName as text : "Button", lineBreakMode:lineBreakMode as integer : 5, tag:tag as integer : 0, action:action as text : "buttonGroupAction:", target:target : missing value
	if action is not in {"", "missing value"} and target is missing value then set target to me
	if radio then
		set button to current application's NSButton's radioButtonWithTitle:"" target:target action:action
	else
		set button to current application's NSButton's checkboxWithTitle:"" target:target action:action
	end if
	if buttonName ends with return then -- set/check the button
		button's setState:(current application's NSOnState) # NSControlStateValueOn
		set buttonName to text 1 thru -2 of buttonName
	end if
	button's setTitle:buttonName
	button's setFrame:{origin, {width, 24}}
	button's setLineBreakMode:lineBreakMode
	if tag > 0 then button's setTag:tag
	if action is not in {"", "missing value"} then
		if target is missing value then set target to me -- 'me' can't be used as an optional default
		button's setTarget:target
		button's setAction:action
	end if
	return button
end makeGroupButton

# Perform an action when a button in the group is pressed (required for radio buttons in a matrix).
on buttonGroupAction:sender
	-- whatever
end buttonGroupAction:

# Return a record of the button titles and states from the enclosing box.
to getGroupButtons from buttonGroupView given onlySelected:onlySelected as boolean : true
	set buttons to current application's NSMutableDictionary's alloc()'s init()
	repeat with anItem in buttonGroupView's contentView's subviews
		if (anItem's state) as integer is 1 or onlySelected then ¬
			tell buttons to setValue:(anItem's state) forKey:(anItem's title)
	end repeat
	return buttons as record
end getGroupButtons

