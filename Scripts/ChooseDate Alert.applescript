
#
#	A `choose date` implementation using NSDatePickers with an optional label NSTextField that cover the NSAlert views.
#	Multiple pickers are used to add a textual picker for the graphical clock - all pickers are synchronized.
#	Updated for Tahoe.
#


use AppleScript version "2.8" -- Monterey (12.0) and later
use framework "Foundation"
use scripting additions

property aligning : false -- change textField border and background for testing the alignments
property datePickers : {calendar:(missing value), graphical:(missing value), textual:(missing value)} -- outlets

# Results
property results : missing value -- AppleScript date or ISO date/time string - missing value if cancelled
property failure : missing value -- error record {errorMessage:string, errorNumber:integer} - missing value if none


on run -- examples
	showDatePicker at {100, 400} -- basic
	log result
	showDatePicker with ISODate given okButtonName:"ISO Date", labelString:"", initialDate:((current date) + 60 * days) -- more options
	log result
	tell failure to if it is not missing value then error ((its errorMessage) as text) number (its errorNumber)
end run

# Set up to perform the alert stuff - UI items need to be run on the main thread.
# This is the main handler, using optional labeled parameters to set defaults.
to showDatePicker at (origin as list) : {} given okButtonName:(okButtonName as text) : "Choose", cancelButtonName:(cancelButtonName as text) : "Cancel", labelString:(labelString as text) : "Choose a date and time…", initialDate:initialDate : (missing value), ISODate:(ISODate as boolean) : false
	set {my results, my failure} to {missing value, missing value} -- reset
	set arguments to {origin, okButtonName, cancelButtonName, labelString, initialDate, ISODate}
	if current application's NSThread's isMainThread() as boolean then
		my performAlertOnMainThread:arguments
	else -- note that performSelector does not return anything
		my performSelectorOnMainThread:"performAlertOnMainThread:" withObject:arguments waitUntilDone:true
	end if
	tell failure to if it is not missing value then error ((its errorMessage) as text) number (its errorNumber) -- pass it up the chain
	return results
end showDatePicker

# Perform the datePicker alert - results are returned in the `results` and `failure` properties.
to performAlertOnMainThread:arguments -- arguments may be a NSArray of Cocoa objects
	set {origin, okButtonName, cancelButtonName, labelString, initialDate, ISODate} to (arguments as list) -- coerce
	set {my results, my failure} to {missing value, missing value} -- reset
	tell current application's NSAlert's alloc()'s init() to try
		its (|window|'s setAutorecalculatesKeyViewLoop:true)
		its setMessageText:"" -- not used, but content will increase the alert size
		its addButtonWithTitle:(item (((okButtonName is "") as integer) + 1) of {okButtonName, "OK"})
		if cancelButtonName is not "" then (its addButtonWithTitle:cancelButtonName)'s setKeyEquivalent:(character id 27)
		its setAccessoryView:(current application's NSView's alloc()'s initWithFrame:{{0, 0}, {276, 98 - (34 * (1 - ((labelString is not "") as integer)))}}) -- adjust for contents to cover icon
		its layout() -- layout alert window for the current settings (buttons, accessory view, etc)
		my addAccessorySubviews((its |window|), labelString, initialDate)
		if origin is not {} then
			its (|window|'s orderBack:me) -- show it...
			its (|window|'s setFrameOrigin:origin) -- ...to move it
		end if
		my (getResults from it for {calendar of datePickers, ISODate})
	on error errmess number errnum
		set my failure to {errorMessage:errmess, errorNumber:errnum}
	end try
end performAlertOnMainThread:

# Return the result from the alert.
to getResults from alert for {object, option}
	if (alert's runModal() as integer) is 1000 then -- modal response starts at 1000 in the button order 
		set theDate to (object's dateValue()) as date -- default AppleScript date - option flag is for ISO date/time string
		set my results to item ((option as integer) + 1) of {theDate, theDate as «class isot» as string}
	else
		set my results to missing value
		error number -128 -- cancel
	end if
end getResults

to addAccessorySubviews(alertWindow, labelString, initialDate) -- datePickers with a label textField
	set accessoryFrame to (item 4 of alertWindow's contentView's subviews)'s frame as list
	set {{x, y}, {width, height}} to accessoryFrame -- after layout, item 4 is the accessory view if used
	set labelOffset to item (((labelString is "") as integer) + 1) of {102, 68} -- cover the icon
	alertWindow's contentView's addSubview:(my (makeLabelField into {{x, y + labelOffset}, {width, 80}} for labelString given alignment:(current application's NSTextAlignmentCenter), textFont:(current application's NSFont's fontWithName:"Helvetica Neue Bold" |size|:13)))
	set calendar of datePickers to (makeDatePicker into {{x, y}, {width / 2, y + 148}} given pickerType:"calendar", initialDate:initialDate) -- calendar to the left
	alertWindow's contentView's addSubview:(calendar of datePickers)
	alertWindow's setInitialFirstResponder:(calendar of datePickers) -- pre-select this datePicker
	set graphical of datePickers to (makeDatePicker into {{x + width / 2 + 16, y + 26}, {width, height * 2}} given pickerType:"graphical", initialDate:initialDate) -- graphical clock face to upper right
	alertWindow's contentView's addSubview:(graphical of datePickers)
	set textual of datePickers to (makeDatePicker into {{x + width / 2 + 24, y}, {108, height / 2}} given pickerType:"textual", initialDate:initialDate) -- textual with stepper to lower right
	alertWindow's contentView's addSubview:(textual of datePickers)
end addAccessorySubviews

# Make and return a label textField - `textString` can be attributed.
to makeLabelField into (frame as list) for textString given textFont:textFont : (missing value), textColor:textColor : (missing value), alignment:alignment : (missing value), linebreakMode:linebreakMode : (missing value)
	tell (current application's NSTextField's labelWithString:textString)
		its setFrame:frame
		its setDrawsBackground:(not aligning) -- hide covered views
		its setBordered:aligning
		its setBackgroundColor:(my makeBackgroundColor()) -- note that colors like quinarySystemFillColor are not opaque
		its setAllowsEditingTextAttributes:true -- the following are ignored if using an attributed string:
		if textFont is not missing value then its setFont:textFont -- NSFont
		if textColor is not missing value then its setTextColor:textColor -- NSColor	
		if alignment is not missing value then its setAlignment:alignment -- 0-4 or NSTextAlignment enum	
		if linebreakMode is not missing value then its setLineBreakMode:linebreakMode -- 0-5 or NSLineBreakMode enum
		return it
	end tell
end makeLabelField

# Make and return an opaque background color similar to the window background.
# Note that label colors and colors like quinarySystemFillColor are not opaque, and Tahoe colors have changed.
to makeBackgroundColor()
	set dark to (((current application's NSApp's effectiveAppearance's |name|) as text) contains "dark")
	set grays to item ((((get system attribute "sys1") ≥ 26) as integer) + 1) of {{0.92, 0.17}, {0.96, 0.08}} -- Tahoe?
	set grayRGB to item ((dark as integer) + 1) of grays -- background color for the current appearance
	return current application's NSColor's colorWithSRGBRed:grayRGB green:grayRGB blue:grayRGB alpha:1.0
end makeBackgroundColor

# Make and return a NSDatePicker view - if the optional `initialDate` is used it must be a date object.
to makeDatePicker into (frame as list) given pickerType:pickerType : "combo", initialDate:initialDate : (missing value)
	if pickerType is not in {"combo", "calendar", "graphical", "textual"} then return missing value
	tell (current application's NSDatePicker's alloc()'s initWithFrame:frame)
		its setDatePickerStyle:(current application's NSClockAndCalendarDatePickerStyle) -- base
		its setDatePickerElements:(current application's NSHourMinuteSecondDatePickerElementFlag as integer) -- base
		if pickerType is "combo" then -- add calendar to base graphical clock
			its setDatePickerElements:((its datePickerElements) + (current application's NSYearMonthDayDatePickerElementFlag as integer))
		else if pickerType is "calendar" then -- calendar only
			its setDatePickerElements:(current application's NSYearMonthDayDatePickerElementFlag as integer)
		else if pickerType is "textual" then -- textual time picker with stepper
			its setDatePickerStyle:(current application's NSDatePickerStyleTextFieldAndStepper)
		end if
		its setDateValue:(item (((initialDate is not missing value) as integer) + 1) of {(current date), initialDate})
		its setTarget:me
		its setAction:"datePickerAction:"
		return it
	end tell
end makeDatePicker

# Synchronize graphical and textual time pickers.
on datePickerAction:sender
	set theDate to sender's dateValue
	repeat with anItem in {calendar, graphical, textual} of datePickers -- just update them all
		if anItem is not missing value then (anItem's setDateValue:theDate)
	end repeat
end datePickerAction:

