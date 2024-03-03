
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSImageView example:
property mainWindow : missing value -- globals can also be used
property imageView : missing value

set my imageView to makeImageView at {20, 20} given dimensions:{200, 200} -- given arguments are optional
imageView's setImage:(current application's NSImage's alloc's initWithContentsOfFile:(POSIX path of (choose file of type "public.image"))) -- or whatever
mainWindow's contentView's addSubview:imageView
*)


# Make and return an NSImageView.
to makeImageView at origin as list given dimensions:dimensions as list : {200, 200}, bezel:bezel as boolean : false, scaling:scaling as integer : 2, autoresizingMask:autoresizingMask as integer : 0, editable:editable as boolean : false, cutCopyPaste:cutCopyPaste as boolean : false, action:action as text : "", target:target : missing value
	tell (current application's NSImageView's alloc()'s initWithFrame:{origin, dimensions})
		if bezel then its setImageFrameStyle:(current application's NSImageFrameGrayBezel)
		if scaling is not 2 then its setImageScaling:scaling
		if autoresizingMask > 0 then its setAutoresizingMask:autoresizingMask
		its setEditable:editable
		its setAllowsCutCopyPaste:cutCopyPaste
		if action is not in {"", "missing value"} then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:action -- see the following action handler
		end if
		return it
	end tell
end makeImageView


# Perform an action when when an image is dragged into the image view.
# The selector for the following is "imageDragged:", and the control is passed in `sender`.
# Cocoa objects must be coerced to the appropriate AppleScript type.
on imageAction:sender
	display dialog "An image was placed into the image view." buttons {"OK"} default button 1
end imageAction:


#
# NSImageScaling:
# NSImageScaleProportionallyDown = 0
# NSImageScaleAxesIndependently = 1
# NSImageScaleNone = 2
# NSImageScaleProportionallyUpOrDown = 3
#

# 
# NSAutoresizingMaskOptions (for combinations, add mask values together):
# NSViewNotSizable = 0
# NSViewMinXMargin = 1
# NSViewWidthSizable = 2
# NSViewMaxXMargin = 4
# NSViewMinYMargin = 8
# NSViewHeightSizable = 16
# NSViewMaxYMargin = 32
#

