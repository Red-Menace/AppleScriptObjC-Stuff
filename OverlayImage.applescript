
use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

property iconResources : POSIX path of (path to library folder from system domain) & "CoreServices/CoreTypes.bundle/Contents/Resources/"

on run -- run from the Script Editor or app double-clicked
    set main to iconResources & "KEXT.icns"
    set overlay to iconResources & "AlertCautionBadgeIcon.icns"
    set output to POSIX path of (((path to desktop folder) as text) & "composite.png")
    
    set mainImage to imageFromFile(main)
    if mainImage is missing value then error "Main image not found."
    set overlayImage to imageFromFile(overlay)
    if overlayImage is missing value then error "Overlay image not found."
    
    set rect to {{0, 0}, overlayImage's |size|() as list} -- icons are the same size
    set shift to {0, -256} -- offset of overlay onto main image
    set operation to current application's NSCompositeSourceOver
    mainImage's lockFocus() -- begin drawing
    overlayImage's drawAtPoint:shift fromRect:rect operation:operation fraction:1.0
    mainImage's unlockFocus() -- end drawing
    
    set finalImage to mainImage's TIFFRepresentation()
    set imageRep to current application's NSBitmapImageRep's imageRepWithData:finalImage
    set imageType to imageRep's representationUsingType:(current application's NSBitmapImageFileTypePNG) |properties|:(missing value)
    imageType's writeToFile:output atomically:true
end run

# Get an NSImage from a file, using NSData for better error handling.
# Returns missing value if the file is not an image or isn't found.
on imageFromFile(posixFile)
    set image to missing value
    set imageData to current application's NSData's dataWithContentsOfFile:posixFile
    if imageData is not missing value then set image to current application's NSImage's alloc's initWithData:imageData
    return image
end imageFromFile

