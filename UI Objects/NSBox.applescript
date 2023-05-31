
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property box : missing value

set my box to makeBox at {20, 20} given dimensions:{100, 50} -- given arguments are optional
mainWindow's contentView's addSubview:box
*)


# Make and return an NSBox.
to makeBox at origin given dimensions:dimensions : {10, 20}, boxType:boxType : missing value, title:title : "", titlePosition:titlePosition : 0, titleFont:titleFont : missing value, borderColor:borderColor : missing value, borderWidth:borderWidth : missing value, cornerRadius:cornerRadius : missing value, fillColor:fillColor : missing value
	tell (current application's NSBox's alloc's initWithFrame:{origin, dimensions})
		if boxType is not missing value then its setBoxType:boxType -- NSBoxSeparator (2) or NSBoxCustom (4)
		if title is not in {"", missing value} then its setTitle:title
		its setTitlePosition:titlePosition -- 0-6 or NSTitlePosition enum
		if titleFont is not missing value then its setTitleFont:titleFont
		if (boxType as integer) is 4 then -- only applies to NSBoxCustom
			if borderColor is not missing value then its setBorderColor:borderColor
			if borderWidth is not missing value then its setBorderWidth:borderWidth
			if cornerRadius is not missing value then its setCornerRadius:cornerRadius
			if fillColor is not missing value then its setFillColor:fillColor
		end if
		return it
	end tell
end makeBox


#
# NSBox title positions:
# NSNoTitle = 0
# NSAboveTop = 1
# NSAtTop = 2
# NSBelowTop = 3
# NSAboveBottom = 4
# NSAtBottom = 5
# NSBelowBottom = 6
#

