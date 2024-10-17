
(*
	Edit select file extended attributes.
	
	New items are added, and duplicate items moved, to the beginning of the list.
	Entering a blank item for removal will delete the attribute (after a confirmation dialog).
	Items beyond the itemLimit will be removed from the end of the list.

	The kMDItemComment is not stored in Finder's .DS_Store and does not show in its Get Info dialog.
	The _kMDItemUserTags format is `tagName\n<colorNumber>`, where <colorNumber> (if used) is one of:
		0 (none), 1 (gray), 2 (green), 3 (purple), 4 (blue), 5 (yellow), 6 (red), or 7 (orange)

	Note that the Finder also keeps track of comments and tags (amongst other things) in its .DS_Store file,
		independent of extended attributes, so depending on how they are added they may not be in sync.
*)


use framework "Foundation"
use scripting additions


property xattrAttributes : {"com.apple.metadata:kMDItemWhereFroms", ¬
	"com.apple.metadata:_kMDItemUserTags", ¬
	"com.apple.metadata:kMDItemFinderComment", ¬
	"com.apple.metadata:kMDItemComment"} -- extended attributes that use an array of strings in a binary property list
property itemLimit : 5 -- the maximum number of entries


on run -- get file item(s) and attribute values
	activate me
	set attribute to (choose from list xattrAttributes with title "Extended Attributes") as text
	if attribute is "false" then return
	repeat with anItem in (choose file with prompt "Choose files for the " & quoted form of attribute & " attribute:" with multiple selections allowed)
		set itemPath to POSIX path of anItem
		set {existing, delimiter} to {readAttribute(attribute, itemPath), linefeed & tab}
		if existing is not {} then
			set {previousTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, delimiter}
			set existingText to delimiter & (existing as text)
			set AppleScript's text item delimiters to previousTID
			set buttonList to {"Remove", "Add", "No Action"} -- left-to-right
			set dialogText to "Existing values: " & return & existingText & linefeed & linefeed & "Enter string to add/remove:"
		else
			set {buttonList, dialogText} to {{"Add", "No Action"}, "Enter string for the attribute:"}
		end if
		activate me
		set {button, response} to {button returned, text returned} of (display dialog "Attribute:  " & attribute & linefeed & "File:  " & anItem & linefeed & linefeed & dialogText with title "Edit Extended Attribute" default answer "" buttons buttonList default button (last item of buttonList))
		if button is "Add" and response is not "" then addAttribute(attribute, response, itemPath)
		if button is "Remove" then removeAttribute(attribute, response, existing, itemPath)
	end repeat
end run

to addAttribute(attribute, newItem, posixPath) -- add to existing attribute, trimming duplicates
	set attributeItems to readAttribute(attribute, posixPath)
	set beginning of attributeItems to (newItem as text) -- new entry at the beginning
	set attributeItems to ((current application's NSOrderedSet's orderedSetWithArray:attributeItems)'s array()) as list
	writeAttribute(attribute, attributeItems, posixPath)
end addAttribute

to readAttribute(attribute, posixPath) -- read the list of attribute items
	try
		set theResult to (do shell script "xattr -px " & attribute & " " & quoted form of posixPath) # print hex
		set plist to (do shell script "echo " & quoted form of theResult & " | xxd -r -p | plutil -convert xml1 -o - -") # reverse hexdump
		set theData to (current application's NSString's stringWithString:plist)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
		set {theResult, failure} to current application's NSPropertyListSerialization's propertyListWithData:theData options:(current application's NSPropertyListMutableContainersAndLeaves) format:(missing value) |error|:(reference)
		if failure is not missing value then error failure's localizedString as text
		return theResult as list
	on error errmess
		log errmess
		return {}
	end try
end readAttribute

to writeAttribute(attribute, attributeItems, posixPath) -- set the attribute to a list of items
	tell attributeItems to if (count it) > itemLimit then set attributeItems to items 1 thru itemLimit of it -- trim length
	set theData to (current application's NSPropertyListSerialization's dataWithPropertyList:attributeItems format:(current application's NSPropertyListXMLFormat_v1_0) options:0 |error|:(missing value))
	set plist to (current application's NSString's alloc's initWithData:theData encoding:(current application's NSUTF8StringEncoding)) as text
	set bplist to do shell script "echo " & quoted form of plist & " | plutil -convert binary1 -o - - | xxd -p"
	do shell script "xattr -w -x " & attribute & " " & bplist & space & quoted form of posixPath
end writeAttribute

to removeAttribute(attribute, entry, currentItems, posixPath) -- remove an item or delete the extended attribute
	if currentItems is {} then return -- empty or no attribute
	if entry is not "" then -- remove the specified entry
		if entry is not in currentItems then return
		set newList to {}
		repeat with anItem in currentItems
			if contents of anItem is not entry then set end of newList to anItem
		end repeat
		if newList is not {} then return writeAttribute(attribute, newList, posixPath) -- remaining items
	end if
	if button returned of (display dialog "Confirm deletion of the " & quoted form of attribute & " extended attribute for " & quoted form of posixPath & "." with title "Attribute Deletion" buttons {"Yes", "No"} default button 2) is "No" then return
	do shell script "/usr/bin/xattr -d " & attribute & " " & quoted form of posixPath
end removeAttribute

