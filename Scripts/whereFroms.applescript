
use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions


on run -- get file item(s) and whereFrom text
	set input to (choose file with multiple selections allowed)
	repeat with anItem in input
		tell application "Finder"
			activate
			open information window of anItem -- whereFroms are in the "More Info" section
		end tell
		activate me
		set response to (display dialog "Enter text to add to whereFroms:" default answer "" buttons {"Enter", "Skip"} default button 2)
		if button returned of response is "Enter" then
			addWhereFrom(text returned of response, anItem)
		end if
	end repeat
end run

to addWhereFrom(newItem, filePath) -- add to existing whereFroms, trimming duplicates
	set whereFroms to readWhereFroms(filePath)
	set end of whereFroms to (newItem as text)
	set whereFroms to (current application's NSOrderedSet's orderedSetWithArray:whereFroms)'s allObjects()
	writeWhereFroms(whereFroms, filePath)
end addWhereFrom

to readWhereFroms(filePath) -- get a list of whereFroms from the extended attribute
	set filePath to quoted form of POSIX path of filePath
	try
		set theResult to (do shell script "xattr -px com.apple.metadata:kMDItemWhereFroms " & filePath) # print hex
		set plist to (do shell script "echo " & quoted form of theResult & " | xxd -r -p | plutil -convert xml1 -o - -") # reverse hexdump
		set theData to (current application's NSString's stringWithString:plist)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
		set {theResult, theError} to current application's NSPropertyListSerialization's propertyListWithData:theData options:(current application's NSPropertyListMutableContainersAndLeaves) format:(missing value) |error|:(reference)
		if theError is not missing value then error theError's localizedString as text
		return theResult as list
	on error errmess
		log errmess
		return {}
	end try
end readWhereFroms

to writeWhereFroms(theList, filePath) -- set the extended attribute to a list of whereFroms
	set filePath to quoted form of POSIX path of filePath
	# serialize the list into a property list string
	set theData to (current application's NSPropertyListSerialization's dataWithPropertyList:theList format:(current application's NSPropertyListXMLFormat_v1_0) options:0 |error|:(missing value))
	set plist to (current application's NSString's alloc's initWithData:theData encoding:(current application's NSUTF8StringEncoding)) as text
	set bplist to do shell script "echo " & quoted form of plist & " | plutil -convert binary1 -o - - | xxd -p"
	do shell script "xattr -w -x com.apple.metadata:kMDItemWhereFroms " & bplist & space & filePath
end writeWhereFroms

