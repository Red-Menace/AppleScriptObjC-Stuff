
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property datePicker : missing value

set my datePicker to makeDatePicker at {20, 20} -- given arguments are optional
mainWindow's contentView's addSubview:datePicker
*)


# Make and return a NSDatePicker.
# Note that the clock and calendar style will need larger dimensions.
# Make and return a NSDatePicker.
# Note that the clock and calendar style will need larger dimensions.
to makeDatePicker at (origin as list) given controlSize:controlSize as integer : 0, pickerStyle:pickerStyle as integer : 0, pickerMode:pickerMode as integer : 0, elements:elements as integer : 236, bezeled:bezeled as boolean : false, bordered:bordered as boolean : false, drawsBackground:drawsBackground as boolean : false, textColor:textColor : missing value, dateValue:dateValue : missing value, minDate:minDate : missing value, maxDate:maxDate : missing value, target:target : missing value, action:action : "datePickerAction:"
	tell (current application's NSDatePicker's alloc()'s initWithFrame:{origin, {0, 0}})
		its setControlSize:controlSize -- 0-3 or NSControlSize enum
		its setDatePickerStyle:pickerStyle -- 0-2 or NSDatePickerStyle enum
		its setDatePickerMode:pickerMode -- 0-1 or NSDatePickerMode enum
		its setDatePickerElements:elements -- NSDatePickerElementFlags mask
		its setBezeled:bezeled
		its setBordered:bordered
		its setDrawsBackground:drawsBackground
		if textColor is not missing value then its setTextColor:textColor
		if dateValue is missing value then set dateValue to (current date) -- 'current date' can't be used as an optional default
		its setDateValue:dateValue
		its sizeToFit()
		if minDate is not missing value then its setMinDate:minDate
		if maxDate is not missing value then its setMaxDate:maxDate
		if action is not missing value then
			its setAction:(action as text)
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
		end if
		return it
	end tell
end makeDatePicker

on datePickerAction:sender
	set theDate to sender's dateValue as date
	# display dialog "The date picker date is " & theDate & "." buttons {"OK"} default button 1 giving up after 2
	-- whatever
end datePickerAction:


# Subclass NSDatePicker to do something like call an action handler when the return/enter key is pressed.
# The subclass must be in a separate file in a script bundle or Cocoa-AppleScript applet and loaded with:
#	set theBundle to current application's NSBundle's bundleWithPath:"/path/to/folder/containing/script(s)"
#	theBundle's loadAppleScriptObjectiveCScripts()
script DatePickerKeyDown
	property parent : class "NSDatePicker"
	
	on keyDown:theEvent
		if theEvent's keyCode is in {current application's NSCarriageReturnCharacter, current application's NSEnterCharacter} then
			-- whatever
		else
			continue keyDown:theEvent
		end if
	end keyDown:
	
end script


# 
# NSDatePickerElementFlags:
# NSDatePickerElementFlagHourMinute = 0x000c			(12) -- for combinations, add mask values together
# NSDatePickerElementFlagHourMinuteSecond = 0x000e	(14)
# NSDatePickerElementFlagTimeZone = 0x0010				(16)
# NSDatePickerElementFlagYearMonth = 0x00c0				(192)
# NSDatePickerElementFlagYearMonthDay = 0x00e0			(224)
# NSDatePickerElementFlagEra = 0x0100					(256)
# 

#
# NSDatePickerStyle:								Deprecated macOS 11.0:
# NSDatePickerStyleTextFieldAndStepper = 0		NSTextFieldAndStepperDatePickerStyle
# NSDatePickerStyleClockAndCalendar = 1			NSClockAndCalendarDatePickerStyle
# NSDatePickerStyleTextField = 2					NSTextFieldDatePickerStyle
#

# 
# NSDatePickerMode:					Deprecated macOS 11.0:
# NSDatePickerModeSingle = 0		NSSingleDateMode
# NSDatePickerModeRange = 1		NSRangeDateMode
#

# NSEventMask (mouse events):
# NSEventMaskLeftMouseDown = 2 -- for combinations, add mask values together
# NSEventMaskLeftMouseUp = 4
# NSEventMaskRightMouseDown = 8
# NSEventMaskRightMouseUp = 16
# 

