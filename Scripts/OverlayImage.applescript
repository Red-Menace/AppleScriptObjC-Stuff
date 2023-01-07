
use AppleScript version "2.7" -- High Sierra (10.13) or later for newer enumerations
use framework "Foundation"
use scripting additions

property iconResources : POSIX path of (path to library folder from system domain) & "CoreServices/CoreTypes.bundle/Contents/Resources/" -- system icons
property baseSize : 1024 -- base image size (icons are square with maximum size 1024)
property scale : 0.55 -- scale of overlayed image (adjust as desired)
property setIcon : false -- set folder icon or save to file

on run -- overlay an image onto a folder icon
	set baseImage to getBaseImage(iconResources & "GenericFolderIcon.icns") -- or whatever icon image
	baseImage's setSize:{baseSize, baseSize}
	
	set overlayImage to getOverlayImage(choose file with prompt "Choose an application or overlay image:")
	set scaledSize to baseSize * scale
	overlayImage's setSize:{scaledSize, scaledSize}
	set offsetX to (baseSize - scaledSize) / 2 -- center (adjust as needed)
	set offsetY to (baseSize - scaledSize) / 2 - 50 -- shift down from center (adjust as needed)
	
	baseImage's lockFocus() -- set drawing context
	overlayImage's drawAtPoint:{offsetX, offsetY} fromRect:(current application's NSZeroRect) operation:(current application's NSCompositingOperationSourceOver) fraction:1.0
	baseImage's unlockFocus()
	output(baseImage)
end run

to getBaseImage(imagePath)
	set image to readImageFromFile(imagePath)
	if image is missing value then error "Base image was not found."
	return image
end getBaseImage

to getOverlayImage(imageFile)
	tell application "Finder" to if (kind of imageFile is "Application") then
		set image to current application's NSWorkspace's sharedWorkspace's iconForFile:(POSIX path of imageFile)
	else
		set image to my readImageFromFile(POSIX path of imageFile)
	end if
	if image is missing value then error "Overlay image was not found."
	return image
end getOverlayImage

to readImageFromFile(posixFile)
	set image to missing value
	set imageData to current application's NSData's dataWithContentsOfFile:posixFile
	if imageData is not missing value then set image to current application's NSImage's alloc's initWithData:imageData
	return image
end readImageFromFile

to writeImageToFile(image, posixPath)
	set imageData to image's TIFFRepresentation()
	set imageRep to current application's NSBitmapImageRep's imageRepWithData:imageData
	set imageType to imageRep's representationUsingType:(current application's NSBitmapImageFileTypePNG) |properties|:(missing value)
	imageType's writeToFile:posixPath atomically:true
end writeImageToFile

to output(image)
	if setIcon then -- set the icon for a folder
		set outputPath to POSIX path of (choose folder with prompt "Choose a folder to set its icon:")
		current application's NSWorkspace's sharedWorkspace's setIcon:image forFile:outputPath options:0
	else -- save to a file
		set outputPath to POSIX path of (((path to desktop folder) as text) & "Composite Folder Icon Image.png") -- or whatever
		writeImageToFile(image, outputPath)
	end if
end output


