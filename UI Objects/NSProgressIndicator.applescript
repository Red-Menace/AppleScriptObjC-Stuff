
# Script object and handler to create an NSProgressIndicator.
# Examples follow the script object.


use AppleScript version "2.5" -- Sierra (10.12) or later
use framework "Foundation"
use scripting additions

# A script object/class for a combination progress bar panel.
# The panel consists of a progress bar (with optional cancel button) with text fields above and below.
script ProgressBarController
	
	# UI item frame constants (for panel layout)
	property PANEL_FRAME : {{200, 600}, {526, 89}}
	property TOP_TEXT_FRAME : {{22, 57}, {482, 17}}
	property FULL_INDICATOR_FRAME : {{24, 35}, {478, 14}} -- without cancel button
	property REDUCED_INDICATOR_FRAME : {{24, 35}, {450, 14}} -- with cancel button
	property BUTTON_FRAME : {{483, 33}, {18, 18}}
	property BOTTOM_TEXT_FRAME : {{22, 15}, {482, 12}}
	
	# the UI items
	property panel : missing value
	property indicator : missing value
	property topTextField : missing value
	property bottomTextField : missing value
	property cancelButton : missing value
	
	# other controller properties
	property setupCompleted : false -- progress panel has been set up
	property includeCancel : false -- include a cancel button
	
	##################################################
	#	Progress bar set up handlers
	##################################################
	
	# initialize with a cancel button.
	on initWithCancel()
		if setupCompleted then return me -- already created
		set my includeCancel to true
		init()
	end initWithCancel
	
	# Create the panel, text fields, and progress bar.
	on init()
		if setupCompleted then return me -- already created
		try
			createPanel()
			createTopTextField()
			createIndicator()
			createBottomTextField()
			set my setupCompleted to true
			return me -- success
		on error errmess
			set logText to "Error in ProgressBarController's 'init' handler: "
			log logText & errmess
			# display alert logText message errmess
			return missing value -- failure
		end try
	end init
	
	# Create a panel for the indicator items - the title can be set via the instance property.
	to createPanel()
		tell (current application's NSPanel's alloc's initWithContentRect:PANEL_FRAME styleMask:(current application's NSWindowStyleMaskTitled) backing:(current application's NSBackingStoreBuffered) defer:true)
			set my panel to it
			its setPreventsApplicationTerminationWhenModal:false
			its setAllowsConcurrentViewDrawing:true
			its (contentView's setCanDrawConcurrently:true)
			its setReleasedWhenClosed:false -- so window can be shown again
			its setLevel:(current application's NSFloatingWindowLevel)
			its setHasShadow:true
			its |center|()
		end tell
	end createPanel
	
	# Create a text field above the progress indicator.
	to createTopTextField()
		tell (current application's NSTextField's alloc's initWithFrame:TOP_TEXT_FRAME)
			set my topTextField to it
			its setBordered:false
			its setDrawsBackground:false
			its setFont:(current application's NSFont's systemFontOfSize:13) -- also boldSystemFont
			its setEditable:false
			its setSelectable:false
			its (cell's setLineBreakMode:(current application's NSLineBreakByClipping))
			panel's contentView's addSubview:it
		end tell
	end createTopTextField
	
	# Create a progress bar indicator.
	to createIndicator()
		if includeCancel then
			set theFrame to REDUCED_INDICATOR_FRAME
			createCancelButton()
		else -- use the button space
			set theFrame to FULL_INDICATOR_FRAME
		end if
		tell (current application's NSProgressIndicator's alloc's initWithFrame:theFrame)
			set my indicator to it
			its setUsesThreadedAnimation:true
			its setDisplayedWhenStopped:true
			its setStyle:(current application's NSProgressIndicatorBarStyle)
			its setIndeterminate:false
			panel's contentView's addSubview:it
		end tell
	end createIndicator
	
	# Create a cancel button.
	to createCancelButton()
		tell (current application's NSButton's alloc's initWithFrame:BUTTON_FRAME)
			set my cancelButton to it
			its setButtonType:(current application's NSMomentaryPushInButton)
			its setBezelStyle:(current application's NSCircularBezelStyle)
			its setBordered:false
			tell its cell()
				its setBackgroundStyle:(current application's NSBackgroundStyleLight)
				its setHighlightsBy:(current application's NSChangeGrayCellMask)
				its setImageScaling:(current application's NSImageScaleProportionallyUpOrDown)
			end tell
			its setImage:(current application's NSImage's imageNamed:(current application's NSImageNameStopProgressFreestandingTemplate))
			# button action is set up in the main script
			its setKeyEquivalent:(character id 27) -- escape key
			its setRefusesFirstResponder:true -- no focus ring
			panel's contentView's addSubview:it
		end tell
	end createCancelButton
	
	# Create a text field below the progress indicator.
	to createBottomTextField()
		tell (current application's NSTextField's alloc's initWithFrame:BOTTOM_TEXT_FRAME)
			set my bottomTextField to it
			its setBordered:false
			its setDrawsBackground:false
			its setFont:(current application's NSFont's systemFontOfSize:10)
			its setEditable:false
			its setSelectable:false
			its (cell's setLineBreakMode:(current application's NSLineBreakByTruncatingMiddle))
			panel's contentView's addSubview:it
		end tell
	end createBottomTextField
	
	##################################################
	#	Progress Controller utility handlers
	##################################################
	
	# Manually handle events to avoid blocking the UI.
	to processEvents()
		repeat -- forever (or at least until events run out)
			tell current application's NSApp
				set theEvent to its nextEventMatchingMask:(current application's NSEventMaskAny) untilDate:(missing value) inMode:(current application's NSDefaultRunLoopMode) dequeue:true
				if theEvent is missing value then exit repeat -- none left
				its sendEvent:theEvent -- pass it on
			end tell
		end repeat
	end processEvents
	
	to updateProgress by amount
		processEvents()
		if amount is not 0 then try -- skip coercion errors
			indicator's incrementBy:(amount as integer)
		end try
		panel's display()
	end updateProgress
	
	to setTextFields given top:top : (missing value), bottom:bottom : (missing value)
		if top is not missing value then topTextField's setStringValue:(top as text)
		if bottom is not missing value then bottomTextField's setStringValue:(bottom as text)
		panel's display()
	end setTextFields
	
	to setProgressValues given minimum:minimum : (missing value), maximum:maximum : (missing value)
		if minimum is not missing value then try -- skip coercion errors
			indicator's setMinValue:(minimum as integer)
		end try
		if maximum is not missing value then try -- skip coercion errors
			indicator's setMaxValue:(maximum as integer)
		end try
	end setProgressValues
	
	to showWindow()
		tell panel to makeKeyAndOrderFront:me
	end showWindow
	
	to closeWindow()
		tell panel to orderOut:me
	end closeWindow
	
end script


(*
	----- Example -----
		
	Typical operation for script object/class:
		¥ set up cancel button action as needed
		¥ create progress controller
		¥ adjust settings
		¥ show the progress window
		¥ place progress updates in the item processing loop
			periodically check the 'stopProgress' property for cancel
		¥ close the progress window
*)

property controller : missing value -- this will be the progress controller instance
property stopProgress : missing value -- a flag to stop (cancel button pressed)
property failed : missing value -- this will be a record of the message and number of any error

on run -- example can be run as app and from Script Editor
	open (words of "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam quis ullamcorper orci.") -- or whatever
end run

on open theItems -- items dragged onto droplet
	try
		if current application's NSThread's isMainThread() as boolean then
			doStuff_(theItems)
		else
			my performSelectorOnMainThread:"doStuff:" withObject:theItems waitUntilDone:true
		end if
		if failed is not missing value then error failed's errmsg number failed's errnum
		log "done"
		if name of current application is not in {"Script Editor", "Script Debugger"} then tell me to quit -- don't quit the script editors
	on error errmsg number errnum
		display alert "Error " & errnum message errmsg
	end try
end open

to doStuff:stuff -- UI stuff needs to be done on the main thread
	try
		set stopProgress to false
		set my controller to ProgressBarController's initWithCancel() -- init progress
		controller's cancelButton's setTarget:me -- set up the button action
		controller's cancelButton's setAction:"cancelProgress:"
		controller's (setProgressValues given maximum:(count stuff)) -- set up details
		controller's indicator's setDoubleValue:0 -- (re)set
		controller's (setTextFields given top:"", bottom:"")
		controller's panel's setTitle:"Progress Example"
		controller's showWindow()
		process(stuff)
	on error errmsg number errnum
		set my failed to {errmsg:errmsg, errnum:errnum}
	end try
end doStuff:

to process(itemList) -- process with progress
	repeat with anItem in itemList
		delay 0.5 -- slow down a bit
		set theText to anItem as text
		if class of anItem is alias then tell application "Finder" to set theText to name of anItem -- shorten file items
		controller's (updateProgress by 1)
		controller's (setTextFields given top:"Processing...", bottom:"Currently processing " & quoted form of theText)
		if stopProgress then exit repeat -- check for the cancel button
		log anItem as text -- do whatever with the item
	end repeat
	delay 1
	controller's closeWindow()
end process

on cancelProgress:sender -- action when the cancel button is pressed
	set my stopProgress to true
	# whatever
	controller's closeWindow()
	set theNumber to controller's indicator's doubleValue -- current progress
	display alert "Progress Canceled" message "The progress was stopped after " & theNumber & " items." giving up after 3
end cancelProgress:


(* example:
property mainWindow : missing value -- globals can also be used
property progressIndicator : missing value

set my progressIndicator to makeProgressIndicator at {100, 100} -- given arguments are optional
mainWindow's contentView's addSubview:progressIndicator
*)

# Minimal handler to make and return a progress indicator.
# Default is a determinate bar of 0-100 that displays when stopped.
to makeProgressIndicator at origin given dimensions:dimensions : {100, 20}, minValue:minValue : (missing value), maxValue:maxValue : (missing value), indeterminate:indeterminate : false, controlSize:controlSize : (missing value), spinning:spinning : false, displayWhenStopped:displayWhenStopped : true
	tell (current application's NSProgressIndicator's alloc's initWithFrame:{origin, dimensions})
		its setUsesThreadedAnimation:true
		if minValue is not in {0, missing value} then its setMinValue:minValue
		if maxValue is not in {100, missing value} then its setMaxValue:maxValue
		if indeterminate is in {true, "yes", 1} then its setIndeterminate:true
		if controlSize is not in {0, missing value} then its setControlSize:controlSize -- 0-3 or enum
		if spinning is in {true, "yes", 1} then its setStyle:1 -- 0-1 or enum
		if displayWhenStopped is not in {true, "yes", 1} then its setDisplayedWhenStopped:false
		return it
	end tell
end makeProgressIndicator

