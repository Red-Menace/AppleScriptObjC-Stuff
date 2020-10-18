
use AppleScript version "2.4" -- Yosemite 10.10 and later
use framework "Appkit"
use scripting additions

property SYS_RESOURCES : "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/"
property cancelButton : "Cancel" -- a name for the cancel button
property okButton : "OK" -- a name for the OK button

property alert : missing value -- this will be the alert
property timerField : missing value -- this will be a countdown textField
property countdown : missing value -- this will be the remaining time before alert is dismissed
property response : missing value -- this will be the button and accessory results from the alert

on run -- examples
    set loremText to "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque vestibulum venenatis velit, non commodo diam pretium sed. Etiam viverra erat a lacus molestie id euismod magna lacinia. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vestibulum ac augue magna, eu pharetra leo. Donec tortor tortor, tristique in ornare nec, feugiat vel justo. Nunc iaculis interdum pellentesque. Quisque vel rutrum nibh. Phasellus malesuada ipsum quis diam ullamcorper rutrum. Nullam tincidunt porta ante, in aliquet odio molestie eget. Donec mollis, nibh euismod pulvinar fermentum, magna nunc consectetur risus, id dictum odio leo non velit. Vestibulum vitae nunc pulvinar augue commodo sollicitudin."
    
    showAlert given arguments:{info:"This is a simple NSAlert example."} -- simple/defaults
    log result
    showAlert given arguments:{addedWidth:50, title:"This is a test", giveUpTime:15, message:"", input:{"Testing" & return, "Whatever" & return, "A really, really, long label to see how really, really, long labels appear"}, info:"This is a more complex NSAlert example using all arguments.", accessoryType:"checkbox", buttons:{"Cancel", "Wait...", "What?", "OK"}, icon:"caution"} -- everything
    log result
end run

# The main handler to configure and show an alert:
#
# Alert arguments (record) - items can be declared in any order, defaults will be used if not specified:
#   title: title of the alert window
#   message: the message text (bold font)
#   info: informational text
#   icon: icon type, system icon, or image path (see setIcon handler for available options)
#   buttons: a (left to right) list of button titles (can be more than three, but try not to overdo it)
#   giveUpTime: the number of seconds for the alert to wait before giving up
#   --
#   accessoryType: the type of accessoryView (see setAccessory handler for available options)
#   input: string or list of strings used in the accessoryView (again, try not to overdo it)
#   addedWidth: added width for the accessoryView (default is enough for buttons, or alert minimum)
#
# Alert result (record):
#   button: the name of the button pressed (or 'gave up' if a specified giveUpTime has expired)
#   answer: the contents of the accessoryView (or "missing value" if none):
#       TextField and ComboBox: the textField contents
#       CheckBox and RadioButtons: a record with button titles as keys and states (0 or 1) as values
#
to showAlert given arguments:arguments
    try
        if current application's NSThread's isMainThread() as boolean then
            my performAlert:arguments
        else
            my performSelectorOnMainThread:"performAlert:" withObject:arguments waitUntilDone:true
        end if
        if button of response is cancelButton then error number -128
        return response
    on error errmess number errnum -- there are a few ways to deal with a cancel, pick one
        tell me to activate
		  display alert "Error " & errnum & " from showAlert handler:" message errmess
        log "Error " & errnum & " from showAlert handler:" & return & errmess
        return response
    end try
end showAlert


##################################################
#                       NSAlert Stuff    
##################################################

# Perform the alert. 
to performAlert:arguments
    set arguments to arguments as record -- merged with default options:
    set arguments to arguments & {title:""} & {message:"Alert"} & {info:""} & {icon:""} & {buttons:{}} & {giveUpTime:0} & {accessoryType:""} & {input:""} & {addedWidth:0}
    set alert to current application's NSAlert's alloc's init()
    if checkValue(title of arguments) then alert's |window|'s setTitle:((title of arguments) as text)
    alert's setMessageText:((message of arguments) as text)
    if (alert's messageText) as text is "" then -- can't be nil, so just make it really small
        set messageFont to current application's NSFont's systemFontOfSize:0.25
        set |font| of (fifth item of alert's |window|'s contentView's subviews) to messageFont
    end if
    if checkValue(info of arguments) then alert's setInformativeText:((info of arguments) as text)
    if checkValue(icon of arguments) then my setIcon:((icon of arguments) as text) -- default if blank
    set buttonList to my setButtons:(buttons of arguments)
    set timer to my setupTimer:(giveUpTime of arguments)
    set accessory to my setAccessory:(accessoryType of arguments) using:(input of arguments) addedWidth:(addedWidth of arguments)
    set button to my buttonPressed:timer -- do it
    if button < 0 then
        set button to "gave up"
    else
        set button to item (button - 999) of buttonList -- index using button number
    end if
    set answer to missing value
    if button is cancelButton then set accessory to missing value -- skip it
    if accessory is not (missing value) then if (accessoryType of arguments) is in {"checkbox", "radiobutton"} then -- check/radio buttons
        set answer to current application's NSMutableDictionary's alloc's init()
        repeat with anItem in accessory's contentView()'s subviews
            (answer's setValue:(anItem's state) forKey:(anItem's title)) -- full button title is key name
        end repeat
        set answer to answer as record
    else -- textFields
        set answer to accessory's stringValue as text
    end if
    set my response to {button:button, answer:answer}
end performAlert:

# Set the alert button(s).
# leftmost button has initial focus, rightmost is the default
to setButtons:buttons
    set buttonList to {}
    repeat with anItem in reverse of (buttons as list) -- arrange the same order as the list
        set anItem to anItem as text
        if anItem is not in buttonList then -- filter for duplicates
            set end of buttonList to anItem
            set theButton to (alert's addButtonWithTitle:anItem)
        end if
    end repeat
    if buttonList is {} then -- make sure there is at least one
        set end of buttonList to okButton
        set theButton to (alert's addButtonWithTitle:okButton)
    end if
    alert's |window|'s setInitialFirstResponder:theButton
    return buttonList
end setButtons:

# Set the alert icon. 
to setIcon:iconType
    set iconImage to missing value
    if iconType is "critical" then
        alert's setAlertStyle:(current application's NSCriticalAlertStyle)
    else if iconType is in {"informational", "warning"} then
        alert's setAlertStyle:(current application's NSInformationalAlertStyle)
    else if iconType is in {"Note", "Caution", "Stop"} then -- system icon  
        set iconImage to current application's NSImage's alloc's initByReferencingFile:(SYS_RESOURCES & "Alert" & iconType & "Icon.icns")
    else -- from a file - ASObjC doesn't like a bad initWithContentsOfFile, so this handles errors better
        set iconImage to current application's NSImage's alloc's initByReferencingFile:(iconType as text)
        if not iconImage's isValid as boolean then set iconImage to missing value
    end if
    if iconImage is not missing value then set alert's icon to iconImage
end setIcon:

# Get the width for an accessoryView after the alert button layout.
on accessoryWidth(addedWidth)
    if class of addedWidth is not in {integer, real} then set addedWidth to 0
    if addedWidth < 0 then set addedWidth to -addedWidth
    alert's layout()
    set width to first item of last item of (alert's |window|'s frame()) as list
    return width - 125 + addedWidth
end accessoryWidth

# Set up a single accessoryView.
to setAccessory:theType using:input addedWidth:addedWidth
    set width to accessoryWidth(addedWidth)
    if theType is "textfield" then
        set accessory to my textAccessory:input width:width secure:false
    else if theType is "securefield" then
        set accessory to my textAccessory:input width:width secure:true
    else if theType is "combobox" then
        set accessory to my comboAccessory:input width:width
    else if theType is "checkbox" then
        set accessory to my buttonAccessory:input width:width radio:false
    else if theType is "radiobutton" then
        set accessory to my buttonAccessory:input width:width radio:true
    else
        set accessory to missing value
    end if
    my adjustTimerField()
    return accessory
end setAccessory:using:addedWidth:

# Adjust the timerField's frame for the alert height.
on adjustTimerField()
    if timerField is missing value then return
    alert's layout() # get new layout
    set spacing to last item of last item of ((get alert's |window|'s frame) as list) -- top of window
    set spacing to spacing - 132 -- put it below the icon
    timerField's setFrameOrigin:[37, spacing]
    alert's |window|'s contentView's addSubview:timerField
end adjustTimerField

# Set up a [secure]textField to get user input.
# the textField will auto-size around its contents - maximum of 10 lines vertical (scroll with arrow keys)
on textAccessory:input width:width secure:secure
    if secure then
        set field to (current application's NSSecureTextField's alloc's initWithFrame:{{0, 0}, {width, 40}})
    else
        set field to (current application's NSTextField's alloc's initWithFrame:{{0, 0}, {width, 40}})
    end if
    tell field
        set its placeholderString to "Enter text" -- arbitrary
        set input to input as text
        if input ends with return then set input to text 1 thru -2 of input
        its setFont:(current application's NSFont's fontWithName:"Menlo" |size|:13) -- monospaced
        its setStringValue:input
        its setFrameSize:(its (cell's cellSizeForBounds:[[0, 0], [width, 150]])) -- auto-size for content
        its setFrameSize:[width, last item of last item of (its frame as list)] -- restore width
        alert's setAccessoryView:it
        return it
    end tell
end textAccessory:width:secure:

# Set up a combo box to get user input.
on comboAccessory:input width:width
    if not checkValue(input) then return my textAccessory:input width:width secure:false -- no items
    tell (current application's NSComboBox's alloc's initWithFrame:{{0, 0}, {width, 26}})
        set its hasVerticalScroller to true
        set its completes to true -- matches an item while manually entering  
        set its numberOfVisibleItems to 10 -- arbitrary  
        its setLineBreakMode:(current application's NSLineBreakByTruncatingMiddle)
        set its placeholderString to "Enter text or select a menu item" -- arbitrary  
        set comboList to {}
        repeat with anItem in (input as list) -- populate combo box menu
            set anItem to anItem as text
            if anItem ends with return then set anItem to text 1 thru -2 of anItem
            if anItem is not "" and anItem is not in comboList then
                (its addItemWithObjectValue:anItem)
                set end of comboList to anItem
            end if
        end repeat
        alert's setAccessoryView:it
        return it
    end tell
end comboAccessory:width:

# Set up a group of check/radio buttons to get user input.
on buttonAccessory:input width:width radio:radio
    if not checkValue(input) then return missing value -- no button items
    set input to input as list
    set height to (count input) * 26
    tell (current application's NSBox's alloc's initWithFrame:{{0, 0}, {width, (height + 11)}})
        set mainView to it
        set its titlePosition to 0
        set itemList to {}
        repeat with anItem from 1 to (count input)
            set label to (item anItem of input) as text
            if label is not "" and label is not in itemList then
                set end of itemList to label
                tell my makeButton(radio, label)
                    (its setFrame:{{0, height - anItem * 26}, {width - 15, 25}})
                    (mainView's addSubview:it)
                end tell
            end if
        end repeat
        alert's setAccessoryView:it
        return it
    end tell
end buttonAccessory:width:radio:

# Make an individual button for the buttonAccessory.
# items ending with a return are selected (state = 1)
# old and new Cocoa NSButton APIs are included
to makeButton(radio, label)
    if (system attribute "sys2") >= 12 then -- use newer API
        if radio then
            set button to current application's NSButton's radioButtonWithTitle:"" target:me action:"no_op:"
        else
            set button to current application's NSButton's checkboxWithTitle:"" target:me action:"no_op:"
        end if
    else -- old style
        set button to current application's NSButton's alloc's init()
        if radio then
            button's setButtonType:(current application's NSRadioButton)
            button's setTarget:me
            button's setAction:"no_op:"
        else
            button's setButtonType:(current application's NSSwitchButton)
        end if
    end if
    button's setLineBreakMode:(current application's NSLineBreakByTruncatingMiddle)
    if label ends with return then # set/check
        button's setState:(current application's NSOnState) -- NSControlStateValueOn
        set label to text 1 thru -2 of label -- strip the return
    end if
    button's setTitle:label
    return button
end makeButton

on no_op_(sender) -- dummy action method to group radio buttons
end no_op_

# Set up the timer textField and give-up timer.
to setupTimer:giveUpTime
    if class of giveUpTime is not in {integer, real} or giveUpTime < 1 then return missing value
    set timerField to current application's NSTextField's alloc's initWithFrame:[[0, 0], [40, 20]]
    timerField's setBordered:false
    timerField's setDrawsBackground:false
    timerField's setFont:(current application's NSFont's fontWithName:"Menlo Bold" |size|:14) -- mono-spaced
    timerField's setEditable:false
    timerField's setSelectable:false
    timerField's setAlignment:(current application's NSCenterTextAlignment)
    timerField's setToolTip:"Time Remaining"
    tell (current application's NSTimer's timerWithTimeInterval:1 target:me selector:"updateCountdown:" userInfo:(missing value) repeats:true)
        set countdown to (giveUpTime as integer)
        timerField's setStringValue:(countdown as text)
        return it
    end tell
end setupTimer:

# Update the countdown timer display.
to updateCountdown:timer
    set countdown to countdown - 1
    if countdown <= 0 then -- stop and reset for next time
        timer's invalidate()
        set timer to missing value
        set timerField to missing value
        set countdown to missing value
        current application's NSApp's abortModal()
    else
        timerField's setStringValue:(countdown as text)
    end if
end updateCountdown:

# Get the number of the button pressed, from right (1000) to left (100x).
# a negative number is returned if timed out (gave up)
on buttonPressed:timer
    if timer is not missing value then current application's NSRunLoop's mainRunLoop's addTimer:timer forMode:(current application's NSModalPanelRunLoopMode) -- start it
    set button to alert's runModal()
    if timer is not missing value then -- reset for next time
        timer's invalidate()
        set timer to missing value
        set timerField to missing value
        set countdown to missing value
    end if
    return button
end buttonPressed:

# Check value for nil or blank.
to checkValue(value)
    return value is not in {{}, "", missing value}
end checkValue

