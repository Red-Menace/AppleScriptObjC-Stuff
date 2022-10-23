
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property imageView : missing value

set my imageView to makeImageView at {20, 20} given dimensions:{200, 200} -- given arguments are optional
imageView's setImage:(current application's NSImage's alloc's initWithContentsOfFile:(POSIX path of (choose file of type "public.image"))) -- or whatever
mainWindow's contentView's addSubview:imageView
*)


# Make and return an NSImageView.
to makeImageView at origin given dimensions:dimensions : {200, 200}, bezel:bezel : false, scaling:scaling : missing value, editable:editable : true, cutCopyPaste:cutCopyPaste : false, action:action : "imageAction:", target:target : missing value
	tell (current application's NSImageView's alloc()'s initWithFrame:{origin, dimensions})
		if bezel is true then its setImageFrameStyle:(current application's NSImageFrameGrayBezel)
		if scaling is not missing value then its setImageScaling:scaling
		if editable is not false then its setEditable:true
		if cutCopyPaste is not false then its setAllowsCutCopyPaste:true
		if action is not missing value then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:(action as text) -- see the following action handler
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
# NSImageScaling behavior:
# NSImageScaleProportionallyDown = 0
# NSImageScaleAxesIndependently = 1
# NSImageScaleNone = 2
# NSImageScaleProportionallyUpOrDown = 3
#

