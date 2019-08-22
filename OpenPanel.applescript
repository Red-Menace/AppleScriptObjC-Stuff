
use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Cocoa"
use scripting additions

# initial checkbox button properties
property buttonList : [Â
    {title:"Select Folders", frame:[{5, 5}, {120, 20}], selector:"canChooseDirectories", value:true}, Â
    {title:"Select Files", frame:[{5, 30}, {150, 20}], selector:"canChooseFiles", value:true}, Â
    {title:"Show Packages", frame:[{150, 5}, {120, 20}], selector:"treatsFilePackagesAsDirectories", value:false}, Â
    {title:"Show Hidden", frame:[{150, 30}, {120, 20}], selector:"showsHiddenFiles", value:false}]

property defaultDirectory : POSIX path of (path to desktop) -- a place to start
property setup : missing value

global response, newer

on run -- run from the Script Editor or app double-clicked
    initialize()
    my performPanel:me
end run

on open someItems -- items dropped onto the app
    initialize()
    processItems(someItems)
end open

on initialize() -- set stuff up when first run
    if setup is not missing value then return
    set newer to (system attribute "sys2") ³ 12 -- system version
    set mainMenu to current application's NSApplication's sharedApplication's mainMenu
    set fileMenu to (mainMenu's itemAtIndex:1)'s submenu
    set openItem to fileMenu's indexOfItemWithTitle:"OpenÉ"
    if openItem as integer is -1 then -- no "OpenÉ" menuItem, so add one to the app
        set menuItem to current application's NSMenuItem's alloc's Â
            initWithTitle:"OpenÉ" action:"performPanel:" keyEquivalent:"o"
        menuItem's setTarget:me
        fileMenu's addItem:menuItem
    end if
end initialize

to processItems(value) -- handle items to open (example just shows dropped/selected file paths)
    if value is missing value then return
    set tempTID to AppleScript's text item delimiters
    set AppleScript's text item delimiters to return
    set output to value as text
    set AppleScript's text item delimiters to tempTID
    display dialog output with title "Result" buttons {"OK"}
end processItems

to performPanel:sender -- run the panel on the main thread (so it can also be used in the Script Editor)
    set response to missing value
    my performSelectorOnMainThread:"getFileItems" withObject:(missing value) waitUntilDone:true
    processItems(response)
end performPanel:

to getFileItems() -- do the open panel thing
    tell current application's NSOpenPanel's openPanel()
        its setFloatingPanel:true
        its setTitle:"Panel Test"
        its setPrompt:"Choose" -- the button name
        its setMessage:"Choose some stuff:"
        if setup is missing value then -- only use default on the first run
            its setDirectoryURL:(current application's NSURL's alloc's initFileURLWithPath:defaultDirectory)
            set setup to true
        end if
        repeat with aButton in buttonList
            (its setValue:(aButton's value) forKey:(aButton's selector))
        end repeat
        my makeAccessory(it)
        its setAllowsMultipleSelection:true
        
        set theResult to its runModal() -- show the panel
        if theResult is (current application's NSFileHandlingPanelCancelButton) then return -- cancel button
        set response to its URLs as list -- pass on the list of file objects
    end tell
end getFileItems

to makeAccessory(panel) -- make an accessory view for the panel
    tell (current application's NSBox's alloc's initWithFrame:[{0, 0}, {285, 70}])
        its setTitlePosition:0
        repeat with aButton in buttonList -- add some buttons
            set check to my makeCheckbox(aButton's title, aButton's frame)
            set check's state to aButton's value
            (its addSubview:check)
        end repeat
        panel's setAccessoryView:it
    end tell
end makeAccessory

to makeCheckbox(title, frame) -- make a checkbox button
    if newer then -- available 10.12+
        set button to current application's NSButton's checkboxWithTitle:title target:me action:"doCheckBox:"
        button's setFrame:frame
    else -- old style
        set button to current application's NSButton's alloc's initWithFrame:frame
        button's setButtonType:(current application's NSSwitchButton)
        button's setTitle:title
        button's setTarget:me
        button's setAction:"doCheckBox:"
    end if
    return button
end makeCheckbox

on doCheckbox:sender -- handle checkbox changes in the accessoryView
    tell sender's |window|() -- 'window' is a reserved AppleScript term
        repeat with aButton in buttonList
            if aButton's title is (sender's title as text) then
                (its setValue:(sender's intValue as boolean) forKey:(aButton's selector))
            end if
        end repeat
        display() -- update
    end tell
end doCheckbox:

on quit
    set setup to missing value -- reset for next time
    continue quit
end quit

