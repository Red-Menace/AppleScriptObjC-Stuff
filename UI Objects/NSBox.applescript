
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSBox example:
property mainWindow : missing value -- globals can also be used
property box : missing value

set my box to makeBox at {20, 20} given dimensions:{100, 50} -- given arguments are optional
mainWindow's contentView's addSubview:box
*)


# Make and return a NSBox.
to makeBox at (origin as list) given dimensions:dimensions as list : {10, 20}, boxType:boxType as integer : 0, title:title as text : "", titlePosition:titlePosition as integer : 0, titleFont:titleFont : missing value, borderColor:borderColor : missing value, borderWidth:borderWidth : missing value, cornerRadius:cornerRadius : missing value, fillColor:fillColor : missing value
	tell (current application's NSBox's alloc()'s initWithFrame:{origin, dimensions})
		if boxType is not 0 then its setBoxType:boxType -- 0|2|4 or NSBoxType enum
		if title is not "" then its setTitle:title
		its setTitlePosition:titlePosition -- 0-6 or NSTitlePosition enum
		if titleFont is not missing value then its setTitleFont:titleFont -- NSFont
		if boxType is 4 then -- only applies to NSBoxCustom
			if borderColor is not missing value then its setBorderColor:borderColor -- NSColor
			if borderWidth is not missing value then its setBorderWidth:(borderWidth as real)
			if cornerRadius is not missing value then its setCornerRadius:(cornerRadius as real)
			if fillColor is not missing value then its setFillColor:fillColor -- NSColor
		end if
		return it
	end tell
end makeBox


#
# NSBoxType:
# NSBoxPrimary = 0
# NSBoxSecondary =1		(deprecated macOS 10.15)
# NSBoxSeparator = 2
# NSBoxOldStyle = 3		(deprecated macOS 10.15)
# NSBoxCustom = 4
#

#
# NSTitlePosition:
# NSNoTitle = 0
# NSAboveTop = 1
# NSAtTop = 2
# NSBelowTop = 3
# NSAboveBottom = 4
# NSAtBottom = 5
# NSBelowBottom = 6
#

