
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property slider : missing value
property levelIndicator : missing value

set my slider to makeSlider at {10, 125} -- given dimensions:{350, 26}
mainWindow's contentView's addSubview:slider

set my levelIndicator to makeLevelIndicator at {10, 50} -- given dimensions:{350, 26}
mainWindow's contentView's addSubview:levelIndicator
*)


# Make and return a slider control.
# Default is linear 0-10, with tickmarks at each value.
to makeSlider at origin given dimensions:dimensions : {150, 24}, circular:circular : false, minimum:minimum : 0, maximum:maximum : 10, initial:initial : 0, tickMarks:tickMarks : 11, onlyTickMarkValues:onlyTickMarkValues : false, tag:tag : missing value, action:action : "sliderAction:", target:target : missing value
	if action is not missing value and target is missing value then set target to me
	tell (current application's NSSlider's sliderWithValue:initial minValue:minimum maxValue:maximum target:target action:action)
		its setFrame:{origin, dimensions}
		if circular is not in {false, missing value} then
			its setSliderType:(current application's NSSliderTypeCircular)
		else
			if second item of dimensions > first item of dimensions then its setVertical:true
		end if
		if tickMarks is not in {0, false, missing value} then
			if tickMarks < 0 then set tickMarks to maximum + 1
			its setNumberOfTickMarks:tickMarks
			if onlyTickMarkValues is true then set its allowsTickMarkValuesOnly to true
		end if
		if tag is not missing value then its setTag:tag
		return it
	end tell
end makeSlider

# Perform an action when the slider is used.
on sliderAction:sender
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
	-- whatever
end sliderAction:


# Make and return a level indicator.
# Similar to a slider, with more display styles but without user adjustment.
# Default is continous 0-10, with tickmarks at each value.
to makeLevelIndicator at origin given dimensions:dimensions : {150, 24}, indicatorStyle:indicatorStyle : 1, minValue:minValue : 0, maxValue:maxValue : 10, warningValue:warningValue : missing value, criticalValue:criticalValue : missing value, fillColor:fillColor : missing value, warningColor:warningColor : missing value, criticalColor:criticalColor : missing value, tickMarks:tickMarks : 11, majorTickMarks:majorTickMarks : 0, tickMarkPosition:tickMarkPosition : 0
	tell current application's NSLevelIndicator's alloc's init()
		its setFrame:{origin, dimensions}
		its setLevelIndicatorStyle:indicatorStyle -- 0-3 or enum
		try
			its setMinValue:(minValue as integer)
			its setMaxValue:(maxValue as integer)
			if warningValue is missing value then set warningValue to maxValue * 0.5 -- default 50%
			its setWarningValue:(warningValue as integer)
			if criticalValue is missing value then set criticalValue to maxValue * 0.8 -- default 80%
			its setCriticalValue:(criticalValue as integer)
		on error errmess -- incorrect value setting
			log errmess -- display alert errmess
		end try
		if fillColor is not missing value then its setFillColor:fillColor -- default is green
		if warningColor is not missing value then its setWarningFillColor:warningColor -- default is yellow
		if criticalColor is not missing value then its setCriticalFillColor:criticalColor -- default is red
		if tickMarks is not in {0, missing value} then try
			its setNumberOfTickMarks:(tickMarks as integer)
			its setTickMarkPosition:tickMarkPosition -- 0-3 or enum
			its setNumberOfMajorTickMarks:(majorTickMarks as integer)
		on error errmess -- incorrect setting
			log errmess -- display alert errmess
		end try
		return it
	end tell
end makeLevelIndicator


#
# Level Indicator Styles:
# NSLevelIndicatorStyleRelevancy = 0				(gray shading)
# NSLevelIndicatorStyleContinuousCapacity = 1	(fractional indication)
# NSLevelIndicatorStyleDiscreteCapacity = 2		(rounded to segments at tick marks)
# NSLevelIndicatorStyleRating = 3					(stars)
#

#
# Tick Mark Positions:
# NSTickMarkPositionBelow = 0		(horizontal)
# NSTickMarkPositionAbove = 1		(horizontal)
#
# NSTickMarkPositionLeading = 1	(vertical)
# NSTickMarkPositionTrailing = 0	(vertical)
#

#
# Event Types:
# NSEventTypeLeftMouseDown = 1
# NSEventTypeLeftMouseUp = 2
# NSEventTypeLeftMouseDragged = 6
# NSEventTypeRightMouseDown = 3
# NSEventTypeRightMouseUp = 4
# NSEventTypeRightMouseDragged = 7
# NSEventTypeKeyDown = 10
# NSEventTypeKeyUp = 11
#

