
use AppleScript version "2.5" -- Sierra (10.12) or later
use framework "Foundation"
use scripting additions


(* example:
property mainWindow : missing value -- globals can also be used
property popupButton : missing value

set my popupButton to makePopupButton at {20, 20} given dimensions:{100, 25}, itemList:{"one", "two", "three", "four"} -- given arguments are optional
mainWindow's contentView's addSubview:popupButton
*)


# Make and return an NSPopUpButton.
# In a pop-up list, the index starts at 0, with the title (automatically) being the checked/selected item.
# In a pull-down list, the index starts at 1, with index 0 used to (manually) store the list’s title.
# The pull-down title (if any) will be added to the beginning of the list.
to makePopupButton at origin given dimensions:dimensions : missing value, itemList:itemList : {}, title:title : missing value, pullsDown:pullsDown : false, tag:tag : missing value, action:action : "popupButtonAction:", target:target : missing value
	if dimensions is in {{}, 0, false, missing value} then set dimensions to {0, 0}
	tell (current application's NSPopUpButton's alloc's initWithFrame:{origin, dimensions} pullsDown:pullsDown)
		if pullsDown is true then if title is not in {"", missing value} then
			set begining of itemList to title
			its setTitle:title
		end if
		its addItemsWithTitles:itemList
		if tag is not missing value then its setTag:tag
		if action is not missing value then
			if target is missing value then set target to me -- 'me' can't be used as an optional default
			its setTarget:target
			its setAction:(action as text) -- see the following action handler
		end if
		if dimensions is {0, 0} then its sizeToFit()
		return it
	end tell
end makePopupButton


# Perform an action when the connected popup button is pressed.
# also see selectedItem, titleOfSelectedItem, indexOfSelectedItem
on popupButtonAction:sender
	display dialog "Popup button menu item '" & (sender's titleOfSelectedItem as text) & "' selected." buttons {"OK"} default button 1
	-- whatever
end popupButtonAction:

