
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSTextField example:
property mainWindow : missing value -- globals can also be used
property textField : missing value
property labelField : missing value

set my textField to makeTextField at {100, 100} given stringValue:"This is some testing text", placeholder:"placeholder" -- given arguments are optional
mainWindow's contentView's addSubview:textField

set my labelField to makeTextField at {100, 120} with label given stringValue:"Testing:" -- given arguments are optional
mainWindow's contentView's addSubview:labelField
*)


# Make and return a plain text NSTextField or NSSecureTextField.
# Note that a bezel affects drawing the background, and backgroundColor is not used for labels.
to makeTextField at (origin as list) given dimensions:dimensions as list : {}, stringValue:stringValue as text : "", label:label as boolean : false, secure:secure as boolean : false, lineBreakMode:lineBreakMode as integer : 5, editable:editable as boolean : true, selectable:selectable as boolean : true, bordered:bordered as boolean : true, bezeled:bezeled as boolean : true, bezelStyle:bezelStyle : 0, placeholder:placeholder as text : "", textFont:textFont : missing value, textColor:textColor : missing value, backgroundColor:backgroundColor : missing value
	set theClass to current application's NSTextField
	if label then
		set textField to theClass's labelWithString:stringValue
	else
		if secure then set theClass to current application's NSSecureTextField
		set textField to theClass's textFieldWithString:stringValue
		if bezeled then
			textField's setBezeled:true
			textField's setBezelStyle:bezelStyle -- 0-1 or NSTextFieldBezelStyle enum
		end if
		textField's setEditable:editable
		textField's setSelectable:selectable
		textField's setBordered:bordered
		if backgroundColor is not missing value then textField's setBackgroundColor:backgroundColor -- NSColor
		if placeholder is not "" then textField's setPlaceholderString:placeholder
	end if
	if textFont is not missing value then textField's setFont:textFont -- NSFont
	if textColor is not missing value then textField's setTextColor:textColor -- NSColor
	textField's setLineBreakMode:lineBreakMode -- 0-5 or NSLineBreakMode enum
	if dimensions is {} then -- size to fit
		textField's setFrameOrigin:origin
		textField's sizeToFit()
	else
		textField's setFrame:{origin, dimensions}
	end if
	return textField
end makeTextField


# 
# NSTextFieldBezelStyle:
# NSTextFieldSquareBezel = 0
# NSTextFieldRoundedBezel = 1
#

#
# NSLineBreakMode:
# NSLineBreakByWordWrapping = 0
# NSLineBreakByCharWrapping = 1
# NSLineBreakByClipping = 2
# NSLineBreakByTruncatingHead = 3
# NSLineBreakByTruncatingTail = 4
# NSLineBreakByTruncatingMiddle = 5
#


