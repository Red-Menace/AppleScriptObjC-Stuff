
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property textField : missing value
property labelField : missing value

set my textField to makeTextField at {100, 100} without dimensions given stringValue:"This is some testing text", placeholder:"placeholder" -- given arguments are optional
mainWindow's contentView's addSubview:textField

set my labelField to makeTextField at {100, 120} with label given stringValue:"Testing:" -- given arguments are optional
mainWindow's contentView's addSubview:labelField
*)


# Make and return a plain text NSTextField or NSSecureTextField.
# A bezel affects drawing the background, so it isn't used for labels.
to makeTextField at origin given dimensions:dimensions : {100, 22}, stringValue:stringValue : missing value, label:label : false, secure:secure : false, editable:editable : missing value, selectable:selectable : missing value, bordered:bordered : missing value, bezelStyle:bezelStyle : missing value, placeholder:placeholder : missing value, textFont:textFont : missing value, textColor:textColor : missing value, backgroundColor:backgroundColor : missing value
	set theClass to current application's NSTextField
	if label is true then
		set textField to theClass's labelWithString:stringValue
	else
		if secure is true then set theClass to current application's NSSecureTextField
		set textField to theClass's textFieldWithString:stringValue
		if bezelStyle is not missing value then
			textField's setBezeled:true
			textField's setBezelStyle:bezelStyle -- 0, 1, or enum
		end if
	end if
	if dimensions is in {{}, false, missing value} then -- size to fit
		textField's setFrameOrigin:origin
		textField's sizeToFit()
	else
		textField's setFrame:{origin, dimensions}
	end if
	if editable is not missing value then textField's setEditable:editable
	if selectable is not missing value then textField's setSelectable:selectable
	if bordered is not missing value then textField's setBordered:bordered
	if placeholder is not missing value then textField's setPlaceholderString:placeholder
	if textFont is not missing value then textField's setFont:textFont
	if textColor is not missing value then textField's setTextColor:textColor
	if backgroundColor is not missing value then textField's setBackgroundColor:backgroundColor
	return textField
end makeTextField


# 
# NSTextFieldBezelStyle:
# NSTextFieldSquareBezel = 0
# NSTextFieldRoundedBezel = 1
#

