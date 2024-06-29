
use AppleScript version "2.5" -- Sierra (10.12) or later
use framework "Foundation"
use scripting additions


(* NSPopUpButton example:

	In a pop-up list, the index starts at 0, with the title (automatically) set to the selected item.
	In a pull-down list, the index starts at 1, with index 0 used to (manually) store the list’s title.

property mainWindow : missing value -- globals can also be used
property popupButton : missing value

set my popupButton to makePopupButton at {20, 20} given itemList:{"one", "two", "three", "This is the fourth menu item."}, title:"two" -- given arguments are optional
mainWindow's contentView's addSubview:popupButton
*)


# Make and return an NSPopUpButton.
to makePopupButton at (origin as list) given maxWidth:maxWidth as integer : 0, itemList:itemList as list : {}, title:title as text : "", pullDown:pullDown as boolean : false, tag:tag as integer : 0, action:action as text : "popupButtonAction:", target:target : missing value
	if title is "missing value" then set title to ""
	if maxWidth < 0 then set maxWidth to 0 -- a maxWidth of 0 will size to fit the menu
	tell (current application's NSPopUpButton's alloc()'s initWithFrame:{origin, {maxWidth, 25}} pullsDown:pullDown)
		its addItemsWithTitles:itemList
		if pullDown then -- initial title
			its insertItemWithTitle:"" atIndex:0 -- add placeholder
			its setTitle:title
		else -- initial selection
			if title is not "" and title is not in itemList then set title to first item of itemList
		end if
		its selectItemWithTitle:title -- blank title (all items deselected) if empty
		if tag > 0 then its setTag:tag
		if action is not in {"", "missing value"} then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:action -- see the following action handler
		end if
		if maxWidth is 0 then -- sizeToFit works differently for pull-down (title vs menu), so do it manually
			set theSize to width of (its |menu|'s |size| as record)
			if pullDown then set theSize to theSize + 10 -- adjust for checkmark space
			its setFrameSize:{theSize, 25}
		end if
		return it
	end tell
end makePopupButton


# Perform an action when the connected popup button is pressed.
on popupButtonAction:sender
	set selected to sender's titleOfSelectedItem as text
	if (sender's pullsDown as boolean) then -- for pull-down
		sender's setTitle:selected -- synchronizeTitleAndSelectedItem doesn't want to work
		sender's sizeToFit() -- sized according to the title
	end if
	display dialog "Popup button menu item '" & selected & "' selected." buttons {"OK"} default button 1
	-- whatever
end popupButtonAction:

