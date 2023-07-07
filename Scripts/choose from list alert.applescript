
#
# NSAlert with tableView to approximate "choose from list"
#
# A NSWindow/NSPanel can also be used, but there is a bit more layout for the UI, and deprecated methods
# need to be used to run it modally (current APIs uses blocks, which are not supported by ASObjC).
#
# Features:
#	The number of list entries to be shown can be specified so that the dialog won't fill the window
#		a setting of 0 or missing value will auto set, up to a maximum (a scroll bar is shown as needed)
#	The width can be specified (it will be clamped between the minimum and maximum)
#		a setting of 0 or missing value will auto set to the longest string, up to the maximum
#		the middle is truncated if a string is longer than the width (a tooltip will show the full string)
#		the width is for the accessory view (the alert is sized for the accessory view, and includes borders)
#	The location (lower left) of the alert dialog can be specified (adjusted if the alert will be off the screen)
#	Clicking the column header (if used) will select all rows
#	NSAttributedStrings are used to set fonts and font traits, colors, paragraph styles, etc
#


use AppleScript version "2.5" -- 10.12 Sierra and later for newer enumerations
use framework "Foundation"
use scripting additions

# alert and table view properties
property dataSource : missing value -- this will be the data (an array of dictionaries) for the tableView
property columnKey : "listItem" -- dictionary key for the column
property minWidth : 220 -- accessory view minimum width (based on alert minimum width)
property maxWidth : 720 -- accessory view maximum width (based on alert maximum width)
property rowHeight : 18 -- height of the table view rows
property maxEntries : 25 -- maximum number of table view rows shown (arbitrary)

global choices -- a list (including empty) of the item(s) chosen, or missing value for cancel


on run -- UI items need to be run on the main thread
	set choices to missing value
	if current application's NSThread's isMainThread() as boolean then
		doStuff()
	else
		my performSelectorOnMainThread:"doStuff" withObject:(missing value) waitUntilDone:true
	end if
	return choices -- note that performSelector does not return anything
end run

# Do the alert stuff.
to doStuff()
	try
		set listItems to {"First", "Peach", "Strawberry", "Pear", "Apple", "A much longer item entry to view the result of the attributed string linebreak setting (remove to use the other shorter items)", "Grape", "Orange", "Banana", "Cherry", "Tomato", "Last"}
		(choose from list listItems with multiple selections allowed and empty selection allowed) -- for comparison
		set choices to (choose from listItems) --  given width:400, entries:5) -- given arguments are optional
	on error errmess number errnum
		display alert "Error " & errnum message errmess
	end try
end doStuff

# Set up and show an alert with a tableView accessory view.
to choose from choiceList given prompt:prompt : "Please make your selection:", info:info : "", location:location : missing value, width:width : 0, entries:entries : 0, multipleSelections:multipleSelections : true
	set choiceArray to (makeDataSource for choiceList) -- the tableView items
	set accessory to makeScrollingTableView under prompt given width:width, entries:entries, multipleSelections:multipleSelections
	tell current application's NSAlert's alloc()'s init()
		its setIcon:(current application's NSImage's alloc's initByReferencingFile:"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericQuestionMarkIcon.icns") -- NSAlert always uses an icon
		its setMessageText:""
		its setInformativeText:info
		its addButtonWithTitle:"Choose"
		its addButtonWithTitle:"Cancel"
		its (|window|'s setAutorecalculatesKeyViewLoop:true)
		its setAccessoryView:accessory
		its (|window|'s setInitialFirstResponder:accessory)
		if location is not in {false, missing value} then -- add window in order to move, then continue
			its layout()
			set location to my checkFrame(second item of ((its |window|'s frame) as list), location) -- make it fit
			its (|window|'s orderBack:me)
			its (|window|'s setFrameOrigin:location)
			its |window|'s recalculateKeyViewLoop()
		end if
		return my getChoices(it, choiceArray)
	end tell
end choose

# Get choices from the choiceArray (NSArray) using the selected indexes (NSIndexSet).
# Returns a list of the choices (can be empty) or missing value.
to getChoices(alert, choiceArray)
	if (alert's runModal() as integer) is current application's NSAlertSecondButtonReturn then -- cancel
		return missing value
	else if (alert's accessoryView's documentView's isColumnSelected:0) as boolean then -- everything
		return (choiceArray's objectsAtIndexes:(current application's NSIndexSet's indexSetWithIndexesInRange:{0, (count dataSource)})) as list
	else -- selection
		return (choiceArray's objectsAtIndexes:(alert's accessoryView's documentView's selectedRowIndexes)) as list
	end if
end getChoices

# Make and return an NSScrollView containing a single column NSTableView.
to makeScrollingTableView under header given width:width : 0, entries:entries : 0, multipleSelections:multipleSelections : true
	if width is 0 then -- auto
		repeat with anItem in dataSource
			set theSize to (listItem of (contents of anItem))'s |size|()'s width as integer -- not quite accurate...
			set theSize to theSize + (count (listItem of (contents of anItem))'s |string| as text) -- ...so pad a bit
			if theSize > width then set width to theSize -- set the width to the longest string
		end repeat
	end if
	set width to clamp(minWidth, width, maxWidth)
	if entries is 0 then set entries to (count dataSource) -- auto
	set entries to clamp(1, entries, (count dataSource))
	set height to entries * rowHeight
	if multipleSelections is not false then set multipleSelections to true
	set tableView to makeTableView(current application's NSMakeRect(0, 0, width + 17, height), multipleSelections)
	tell (current application's NSTableColumn's alloc()'s initWithIdentifier:columnKey)
		(its setWidth:width)
		if header is not in {"", missing value} then -- adjust for header
			its (headerCell's setTitle:(header as text))
			set tweak to 28
		else
			(tableView's setHeaderView:(missing value))
			set tweak to 0
		end if
		(tableView's addTableColumn:it)
	end tell
	return makeScrollView(current application's NSMakeRect(0, 0, width + 17, height + tweak), tableView)
end makeScrollingTableView


##################################################
#	Accessory view and utility handlers
##################################################

to makeTableView(frame, multiple)
	tell (current application's NSTableView's alloc()'s initWithFrame:(frame))
		its setStyle:(current application's NSTableViewStylePlain)
		its setRowHeight:rowHeight
		if multiple then
			its setAllowsMultipleSelection:true
			its setAllowsColumnSelection:true
		end if
		its setAllowsEmptySelection:true
		its setDataSource:me -- for the dataSource handlers
		return it
	end tell
end makeTableView

to makeScrollView(frame, tableView)
	tell (current application's NSScrollView's alloc()'s initWithFrame:frame)
		its setDocumentView:tableView
		its setHasVerticalScroller:true
		its setScrollerStyle:(current application's NSScrollerStyleLegacy) -- always show
		its setHorizontalScrollElasticity:(current application's NSScrollElasticityNone)
		its setVerticalScrollElasticity:(current application's NSScrollElasticityNone)
		its (documentView's scrollPoint:(current application's NSMakePoint(0.0, -30.0))) -- scroll to top
		return it
	end tell
end makeScrollView

# Set up the dataSource (NSArray of NSDictionary) used by the tableView.
# Returns a NSArray of the original tableItems for use in getting the selected indexes.
to makeDataSource for tableItems
	tell current application's NSMutableArray's alloc()'s init()
		repeat with anItem in tableItems -- build an array of dictionaries for the columns of each row		
			set dict to current application's NSMutableDictionary's alloc's init()
			(dict's setObject:(my (makeAttributedString for anItem)) forKey:columnKey)
			(its addObject:dict)
		end repeat
		set my dataSource to it
	end tell
	return current application's NSArray's arrayWithArray:tableItems
end makeDataSource

# Make and return an attributed string.
to makeAttributedString for someText given lineBreakMode:lineBreakMode : 5, traitmask:traitmask : missing value, textFont:textFont : missing value, textColor:textColor : missing value
	if class of someText is not string or someText is "" then return someText
	tell current application's NSMutableParagraphStyle's alloc's init()
		if lineBreakMode is not in {false, missing value} then its setLineBreakMode:lineBreakMode
		set paraStyle to it
	end tell
	tell (current application's NSMutableAttributedString's alloc's initWithString:someText)
		its beginEditing()
		its addAttribute:(current application's NSParagraphStyleAttributeName) value:paraStyle range:{0, (its |length|)}
		if traitmask is not in {false, missing value} then its applyFontTraits:traitmask range:{0, (its |length|)}
		if textFont is not in {false, missing value} then its addAttribute:(current application's NSFontAttributeName) value:textFont range:{0, (its |length|)} -- adjust row height as needed
		if textColor is not in {false, missing value} then its addAttribute:(current application's NSForegroundColorAttributeName) value:textColor range:{0, (its |length|)}
		its endEditing()
		return it
	end tell
end makeAttributedString

# Adjust dialog origin to fit the screen with the menu bar.
to checkFrame(alertSize, location)
	set screenSize to second item of (((current application's NSScreen's screens)'s objectAtIndex:0)'s frame as list)
	set first item of location to clamp(0, first item of location, (first item of screenSize) - (first item of alertSize))
	set second item of location to clamp(0, second item of location, (second item of screenSize) - (second item of alertSize))
	return location
end checkFrame

# Clamps a value between min and max.
to clamp(min, obj, max)
	if obj < min then return min
	if obj > max then return max
	return obj
end clamp


##################################################
#	Required tableView dataSource handlers
##################################################

on numberOfRowsInTableView:sender
	return dataSource's |count|()
end numberOfRowsInTableView:

on tableView:sender objectValueForTableColumn:column row:row
	set dict to dataSource's objectAtIndex:row
	return dict's valueForKey:(column's identifier)
end tableView:objectValueForTableColumn:row:


#
# NSFontTraitMask (dependent on font) - for combinations, add mask values together:
# NSItalicFontMask = 0x00000001		(1)
# NSNarrowFontMask = 0x00000010		(16)
# NSPosterFontMask = 0x00000100		(256)
# NSBoldFontMask = 0x00000002			(2)
# NSExpandedFontMask = 0x00000020		(32)
# NSCompressedFontMask = 0x00000200	(512)
# NSCondensedFontMask = 0x00000040	(64)
# NSFixedPitchFontMask = 0x00000400	(1024)
# NSSmallCapsFontMask = 0x00000080	(128)
#

#
# NSLineBreakMode:
# NSLineBreakByClipping = 2
# NSLineBreakByTruncatingHead = 3
# NSLineBreakByTruncatingTail = 4
# NSLineBreakByTruncatingMiddle = 5
#

