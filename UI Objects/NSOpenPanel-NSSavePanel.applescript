
#
# Handlers to create NSOpen and NSSave panels and accessory view.
#
# Common panel settings:
#		message:				prompt text
#		allowedTypes:			file types/extensions/URIs alowed
#		buttonName:			the "select" button name
#		directory:			starting directory
#		showHidden:			show hidden items
#		traversePackages:	traverse package contents
#
# The Save and Open panels have additional unique settings.
# Given handler arguments are optional and have default values (change as desired).
#
# An accessory view can also be used - the default view contains checkboxes and actions for:
#		"Show hidden items"		shows hidden file items
#		"Look into packages"	allows navigation into packages/bundles (refresh doesn't work very well)
#		"Choose files"			for an NSOpen panel, allows files to be chosen
#		"Choose folders"			for an NSOpen panel, allows folders to be chosen
#


use AppleScript version "2.5" -- El Capitan (10.11) or later
use framework "Foundation"
use scripting additions -- StandardAdditions.osax


property reply : missing value -- performSelectorOnMainThread doesn't return anything


on run -- example
	if current application's NSThread's isMainThread() as boolean then
		showPanels()
	else
		my performSelectorOnMainThread:"showPanels" withObject:(missing value) waitUntilDone:true
	end if
	return reply
end run


on showPanels() -- UI stuff needs to be done on the main thread
	try
		set my reply to showSavePanel for "This is an NSSavePanel example" with accessory
		log result
		set my reply to showOpenPanel for "This is an NSOpenPanel example" with accessory and chooseFolders
		log result
	on error errmess number errnum
		display alert "Error " & errnum message errmess
	end try
end showPanels


##################################################
# NSOpenPanel - must be run in foreground
##################################################

# Create and display an NSOpenPanel.
to showOpenPanel for message given allowedTypes:allowedTypes : missing value, buttonName:buttonName : missing value, directory:directory : missing value, showHidden:showHidden : false, traversePackages:traversePackages : false, accessory:accessory : missing value, returnPosix:returnPosix : true, chooseFiles:chooseFiles : true, chooseFolders:chooseFolders : false, allowMultiple:allowMultiple : true, showAccessory:showAccessory : false
	tell current application's NSOpenPanel's openPanel()
		if allowedTypes is not in {"", {}, missing value} then its setAllowedFileTypes:(allowedTypes as list)
		set {its canChooseFiles, its canChooseDirectories} to {chooseFiles, chooseFolders}
		set {its allowsMultipleSelection, its accessoryViewDisclosed} to {allowMultiple, showAccessory}
		(my (commonSetup for it given message:message, buttonName:buttonName, directory:directory, showHidden:showHidden, traversePackages:traversePackages, accessory:accessory))
		set reply to its runModal()
		if reply is current application's NSFileHandlingPanelCancelButton then return missing value
		set my reply to its URLs() as list
		if returnPosix is not in {false, missing value} then
			repeat with anItem in reply -- coerce the paths in place
				tell anItem to set its contents to its POSIX path
			end repeat
		end if
		return reply
	end tell
end showOpenPanel


##################################################
# NSSavePanel - must be run in foreground
##################################################

# Create and display an NSSavePanel.
to showSavePanel for message given title:title : missing value, allowedTypes:allowedTypes : missing value, buttonName:buttonName : missing value, directory:directory : missing value, showHidden:showHidden : false, traversePackages:traversePackages : false, accessory:accessory : missing value, returnPosix:returnPosix : true, nameLabel:nameLabel : missing value, nameString:nameString : missing value, showTagField:showTagField : false, tagNames:tagNames : missing value, createFolders:createFolders : true
	tell current application's NSSavePanel's savePanel()
		if title is not in {"", missing value} then set its title to title as text
		if allowedTypes is not in {"", {}, missing value} then its setAllowedContentTypes:(allowedTypes as list)
		if nameLabel is not in {"", missing value} then set its nameFieldLabel to nameLabel as text
		if nameString is not in {"", missing value} then set its nameFieldStringValue to nameString as text
		set {its showsTagField, its canCreateDirectories} to {showTagField, createFolders}
		if tagNames is not in {"", {}, missing value} then set its tagNames to (tagNames as list)
		(my (commonSetup for it given message:message, buttonName:buttonName, directory:directory, showHidden:showHidden, traversePackages:traversePackages, accessory:accessory))
		set reply to its runModal()
		if reply is current application's NSFileHandlingPanelCancelButton then return missing value
		set reply to its |URL|() as «class furl»
		if returnPosix is not in {false, missing value} then set reply to POSIX path of reply
		return reply
	end tell
end showSavePanel


##################################################
# Common panel handlers
##################################################

# Set common panel options.
on commonSetup for panel given message:message, buttonName:buttonName, directory:directory, showHidden:showHidden, traversePackages:traversePackages, accessory:accessory
	tell panel
		set its allowsConcurrentViewDrawing to true
		if message is not in {"", missing value} then its setMessage:message
		if buttonName is not in {"", missing value} then set its prompt to buttonName as text
		if directory is not in {"", missing value} then set its directoryURL to current application's NSURL's URLWithString:(directory as text)
		set {its showsHiddenFiles, its treatsFilePackagesAsDirectories} to {showHidden, traversePackages}
		if accessory is not in {false, missing value} then if accessory is true then -- default
			tell (current application's NSBox's alloc's initWithFrame:{{0, 0}, {300, 34}})
				set its titlePosition to 0
				its addSubview:(my createCheckbox({{0, 0}, {140, 20}}, "Show hidden items", panel's showsHiddenFiles))
				its addSubview:(my createCheckbox({{150, 0}, {140, 20}}, "Look into packages", panel's treatsFilePackagesAsDirectories))
				if panel's isKindOfClass:(current application's NSOpenPanel) then
					its setFrame:{{0, 0}, {300, 55}}
					its addSubview:(my createCheckbox({{0, 20}, {140, 20}}, "Choose folders", panel's canChooseDirectories))
					its addSubview:(my createCheckbox({{150, 20}, {140, 20}}, "Choose files", panel's canChooseFiles))
				end if
				set accessory to it
			end tell
			its setAccessoryView:accessory
		end if
	end tell
end commonSetup


##################################################
# Accessory view handlers
##################################################

# Create and return a checkbox button to be added to the accessoryView.
to createCheckbox(frame, title, state)
	set theButton to current application's NSButton's alloc's initWithFrame:frame
	theButton's setButtonType:(current application's NSButtonTypeSwitch) -- NSSwitchButton
	tell theButton to set {its title, its state, its target} to {title, state, me}
	theButton's setAction:"panelOptions:"
	return theButton
end createCheckbox


# Handle button items in the accessoryView
on panelOptions:sender
	try
		set buttonTitle to (sender's title) as text
		set panelWindow to sender's |window|'s parentWindow -- checkbox > box > accessory > panel
		if buttonTitle is "Choose files" then
			panelWindow's setCanChooseFiles:(sender's state)
		else if buttonTitle is "Choose folders" then
			panelWindow's setCanChooseDirectories:(sender's state)
		else if buttonTitle is "Show hidden items" then
			panelWindow's setShowsHiddenFiles:(sender's state)
		else if buttonTitle is "Look into packages" then
			panelWindow's setTreatsFilePackagesAsDirectories:(sender's state)
		else
			log "no match for button title"
		end if
		panelWindow's validateVisibleColumns() -- doesn't work very well
		panelWindow's display() -- update
	on error errmess number errnum
		display alert "Error " & errnum message errmess
	end try
end panelOptions:

