
#
#	NSAlert dialogs - plain and enhanced with support for fonts, countdown timer, and an accessory view.
#	Tested with older systems as far back as 10.12 Sierra, which use the original horizontal orientation.
#	Examples follow the handler and script object, which can also be used as a script library.
#


use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


# ================================================== NSAlert Handler ==================================================

#
# Minimal handler to make and return a NSAlert (or its button result).
#

to makeAlert for messageText as text : "" given infoText:infoText as text : "", buttons:buttons as list : {"OK"}, icon:icon as text : "", showing:showing as boolean : false
	tell current application's NSAlert's alloc()'s init()
		if messageText is not "" then its setMessageText:messageText
		if infoText is not "" then its setInformativeText:infoText
		repeat with aButton in buttons
			set theButton to (its addButtonWithTitle:aButton)
		end repeat
		if icon is not "" then
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


# =============================================== NSAlert Script Object ===============================================

#
# A script object/class for creating/displaying an enhanced NSAlert.
# Script objects must be declared before their use.
# The caller handles any accessory view.
#

script AlertController
	
	property okButton : "OK" -- a name for the OK button
	property cancelButton : "Cancel" -- the cancel button name
	
	# outlets and script properties
	property alert : missing value -- this will be the alert object
	property timerField : missing value -- this will be a countdown textField
	property giveUpTime : missing value -- this will be the give up time (in seconds)
	property countdown : missing value -- this will be the remaining time before alert is dismissed
	property buttonList : missing value -- this will be a list of the alert buttons (for title, hasDestructiveAction, etc)
	property response : missing value -- this will be an index from the modal response or -1 if gave up time expired
	
	# The main handler to configure and perform the alert.
	to performAlert for messageText as text : "" given messageFont:messageFont : missing value, messageColor:messageColor : missing value, infoText:infoText as text : "", infoFont:infoFont : missing value, infoColor:infoColor : missing value, buttons:buttons as list : {"OK"}, icon:icon as text : "", accessory:accessory : missing value, givingUpAfter:givingUpAfter as integer : 0
		set my alert to current application's NSAlert's alloc()'s init()
		alert's |window|'s setAutorecalculatesKeyViewLoop:true -- hook any added views into the key-view loop
		alert's setMessageText:adjustFonts(messageText, {messageFont, messageColor, infoFont, infoColor})
		if infoText is not "" then alert's setInformativeText:infoText
		setButtons(buttons)
		if icon is not "" then setIcon(icon)
		if accessory is not missing value then alert's setAccessoryView:accessory
		if givingUpAfter > 0 then set my giveUpTime to givingUpAfter
		showAlert()
	end performAlert
	
	# Show the alert with the current settings and get the button pressed.
	# This handler is kept separate so that the alert can be shown again.
	to showAlert()
		set response to getResponseIndex(setupTimer(giveUpTime)) -- get modal response
		if response < 0 then
			set buttonName to "gave up"
		else
			set buttonName to (item response of buttonList)'s title as text
		end if
		return buttonName
	end showAlert
	
	##################################################
	#	Alert response handlers
	##################################################
	
	# Get the index of the button pressed - a negative number is returned if timed out (gave up).
	# Sets the response property.
	to getResponseIndex(timer)
		if timer is not missing value then current application's NSRunLoop's mainRunLoop's addTimer:timer forMode:(current application's NSModalPanelRunLoopMode) -- start it
		set buttonIndex to (alert's runModal() as integer) - 999 -- first button returns 1000
		if buttonIndex < 0 then set buttonIndex to -1 -- stopModal/abortModal return -1000/-1001
		if timer is not missing value then -- reset for next time
			timer's invalidate()
			timerField's setStringValue:""
			set {timer, my countdown} to {missing value, missing value}
		end if
		set my response to buttonIndex
	end getResponseIndex
	
	# Return the title and hasDestructiveAction properties (if available) of the button pressed.
	to getButtonValues()
		set available to (current application's NSButton's instancesRespondToSelector:"hasDestructiveAction") as boolean
		set destructive to {}
		if response < 0 or response is missing value then
			set title to item (((response is missing value) as integer) + 1) of {"gave up", missing value}
			if available then set destructive to {destructiveAction:missing value}
		else
			tell (item response of buttonList)
				set title to its title as text
				if available then set destructive to {destructiveAction:(its hasDestructiveAction) as boolean}
			end tell
		end if
		
		return {button:title} & destructive
	end getButtonValues
	
	##################################################
	#	Alert set up handlers
	##################################################
	
	# Adjust the message and informative text field font and colors.
	to adjustFonts(messageText as text, fontInfo)
		set {messageFont, messageColor, infoFont, infoColor} to fontInfo
		tell alert's |window|'s contentView's subviews's item 5
			if messageText is "" then -- space always used in earlier systems, so just make it small
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
	
	# Set the alert button(s) and buttonList property.
	# Key equivalents are return for right/top button, escape for button titled "Cancel", first button has focus.
	# Button titles ending with return will have their hasDestructiveAction property set.
	to setButtons(buttons as list)
		tell (current application's NSMutableOrderedSet's orderedSetWithArray:buttons) -- remove duplicates...
			its removeObjectsInArray:{"", {}, missing value, "missing value"} -- ...and empty items
			set buttons to its allObjects() as list
		end tell
		if buttons is {} then set buttons to {okButton}
		set available to (current application's NSButton's instancesRespondToSelector:"hasDestructiveAction") as boolean
		set alertButtons to {}
		repeat with indx from 1 to (count buttons)
			set aButton to (item indx of buttons) as text
			set destructive to (aButton ends with return)
			if destructive then set aButton to text 1 thru -2 of aButton -- remove flag
			set theButton to (alert's addButtonWithTitle:aButton)
			if destructive and available then (theButton's setHasDestructiveAction:true)
			if indx is 1 then (theButton's setKeyEquivalent:return)
			set end of alertButtons to theButton
		end repeat
		set my buttonList to alertButtons
	end setButtons
	
	# Set the alert icon to one of the defaults or an image file.
	to setIcon(icon as text)
		if icon is "" then return -- default/normal (NSAlertStyleInformational and NSAlertStyleWarning)
		if icon is "critical" then -- badge on caution icon
			alert's setAlertStyle:(current application's NSAlertStyleCritical)
		else if icon is "caution" then -- system icon no badge
			set alert's icon to current application's NSImage's imageNamed:(current application's NSImageNameCaution)
		else if icon is in {"note", "stop"} then -- system alert icons no badge
			set alert's icon to current application's NSImage's alloc()'s initByReferencingFile:("/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Alert" & icon & "Icon.icns")
		else -- from a file - initByReferencingFile handles errors better
			set iconImage to current application's NSImage's alloc()'s initByReferencingFile:icon
			if (iconImage is not missing value) and (iconImage's isValid as boolean) then set alert's icon to iconImage
		end if
	end setIcon
	
	# Set up the timer textField and give up timer; sets the timerField and countdown properties.
	# For proper alignment, must be called before setting the accessory view.
	to setupTimer(giveUpTime as integer)
		if giveUpTime < 1 then return missing value
		tell (current application's NSTextField's alloc()'s initWithFrame:{{0, 0}, {40, 20}})
			set my timerField to it
			its setBordered:false
			its setDrawsBackground:false
			its setFont:(current application's NSFont's fontWithName:"Menlo Bold" |size|:14)
			its setEditable:false
			its setAlignment:(current application's NSCenterTextAlignment)
			its setToolTip:"Time Remaining"
			my positionTimerField(it)
		end tell
		tell (current application's NSTimer's timerWithTimeInterval:1 target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true)
			set my countdown to giveUpTime
			timerField's setStringValue:(countdown as text)
			return it
		end tell
	end setupTimer
	
	# Position the timer textField's frame for the icon location.
	# Icon is centered at the top for Big Sur and later,
	# to the left of the text fields for previous versions.
	to positionTimerField(timerField)
		if timerField is missing value then return
		set padding to 13
		alert's layout() -- get current layout
		set {originX, originY} to ((first item of alert's |window|'s contentView's subviews)'s frameOrigin()) as list
		timerField's setFrameOrigin:{originX + padding, originY - 18}
		alert's |window|'s contentView's addSubview:timerField
	end positionTimerField
	
	# Update the countdown timer display.
	to updateCountdown:_timer
		set my countdown to countdown - 1
		if countdown ≤ 0 then -- reset - see getButtonPress
			current application's NSApp's abortModal()
		else
			timerField's setStringValue:(countdown as text)
		end if
	end updateCountdown:
	
end script


(*	===================================================== Examples =====================================================
	
	Uses the above handler and script object, handlers added for creating and getting values from an accessory view. 

	Typical operation for script object/class:
		• set up accessory view as needed
		• create/show the alert
		• get accessory values as needed
		
	A NSAlert can be shown at a specified location by first showing its window (this is included in the example),
	but since alerts are typically centered this is left up to the user.
	
	The NSAlert window will also increase its width to contain an accessory view, but this can get ugly with the
	center alignment and vertical orientation.  Note that some code for the earlier horizontal layout appears to
	still exist in the current API, but the conditions for its use are not reliable and may require positioning
	objects.  I stumbled across this while testing and left the settings for one of the examples - YMMV.

*)

# some example/testing properties
property loremText : "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque vestibulum venenatis velit, non commodo diam pretium sed. Etiam viverra erat a lacus molestie id euismod magna lacinia. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vestibulum ac augue magna, eu pharetra leo. Donec tortor tortor, tristique in ornare nec, feugiat vel justo. Nunc iaculis interdum pellentesque. Quisque vel rutrum nibh. Phasellus malesuada ipsum quis diam ullamcorper rutrum. Nullam tincidunt porta ante, in aliquet odio molestie eget. Donec mollis, nibh euismod pulvinar fermentum, magna nunc consectetur risus, id dictum odio leo non velit. Vestibulum vitae nunc pulvinar augue commodo sollicitudin."
property alertButtons : {"OK", "Test" & return, missing value, "", "One", "Cancel", "One", "Foo", "Bar"}
property boxButtons : {"foo", "bar 0123456789012345678901234567890" & return, "baz", "", missing value, "One", "One", "Two" & return}

# example result properties
property reply : missing value -- performSelectorOnMainThread doesn't return anything
property failure : missing value -- error record with keys {errorMessage, errorNumber, handlerName}


on run -- example can be run as app and from Script Editor
	try
		if current application's NSThread's isMainThread() as boolean then
			doStuff()
		else
			my performSelectorOnMainThread:"doStuff" withObject:(missing value) waitUntilDone:true
		end if
		if failure is not missing value then error
	on error errmess number errnum
		if failure is missing value then -- use passed arguments
			display alert "AlertLib Script Error " & errnum message errmess
		else -- use keys from the failure record
			display alert "AlertLib Script Error " & failure's errorNumber message quoted form of failure's errorMessage & " from handler " & failure's handlerName
		end if
		set failure to missing value -- reset any previous value before reshowing
		-- return missing value
	end try
	return reply
end run

to doStuff() -- UI stuff needs to be done on the main thread
	try -- set up some accessory stuff
		plainExample() -- use the individual handler
		set accessory to makeButtonGroup at {0, 0} without radio given itemList:boxButtons -- some buttons in a box
		enhancedExample(accessory) -- use the AlertController script object/class
	on error errmess number errnum
		if failure is missing value then set my failure to {errorMessage:errmess, errorNumber:errnum, handlerName:"doStuff:"}
		error errmess number errnum
	end try
end doStuff

on plainExample() -- use the 'makeAlert' handler
	try
		set theButtons to {"Foo", "Bar", "Cancel"}
		tell (makeAlert for "Simple Alert" given infoText:"Window has been relocated.", buttons:theButtons)
			its setAccessoryView:(current application's NSView's alloc()'s ¬
				initWithFrame:(current application's NSMakeRect(0, 0, 300, 0))) -- make wider
			its (|window|'s orderFront:me) -- show it
			its (|window|'s setFrameOrigin:{0, 300}) -- move it
			set indx to (its runModal() as integer) - 999 -- run it (the first button is 1000)
			log item indx of theButtons
			if item indx of theButtons is "Cancel" then error number -128 -- manual error from button name
		end tell
	on error errmess number errnum
		if failure is missing value then set my failure to {errorMessage:errmess, errorNumber:errnum, handlerName:"plainExample"}
		error errmess number errnum
	end try
end plainExample

on enhancedExample(accessory) -- use the 'AlertController' script object
	try
		tell AlertController
			its (performAlert for "Alert" given infoText:loremText, infoColor:(current application's NSColor's orangeColor), buttons:alertButtons, accessory:accessory, givingUpAfter:15, icon:"stop")
			my (setReply from it without onlySelected given accessory:accessory)
			log reply -- initial alert
			tell its alert -- alter the script's NSAlert object
				its setMessageText:"The previous alert has been altered and run again" -- use API
				its setInformativeText:""
				AlertController's setIcon("note")
				(its first item of buttons)'s setKeyEquivalent:return -- reset default and cancel key equivalents
				repeat with aButton in rest of (its buttons as list)
					if aButton's title as text is AlertController's cancelButton then
						(aButton's setKeyEquivalent:(character id 27))
						exit repeat
					end if
				end repeat
			end tell
			its showAlert() -- show it again and update button pressed
			my (setReply from its alert with onlySelected without cancel given accessory:accessory)
			log reply -- altered alert
		end tell
	on error errmess number errnum
		if failure is missing value then set my failure to {errorMessage:errmess, errorNumber:errnum, handlerName:"enhancedExample"}
		error errmess number errnum
	end try
end enhancedExample


##################################################
#	Example accessory view handlers
##################################################

# Set the alert reply - returns a record for the accessory view items.
# When true, the cancel argument will cause an error to be thrown if the cancel button has been pressed.
# The onlySelected argument returns items with a state of 1 when true, otherwise returns all.
# Customized for the accessory view UI item(s) created with the makeButtonGroup handler below.
on setReply from alert given accessory:accessory : missing value, cancel:cancel as boolean : true, onlySelected:onlySelected as boolean : true
	set alertResponse to AlertController's getButtonValues()
	set cancel to cancel and (alertResponse's button is AlertController's cancelButton)
	if not cancel and accessory is not missing value then
		set buttons to current application's NSMutableDictionary's alloc()'s init()
		repeat with anItem in (get accessory's contentView's subviews)
			if not onlySelected or (anItem's state) as integer is 1 then ¬
				tell buttons to setValue:(anItem's state) forKey:(anItem's title)
		end repeat
		set buttons to buttons as record
	else
		set buttons to missing value -- no items or cancel
	end if
	set my reply to alertResponse & {accessory:buttons} -- whatever
	if cancel then error number -128 -- manual "User canceled."
end setReply

# Make and return a NSBox containing a group of checkbox or radio buttons.
# NSControlSize values for controlSize will auto size, otherwise normal sized controls will be in a custom width box.
to makeButtonGroup at (origin as list) given radio:radio as boolean : true, controlSize:controlSize as integer : 0, itemList:itemList as list : {}, title:title as text : "", titlePosition:titlePosition as integer : 0, lineBreakMode:lineBreakMode as integer : 5, baseTag:baseTag as integer : 0, action:action as text : "buttonGroupAction:", target:target : missing value
	tell (current application's NSMutableOrderedSet's orderedSetWithArray:itemList) -- remove duplicates...
		its removeObjectsInArray:{"", {}, missing value, "missing value"} -- ...and empty items
		set itemList to its allObjects() as list
	end tell
	set {buttonHeight, padding, tag} to {24, 15, 0}
	set {width, itemCount} to {controlSize, (count itemList)}
	set boxHeight to itemCount * buttonHeight + padding
	if titlePosition is not 0 then set boxHeight to boxHeight + 12 -- box + default label height
	set theBox to current application's NSBox's alloc()'s initWithFrame:{origin, {controlSize, boxHeight}}
	if title is not "" then theBox's setTitle:title
	theBox's setTitlePosition:titlePosition
	repeat with itemIndex from 1 to itemCount
		if baseTag > 0 then set tag to baseTag + itemIndex -- group using a base tag
		tell (makeGroupButton at origin given radio:radio, controlSize:width, buttonName:(item itemIndex of itemList), lineBreakMode:lineBreakMode, tag:tag, action:action, target:target)
			set newWidth to ((current application's NSWidth(its frame)) as integer) + (padding * 2)
			if newWidth > controlSize then set controlSize to newWidth
			if width is not in {0, 1, 2, 3} then set controlSize to width
			(theBox's setFrameSize:{controlSize, buttonHeight * (itemCount + 0.75)}) -- adjust box size
			(its setFrame:{{10, (itemIndex - 1) * buttonHeight}, {controlSize - (padding * 2), buttonHeight}})
			(its setRefusesFirstResponder:true) -- initial highlight as desired
			(theBox's addSubview:it)
		end tell
	end repeat
	return theBox
end makeButtonGroup

# Make an individual checkbox or radio button - the state will be on if the name ends with a return.
# The image position is to the left of the title (default), other positions are left up to the user.
to makeGroupButton at (origin as list) given radio:radio as boolean : true, controlSize:controlSize as integer : 0, buttonName:buttonName as text : "Button", lineBreakMode:lineBreakMode as integer : 5, tag:tag as integer : 0, action:action as text : "buttonGroupAction:", target:target : missing value
	if radio then
		set button to current application's NSButton's radioButtonWithTitle:"" target:target action:action
	else
		set button to current application's NSButton's checkboxWithTitle:"" target:target action:action
	end if
	if buttonName ends with return then -- set/check the button
		button's setState:1 -- NSControlStateValueOn/NSOnState
		set buttonName to text 1 thru -2 of buttonName
	end if
	button's setTitle:buttonName
	button's setFrameOrigin:origin
	button's setLineBreakMode:lineBreakMode
	if controlSize is in {0, 1, 2, 3} then -- 0-3 or NSControlSize enum
		button's setControlSize:controlSize
		button's sizeToFit()
	else
		button's setFrameSize:{controlSize, 24} -- default NSControlSize with custom width
	end if
	if tag is not 0 then button's setTag:tag
	if action is not "" then
		button's setTarget:(item (((target is missing value) as integer) + 1) of {target, me})
		button's setAction:action
	end if
	return button
end makeGroupButton

# Perform an action when a button is pressed (common action required for radio buttons in a matrix).
on buttonGroupAction:sender
	tell AlertController to if its giveUpTime > 0 then set its countdown to its giveUpTime -- reset (if desired)
end buttonGroupAction:

