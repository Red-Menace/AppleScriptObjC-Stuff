
use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

property userFolder : missing value

on run -- get file item(s) and extract folder names for tags
	set input to (choose file) -- with multiple selections allowed
	repeat with anItem in input
		set pieces to getPathPieces(anItem)
		addTags(pieces, anItem)
	end repeat
end run

to getPathPieces(filePath) -- break path apart at delimiters
	set filePath to filePath as text
	if filePath begins with userFolder then set filePath to text ((length of userFolder) + 1) thru -1 of filePath -- trim user
	set {tempTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
	set pathPieces to text items 1 thru -2 of filePath -- skip file name
	set AppleScript's text item delimiters to tempTID
	return pathPieces
end getPathPieces

to addTags(tagList, filePath) -- add to existing tags, trimming duplicates
	set theTags to tagList & readTags(filePath)
	set theTags to (current application's NSOrderedSet's orderedSetWithArray:theTags)'s allObjects()
	writeTags(theTags, filePath)
end addTags

to readTags(filePath) -- get current tags
	set theURL to current application's NSURL's fileURLWithPath:(POSIX path of filePath)
	set {theResult, theTags} to theURL's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
	if theTags is equal to missing value then return {} -- no items
	return theTags as list
end readTags

to writeTags(tagList, filePath) -- set tags
	set theURL to current application's NSURL's fileURLWithPath:(POSIX path of filePath)
	theURL's setResourceValue:tagList forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
end writeTags

to setTagColor(theTag, tagColor)
	# The optional color index is separated by a linefeed.
	# Colors are      0 = None    1 = Gray    2 = Green   3 = Purple
	#                 4 = Blue    5 = Yellow  6 = Red     7 = Orange
	if class of tagColor is integer then -- index
		set theColor to tagColor mod 8
	else -- name
		set dict to current application's NSDictionary's dictionaryWithDictionary:{gray:1, green:2, purple:3, blue:4, yellow:5, red:6, orange:7}
		set theColor to dict's objectForKey:tagColor
		if theColor is missing value then set theColor to 0
	end if
	return theTag & linefeed & (theColor as text)
end setTagColor

