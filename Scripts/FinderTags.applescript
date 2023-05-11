
# IMPORTANT NOTE:  getting tags from the Finder varies depending on the OS version.
# Although the following script has been tested with 10.12 Sierra, 10.15 Catalina,
# and 12.6 Monterey, there is no official documentation or API available.  However...
#
# NSWorkspace can return the default tags and colors
# NSURL has methods to get/set file tag and color resources
# The xattr shell utility can get/set extended attributes for file tags
#
# From macOS 10.9 Mavericks thru macOS 11 Big Sur, Finder tags are in a preference plist:
#	~/Library/SyncedPreferences/com.apple.finder.plist
# 		key: "values" => "FinderTagDict" => "value" => "FinderTags"
#
# For macOS 12 Monterey (and presumably later), Finder tags are in an SQLite database:
#	~/Library/SyncedPreferences/com.apple.kvs/com.apple.KeyValueService-Production.sqlite
# 		SQLite:  select ZPLISTDATAVALUE from ZSYDMANAGEDKEYVALUE where ZKEY = 'FinderTagDict'
#
# Both are an NSDictionary, with the "FinderTags" key containing an array of dictionaries:
#	key: "n" => (name) - the tag name
#	key: "l" => (label) - missing, or an index if a color has been set - see below
#	key: "v" => (sidebar visibility) - if false the tag is not visible in the sidebar
#	key: "p" => (?)
#
# The color of an existing Finder tag name takes precedent, and it may take a moment for
# Spotlight and the Finder to sync.  The tag colors and their indexes are:
#		None = 0 or missing value
#		Gray = 1
#		Green = 2
#		Purple = 3
#		Blue = 4
#		Yellow = 5
#		Red = 6
#		Orange = 7
#
# Note that the property lists are only updated when a tag is created in the Finder preferences, or
# when it is actually used by the Finder (tags added with xattr don't immediately update the list).
#
# When using xattr, tags consist of the name and an optional color index separated by a linefeed.
# The utility is not used here, but an option has been included to provide a similar output.
#


use AppleScript version "2.3" -- macOS 10.9 Mavericks and later
use framework "Foundation"
use scripting additions


on run -- example
	set test to getTagDict() -- get the source NSDictionary to roll your own output
	return getTagInfo for "name" -- output the tags as an Applescript list or record
end run


# Return Finder tags using the specified option.
to getTagInfo for option --  "dict", "name", "index", "combo", "attr"
	set tagDict to getTagDict()
	set {keyPath, separator} to {"FinderTags", " = "}
	set labelColors to {"Gray", "Green", "Purple", "Blue", "Yellow", "Red", "Orange"}
	if option is "dict" then -- the complete dictionary
		return tagDict as record
	else if option is "name" then -- a list of the tag names
		set keyPath to keyPath & ".n"
	else if option is "index" then -- a list of the tag color indexes
		set keyPath to keyPath & ".l"
	else if option is in {"combo", "attr"} then -- a list of the tag names with their colors
		set combo to {}
		repeat with theRecord in (tagDict's valueForKeyPath:keyPath)
			set theName to (theRecord's objectForKey:"n") as text
			set theColor to (theRecord's objectForKey:"l")
			if theColor is missing value then set theColor to ""
			if option is "attr" then -- name and color index as xattr attribute
				if theColor is not "" then set theColor to linefeed & theColor
			else -- name followed by color (can split at separator as desired)
				if theColor is "" then
					set theColor to separator & "None"
				else
					set theColor to separator & item (theColor as integer) of labelColors
				end if
			end if
			set the end of combo to theName & theColor
		end repeat
		return combo
	end if
	return (tagDict's valueForKeyPath:keyPath) as list -- default is a list of records
end getTagInfo


to getTagDict() -- get a dictionary from the appropriate property list
	set basePath to POSIX path of (path to library folder from user domain)
	if (get system attribute "sys1") > 11 then -- from sqlite database in macOS 12 Monterey and greater
		set prefsPath to basePath & "SyncedPreferences/com.apple.kvs/com.apple.KeyValueService-Production.sqlite"
		set query to "select hex(ZPLISTDATAVALUE) from ZSYDMANAGEDKEYVALUE where ZKEY = 'FinderTagDict';"
		set plist to (do shell script "sqlite3 " & prefsPath & space & quoted form of query & " | xxd -r -p | plutil -convert xml1 -o - -") -- get binary plist from database and convert
		set theData to (current application's NSString's stringWithString:plist)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
		set keyPath to ""
	else -- from property list file in macOS 10.9 Mavericks thru macOS 11 Big Sur
		set prefsPath to basePath & "SyncedPreferences/com.apple.finder.plist"
		set theData to current application's NSData's dataWithContentsOfFile:prefsPath
		set keyPath to "values.FinderTagDict.value"
	end if
	set {theDict, theError} to current application's NSPropertyListSerialization's propertyListWithData:theData options:0 format:(missing value) |error|:(reference)
	if theDict is missing value then error theError's localizedDescription() as text
	if keyPath is "" then return theDict
	return theDict's valueForKeyPath:keyPath
end getTagDict

