
#
# A `choose date` implementation using a NSDatePicker and label NSTextField that cover the NSAlert views.
#


use framework "Foundation"
use scripting additions

property response : missing value -- AppleScript date or ISO date/time string - missing value if cancelled
property failure : missing value -- error record {errmess:string, errnum:integer} - missing value if none


on run -- examples
	try
		showDatePicker at {} -- basic
		log result
		showDatePicker at {100, 400} with ISODate given okButtonName:"ISO Date", cancelButtonName:"", labelString:"", initialDate:((current date) + 60 * days) -- more options
		log result
	on error errmess number errnum
		if errnum is -128 then error number -128 -- cancel
		tell failure to if it is not missing value then error ((its errmess) as text) number (its errnum)
	end try
end run

# Set up and perform the alert stuff - UI items need to be run on the main thread.
# This is the main handler - options are set up for the alert using optional parameters with defaults.
to showDatePicker at (origin as list) given okButtonName:(okButtonName as text) : "Choose", cancelButtonName:(cancelButtonName as text) : "Cancel", labelString:(labelString as text) : "Choose a date and time…", initialDate:initialDate : (missing value), ISODate:(ISODate as boolean) : false
	set arguments to {origin, okButtonName, cancelButtonName, labelString, initialDate, ISODate}
	if current application's NSThread's isMainThread() as boolean then
		my performAlertOnMainThread:arguments
	else -- note that performSelector does not return anything
		my performSelectorOnMainThread:"performAlertOnMainThread:" withObject:arguments waitUntilDone:true
	end if
	tell failure to if it is not missing value then error ((its errmess) as text) number (its errnum) -- pass it up the chain
	return response
end showDatePicker

# Perform the datePicker alert - sets the `response` property to an AppleScript date or ISO date/time string.
to performAlertOnMainThread:arguments -- arguments are a NSArray of Cocoa objects
	set {origin, okButtonName, cancelButtonName, labelString, initialDate, ISODate} to (arguments as list) -- coerce
	set {my response, my failure} to {missing value, missing value} -- reset
	tell current application's NSAlert's alloc()'s init() to try
		its (|window|'s setAutorecalculatesKeyViewLoop:true)
		repeat with aView in {item 4, item 5, item 6} of its |window|'s contentView's subviews
			(aView's setHidden:true) -- hide icon imageView, message and informative textFields
		end repeat
		its setMessageText:"" -- no default text
		its addButtonWithTitle:(item (((okButtonName is "") as integer) + 1) of {okButtonName, "OK"})
		if cancelButtonName is not "" then (its addButtonWithTitle:cancelButtonName)'s setKeyEquivalent:(character id 27)
		set showLabel to (labelString is not "") as integer
		its setAccessoryView:(current application's NSView's alloc()'s initWithFrame:{{0, 0}, {276, 98 - (34 * (1 - showLabel))}}) -- adjust base alert window size to fit added view(s)
		its layout() -- layout the alert window using the current settings (buttons, accessory view, etc)
		set {originX, originY} to first item of ((item -2 of (its |window|'s contentView's subviews))'s frame as list) -- accessory view
		set datePicker to (my (makeDatePicker into {{originX, originY}, {276, 148}} given initialDate:initialDate))
		its (|window|'s contentView's addSubview:datePicker)
		if (showLabel as boolean) then its (|window|'s contentView's addSubview:(my (makeLabelField into {{originX, originY + 160}, {276, 22}} for labelString)))
		its (|window|'s setInitialFirstResponder:datePicker) -- highlight
		if origin is not {} then -- move to location
			its (|window|'s orderBack:me)
			its (|window|'s setFrameOrigin:origin) -- bottom left corner
		end if
		my (getResults from it for {datePicker, ISODate})
	on error errmess number errnum
		set my failure to {errmess:("performAlertOnMainThread: " & errmess), errnum:errnum}
	end try
end performAlertOnMainThread:

# Return the result from the alert.
to getResults from alert for {object, option}
	if (alert's runModal() as integer) is 1000 then -- modal response starts at 1000 in the button order 
		set theDate to (object's dateValue()) as date -- default AppleScript date - option flag is for ISO date/time string
		set my response to item ((option as integer) + 1) of {theDate, theDate as «class isot» as string}
	else
		set my response to missing value
		error number -128 -- cancel
	end if
end getResults

# Make and return a date picker view - if the optional `initialDate` is used it must be a date object.
to makeDatePicker into (frame as list) given initialDate:initialDate : (missing value)
	tell (current application's NSDatePicker's alloc()'s initWithFrame:frame)
		its setDatePickerStyle:(current application's NSClockAndCalendarDatePickerStyle)
		its setDatePickerElements:((current application's NSYearMonthDayDatePickerElementFlag as integer) ¬
			+ (current application's NSHourMinuteSecondDatePickerElementFlag as integer))
		its setDateValue:(item (((initialDate is not missing value) as integer) + 1) of {current application's NSDate's |date|(), initialDate})
		return it
	end tell
end makeDatePicker

# Make and return a label text field.
to makeLabelField into (frame as list) for (theString as text)
	tell (current application's NSTextField's labelWithString:theString)
		its setFrame:frame
		its setAlignment:(current application's NSTextAlignmentCenter)
		its setLineBreakMode:(current application's NSLineBreakByTruncatingMiddle)
		its setFont:(current application's NSFont's fontWithName:"Helvetica Neue Bold" |size|:13)
		return it
	end tell
end makeLabelField

