
use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

property useBinary : missing value

on run -- get file item(s) and whereFrom text
	set input to (choose file) -- with multiple selections allowed
	repeat with anItem in input
		tell application "Finder"
			activate
			open information window of anItem -- whereFroms are in the "More Info" section
		end tell
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
	set attribute to missing value
	set useBinary to missing value -- keep track of which it is
	try -- get existing attribute as property list
		set attribute to (do shell script "xattr -p com.apple.metadata:kMDItemWhereFroms " & filePath & "  | xxd -r -p | plutil -convert xml1 -o - -") -- convert from binary
		set useBinary to true
	on error -- oops, not a binary plist, so try XML
		try -- skip error if no attribute
			set attribute to (do shell script "xattr -p com.apple.metadata:kMDItemWhereFroms " & filePath)
			set useBinary to false
		end try
	end try
	if attribute is in {missing value, ""} then return {}
	# deserialize the list from the property list string
	set theData to (current application's NSString's stringWithString:attribute)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
	return (current application's NSPropertyListSerialization's propertyListWithData:theData options:(current application's NSPropertyListMutableContainersAndLeaves) format:(missing value) |error|:(missing value)) as list
end readWhereFroms

to writeWhereFroms(theList, filePath) -- set the extended attribute to a list of whereFroms
	set filePath to quoted form of POSIX path of filePath
	# serialize the list into a property list string
	set theData to (current application's NSPropertyListSerialization's dataWithPropertyList:theList format:(current application's NSPropertyListXMLFormat_v1_0) options:0 |error|:(missing value))
	set plist to (current application's NSString's alloc's initWithData:theData encoding:(current application's NSUTF8StringEncoding)) as text
	if useBinary is false then -- set XML plist
		do shell script "xattr -w com.apple.metadata:kMDItemWhereFroms " & quoted form of plist & space & filePath
	else -- convert and set binary plist
		set bplist to do shell script "echo " & quoted form of plist & " | plutil -convert binary1 -o - - | xxd -p"
		do shell script "xattr -w -x com.apple.metadata:kMDItemWhereFroms " & bplist & space & filePath
	end if
end writeWhereFroms

