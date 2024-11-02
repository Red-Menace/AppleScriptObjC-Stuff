
#
# Get text from an image using the Vision framework. 
# The clipboard is checked for image data, otherwise a file is used.
# Can also use a screencapture selection.
# Displays a dialog and returns an array of the text items found.
#

use framework "Foundation"
use scripting additions

property generalPasteboard : a reference to current application's NSPasteboard's generalPasteboard
property NSImage : a reference to current application's NSImage
property useCapture : false -- use screencapture?


on run -- examples
	if useCapture then -- copy screencapture selection to clipboard
		do shell script "screencapture -ci" -- needs accessibility permissions for Screen & System Audio Recording
		set theImage to NSImage's alloc()'s initWithPasteboard:generalPasteboard
	end if
	
	get clipboard info -- get info about the clipboard
	
	tell generalPasteboard to set theData to its dataForType:(its availableTypeFromArray:(current application's NSArray's arrayWithArray:{current application's NSPasteboardTypePNG, current application's NSPasteboardTypeTIFF}))
	if theData is not missing value then -- clipboard has image data
		set theImage to NSImage's alloc()'s initWithData:theData
	else
		set imagePath to POSIX path of (choose file of type "public.image")
		set theImage to NSImage's alloc()'s initWithContentsOfFile:imagePath
	end if
	
	set textItems to (getText from theImage)
	set {previousTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, linefeed}
	set {dialogText, AppleScript's text item delimiters} to {textItems as text, previousTID}
	display dialog dialogText with title "Results" buttons {"OK"}
	return textItems
end run


to getText from image
	set requestHandler to current application's VNImageRequestHandler's alloc()'s initWithData:(image's TIFFRepresentation()) options:(missing value)
	set theRequest to current application's VNRecognizeTextRequest's alloc()'s init()
	set {success, failure} to requestHandler's performRequests:(current application's NSArray's arrayWithObject:theRequest) |error|:(reference)
	if success then
		set textPieces to {}
		repeat with observation in theRequest's results() -- VNRecognizedTextObservation objects
			set end of textPieces to ((first item in (observation's topCandidates:1))'s |string|() as text)
		end repeat
		return textPieces
	else
		return (failure's localizedDescription) as text
	end if
end getText

