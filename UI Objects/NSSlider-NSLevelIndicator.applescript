
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property slider : missing value
property levelIndicator : missing value

set my slider to makeSlider at {20, 125} -- given dimensions:{300, 26}
mainWindow's contentView's addSubview:slider

set my levelIndicator to makeLevelIndicator at {20, 50} -- given dimensions:{300, 26}
mainWindow's contentView's addSubview:levelIndicator
*)


# Make and return a basic slider control with value range from 0.0 to 1.0.
to makeBasicSlider at (origin as list) given dimensions:dimensions as list : {150, 26}, controlSize:controlSize : missing value, fillColor:fillColor : missing value, vertical:vertical as boolean : false, initial:initial as real : 0, tag:tag : missing value, target:target : missing value, action:action : "sliderAction:"
	if action is not in {"", missing value} and target is missing value then set target to me
	tell (current application's NSSlider's sliderWithTarget:target action:action)
		its setFrame:{origin, dimensions}
		its sendActionOn:(current application's NSEventMaskLeftMouseUp) -- comment for continuous
		if controlSize is not missing value then its setControlSize:controlSize -- 0-4 or NSControlSize enum
		if vertical then its setFrameRotation:90 -- adjust origin accordingly
		if fillColor is not missing value then its setTrackFillColor:fillColor -- NSColor
		if tag is not missing value then its setTag:tag
		its setFloatValue:initial
		return it
	end tell
end makeBasicSlider


# Make and return a slider control.
# Default is linear 0-10, with tickmarks at each value.
to makeSlider at (origin as list) given dimensions:dimensions as list : {150, 26}, controlSize:controlSize : missing value, fillColor:fillColor : missing value, circular:circular as boolean : false, minimum:minimum : 0, maximum:maximum : 10, initial:initial : 0, tickMarks:tickMarks as integer : 11, onlyTickMarkValues:onlyTickMarkValues as boolean : false, tag:tag : missing value, target:target : missing value, action:action as text : "sliderAction:"
	if action is not in {"", "missing value"} and target is missing value then set target to me
	tell (current application's NSSlider's sliderWithValue:initial minValue:minimum maxValue:maximum target:target action:action)
		its setFrame:{origin, dimensions}
		if second item of dimensions > first item of dimensions then its setVertical:true -- adjust origin accordingly
		its sendActionOn:(current application's NSEventMaskLeftMouseUp) -- comment for continuous
		if controlSize is not missing value then its setControlSize:controlSize -- 0-4 or NSControlSize enum
		if fillColor is not missing value then its setTrackFillColor:fillColor -- NSColor
		if tag > 0 then its setTag:tag
		if circular then
			its setSliderType:(current application's NSSliderTypeCircular)
		else
			if second item of dimensions > first item of dimensions then its setVertical:true
		end if
		if tickMarks is not 0 then
			if tickMarks < 0 then set tickMarks to maximum + 1
			its setNumberOfTickMarks:tickMarks
			if onlyTickMarkValues then set its allowsTickMarkValuesOnly to true
		end if
		return it
	end tell
end makeSlider


# Perform an action when the slider is used.
on sliderAction:sender
	-- whatever
	
	(* The current event can be used if not using continuous or sendActionOn:
	set eventType to (current application's NSApplication's sharedApplication's currentEvent's |type|) as integer
	if eventType is (current application's NSEventTypeLeftMouseDown) then
		-- do whatever when dragging starts
	else if eventType is (current application's NSEventTypeLeftMouseUp) then
		-- do whatever when dragging stops
		display dialog "Current slider value: " & sender's doubleValue as text with title "Slider changed with mouse" buttons {"OK"} default button 1 giving up after 2
	else if eventType is (current application's NSEventTypeLeftMouseDragged) then
		-- do whatever while dragging
	else
		-- other slider change (keypress, touchpad, etc)
		display dialog "Current slider value: " & sender's doubleValue as text with title "Slider changed (event type = " & eventType & ")" buttons {"OK"} default button 1 giving up after 2
	end if
	*)
end sliderAction:


# Make and return a level indicator.
# Similar to a slider, with more display styles but without user adjustment.
# Default is continous 0-10, with tickmarks at each value.
to makeLevelIndicator at (origin as list) given dimensions:dimensions as list : {150, 24}, indicatorStyle:indicatorStyle : 1, controlSize:controlSize as integer : 0, vertical:vertical as boolean : false, minValue:minValue as real : 0, maxValue:maxValue as real : 10, warningValue:warningValue as real : 0, criticalValue:criticalValue as real : 0, fillColor:fillColor : missing value, warningColor:warningColor : missing value, criticalColor:criticalColor : missing value, tickMarks:tickMarks as integer : 11, majorTickMarks:majorTickMarks as integer : 0, tickMarkPosition:tickMarkPosition as integer : 0
	tell current application's NSLevelIndicator's alloc()'s init()
		its setFrame:{origin, dimensions}
		its setLevelIndicatorStyle:indicatorStyle -- 0-3 or NSLevelIndicatorStyle enum
		if controlSize > 0 then its setControlSize:controlSize -- 0-4 or NSControlSize enum
		if vertical then its setFrameRotation:90 -- adjust origin accordingly
		try
			its setMinValue:minValue
			its setMaxValue:maxValue
			its setWarningValue:(item (((warningValue > 0) as integer) + 1) of {maxValue * 0.5, warningValue}) -- default 50%
			its setCriticalValue:(item (((criticalValue > 0) as integer) + 1) of {maxValue * 0.8, criticalValue}) -- default 80%
		on error errmess -- incorrect value setting
			log errmess -- display alert errmess
		end try
		if fillColor is not missing value then its setFillColor:fillColor -- NSColor - default is green
		if warningColor is not missing value then its setWarningFillColor:warningColor -- NSColor - default is yellow
		if criticalColor is not missing value then its setCriticalFillColor:criticalColor -- NSColor - default is red
		if tickMarks is not 0 then try
			its setNumberOfTickMarks:tickMarks
			its setTickMarkPosition:tickMarkPosition -- 0-1 or NSTickMarkPosition enum
			its setNumberOfMajorTickMarks:majorTickMarks
		on error errmess -- incorrect setting
			log errmess -- display alert errmess
		end try
		return it
	end tell
end makeLevelIndicator


#
# NSControlSize:
# NSControlSizeRegular = 0
# NSControlSizeSmall = 1
# NSControlSizeMini = 2
# NSControlSizeLarge = 3
#

#
# NSLevelIndicatorStyle:
# NSLevelIndicatorStyleRelevancy = 0           (gray shading)
# NSLevelIndicatorStyleContinuousCapacity = 1  (fractional indication)
# NSLevelIndicatorStyleDiscreteCapacity = 2    (rounded to segments at tick marks)
# NSLevelIndicatorStyleRating = 3              (stars)
#

#
# NSTickMarkPosition:
# NSTickMarkPositionBelow = 0     (horizontal)
# NSTickMarkPositionAbove = 1     (horizontal)
#
# NSTickMarkPositionTrailing = 0  (vertical)
# NSTickMarkPositionLeading = 1   (vertical)
#

#
# NSEventType:
# NSEventTypeLeftMouseDown = 1
# NSEventTypeLeftMouseUp = 2
# NSEventTypeRightMouseDown = 3
# NSEventTypeRightMouseUp = 4
# NSEventTypeLeftMouseDragged = 6
# NSEventTypeRightMouseDragged = 7
# NSEventTypeKeyDown = 10
# NSEventTypeKeyUp = 11
#

