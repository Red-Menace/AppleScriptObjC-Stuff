
(*
   Auto Code Wrapper (combined) - wraps a Script Editor / Script Debugger selection or clipboard text with a code insertion script
   last reviewed April 23, 2026
      Input:   source text read from the targeted editor selection or the clipboard
      Output:  script text pasted into a new targeted editor document or saved to a file

   This script and its generated wrapper scripts are designed to be run from the Script Menu as an alternative to using a code snippet manager.  The Script Menu has its own application and uses `osascript` to run scripts separate from the editors, which allows the current editor document to be edited.  This also avoids issues such as a wrapper script targeting the wrong editor or the editor not running. Compiled wrapper scripts can be added to the Script Menu by placing them in your user's ~/Library/Scripts/Applications/Script Editor (or Script Debugger) folder, where they will be listed in the menu when that editor is active.

   NOTE: 
   The script is distributed as text so that it can be saved as a compiled .scpt after making any desired changes to the script settings (`targetEditor`, `savePath`, etc) and default options (`authorInfo`, `autoSave`, n`amePrefix`, etc).  Script Editor and Script Debugger use slightly different terminology, so it is important to set the `targetEditor` property for the desired script editor.  The script uses `run script` and `osacompile` in order to avoid a choose dialog and/or error if Script Debugger is not installed - generated wrapper scripts will only target the specified editor.

   When running this script in the editor (testing, etc), the target editor is temporarily set to the current application and the save destination is set to the Desktop folder.  The ~/Library/Scripts folder for the current application is also created if it does not already exist.  Any generated wrapper scripts will still need to be used from an AppleScript instance separate from the editor, e.g. Script Menu, `osascript`, etc.

   When running this script from the Script Menu, it gets a code snippet/handler from the current editor selection or the clipboard (the `selectionFirst` property determines which is looked for first) and wraps it with an insertion script.  A handler wrapper is determined at script creation if, after skipping leading comment/empty lines and whitespace, the input text begins with "on " or "to " and the `includeHandlerCall` property is true, otherwise a code snippet wrapper is used.
   The script doesn't check that the inserted text will compile in the targeted script or if it contains things such as multiple handlers, so that incomplete snippets or a group of handlers such as a main/helper or utility handlers can be inserted and edited as appropriate.  The option to compile after code insertion can be set as desired for each wrapper script.
   Wrapper code is minimal, adding 24 lines for a handler and 13 for a snippet (including comments and blank lines).

   When a wrapper script is run from the Script Menu, it will insert its handler/snippet code into the editor's front document at the current insertion point or selection.  If the `includeHandlerCall` property is false, a handler wrapper operates as a general-purpose code snippet wrapper (except for the auto-save name - see below), otherwise a handler wrapper will perform as follows:
         • Comments and extra whitespace are removed from the handler call statement, and a newline will be added to the end of the handler code if doesn't already end with one.
         • The handler code will be inserted if there are two or more preceding blank lines (at least 3 newline characters), otherwise a handler call statement is inserted as a template for any arguments.  The handler call statement normally uses the first line/paragraph of the handler definition (minus the `on/to`), but line continuations are also supported.  Note that the handler call statement contains the entire handler name declaration and may not compile until arguments have been edited (e.g. labeled parameters with defaults).

   The default name of a generated script will begin with the `namePrefix` property followed by the first word of the handler name (piped or underscored identifiers are treated as one word) or a random(ish) snippet name in the form of `snippet-41B78F6578E2`.  If not auto-saving, a new editor document will be opened in Script Debugger and given the name, but new documents in Script Editor will not be renamed since a backing file is required.  The default `savePath` is the appropriate ~/Library/Scripts/Applications/ folder and can be POSIX, the Desktop will be used if it is not set ("" or missing value).  The new document will be compiled according to the `compileNewDocuments` property setting.

   Other than AppleScript's historical practice of saving properties and globals in the script file, regular scripts don't really have a preferences system.  This script prevents properties from being modified by copying their values into global values - there is an initial alert dialog to let you adjust a few of these values such as the auto-save and selection options so that you don't have to recompile the defaults in the script if you want to occasionally do something slightly different.  The default options are those that have been set in the script properties - any adjustments from the alert will only be applied to the current run and are not kept.
*)


use AppleScript version "2.7" -- High Sierra (10.13) and later
use framework "Foundation" -- Cocoa framework(s) for AppleScriptObjC
use scripting additions


property |+| : current application -- just a shortcut

# script settings
property targetEditor : "Script Editor" -- or -- "Script Debugger"
property savePath : ((path to scripts folder) as text) & "Applications:" & targetEditor & ":" -- default save location
property includeHandlerCall : true -- include handler wrapper code to insert a handler call?
property compileNewDocuments : true -- compile new wrapper documents when opening in the editor?

# default user options
property selectionFirst : true -- check for an editor selection before the clipboard?
property compileAfterInsert : true -- compile the target script after pasting the script text?
property autoSave : true -- automatically save the wrapped handler/snippet?
property namePrefix : text 1 of targetEditor & text 8 of targetEditor & " - " -- autoSave name prefix (editor indication, etc)
property authorInfo : "" -- author info for wrapper script (website, email, etc)


global selectionOption, compileOption, saveOption, prefixOption, authorOption -- working user options
global editor, destination -- working targetEditor and savePath copies
global usingEditor -- flag to indicate running in an editor
global newline -- editor newline character to use
global wrapperComment -- comment (description, etc) added to the wrapped script
global failure -- error record {errorMessage, errorNumber} -- `performSelectorOnMainThread` doesn't return anything


on run
	initialize()
end run

on initialize() -- reset globals and get options
	set {selectionOption, compileOption, saveOption, prefixOption, authorOption, editor} ¬
		to {selectionFirst, compileAfterInsert, autoSave, namePrefix, authorInfo, targetEditor}
	set destination to item (((savePath is in {"", missing value}) as integer) + 1) of {savePath, (path to desktop) as text}
	set usingEditor to (name of |+|) is in {"Script Editor", "Script Debugger"}
	if usingEditor then -- make a few adjustments to use the editor for testing
		do shell script "mkdir -p " & quoted form of POSIX path of (((path to scripts folder) as text) & "Applications:" & editor & ":") -- make the ~/Library/Scripts folder
		set destination to (path to desktop) as text
		tell (get name of |+|)
			set editor to it
			set customPrefix to (namePrefix is not (text 1 & text 8 & " - "))
			set prefixOption to item ((customPrefix as integer) + 1) of {namePrefix, text 1 & text 8 & " - "} -- new default or custom
		end tell
	end if
	set newline to item (((editor is "Script Debugger") as integer) + 1) of {return, linefeed}
	set failure to {}
	my performSelectorOnMainThread:"showAlert:" withObject:(missing value) waitUntilDone:true -- get options
	if failure is {} then
		set wrapperComment to item (((wrapperComment is not "") as integer) + 1) of {"", "-  " & wrapperComment}
		doStuff()
	else -- alert sets failure record
		log failure
		if failure's errorNumber is not in {-128, 2700} then my performSelectorOnMainThread:"showAlert:" withObject:{messageText:"AutoCodeWrapper Options Error", infoText:(failure's errorMessage & "  (" & failure's errorNumber & ")")} waitUntilDone:true -- don't show for cancel and reveal options
	end if
end initialize

on doStuff() -- get the source text and wrap it
	set openDocuments to (run script "tell application \"" & editor & "\" to return (get documents)")
	set sourceText to ""
	if selectionOption and (openDocuments is not {}) then -- selection first
		set sourceText to (run script "tell application \"" & editor & "\" to tell document 1 to return contents of selection")
		if sourceText is "" then
			if ((clipboard info) as text) contains "«class utf8»" then set sourceText to (the clipboard) as text
		end if
	else -- clipboard first
		if ((clipboard info) as text) contains "«class utf8»" then set sourceText to (the clipboard) as text
		if sourceText is "" and (openDocuments is not {}) then
			set sourceText to (run script "tell application \"" & editor & "\" to tell document 1 to return contents of selection")
		end if
	end if
	if (trimWhitespace from sourceText) is "" then
		my performSelectorOnMainThread:"showAlert:" withObject:{messageText:"AutoCodeWrapper Input Error", infoText:"There is no script editor selection or document and the clipboard does not contain text.  Please copy or select script text to wrap."} waitUntilDone:true
		return
	end if
	makeWrapper(sourceText)
end doStuff


##############################
-->> Wrapper Handlers
##############################

to makeWrapper(scriptText) -- make an insertion wrapper for the chosen script text
	try
		set {defaultName, escapedText} to {"", escapeString(scriptText)}
		set handlerCall to checkForHandler(scriptText)
		if handlerCall is not "# code wrapper #" then
			set defaultName to (first word of handlerCall)
			if defaultName is "|" then -- look for closing pipe
				set defaultName to text 1 thru ((offset of "|" in (text 2 thru -1 of handlerCall)) + 1) of handlerCall
			end if
			set typical to ((count defaultName) is (count handlerCall)) or (text ((count defaultName) + 1) of handlerCall is in {"(", ":"}) -- typical handler declaration
			set handlerCall to "my " & item ((typical as integer) + 1) of {"(" & handlerCall & ")", handlerCall} -- group the handler declaration if it uses labels or terminology
		end if
		tell (current date) to set dateInfo to "last reviewed " & (its month) & " " & (its day) & ", " & (its year)
		if includeHandlerCall and (defaultName is not "") then
			set theCode to wrapHandler(escapedText, defaultName, handlerCall, dateInfo)
		else
			if defaultName is "" then set defaultName to "snippet" & text -13 thru -1 of (do shell script "uuidgen") -- last part of UUID
			set theCode to wrapCode(escapedText, defaultName, dateInfo)
		end if
	on error errorMessage number errorNumber
		my performSelectorOnMainThread:"showAlert:" withObject:{messageText:"AutoCodeWrapper Wrap Error", infoText:errorMessage & "  (" & errorNumber & ")"} waitUntilDone:true
		return
	end try
	outputWrapper(theCode, prefixOption & defaultName & ".scpt")
end makeWrapper

# Return a handler call statement if a handler declaration is found, otherwise indicate a generic code wrapper.
# A handler call statement does not include any comments added to the handler name - multi-line names are supported.
to checkForHandler(scriptText)
	repeat with handlerCall in (paragraphs of scriptText) -- find first line that is not a comment or whitespace/empty
		set handlerCall to contents of handlerCall
		set prospect to (trimWhitespace from handlerCall)
		if (prospect is not "") and (prospect does not start with "#") and (prospect does not start with "--") and prospect does not start with "(*" and prospect does not start with "*)" then
			set wordOffset to ((offset of (first word of handlerCall) in handlerCall) - 1) -- offset of `on/to`
			ignoring white space -- determine if the line is the start of a handler declaration
				if not ((first word of handlerCall is in {"on", "to"}) and ((wordOffset is 0) or ((text 1 thru wordOffset of handlerCall) is ""))) then return "# code wrapper #" -- leading whitespace is allowed in a handler declaration
			end ignoring
			set handlerCall to text (offset of handlerCall in scriptText) thru -1 of scriptText
			exit repeat
		end if
	end repeat
	if handlerCall is "" or (count (words of handlerCall)) < 2 then return "# code wrapper #"
	repeat with theIndex from 1 to (count paragraphs of handlerCall) -- find first line without a line continuation
		if contents of (paragraph theIndex of handlerCall) does not end with "¬" then exit repeat
	end repeat
	set handlerCall to (paragraphs 1 thru theIndex of handlerCall) as text
	set {prevTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {"¬", tab}} -- continuation characters
	set {handlerCall, AppleScript's text item delimiters} to {text items of handlerCall, prevTID}
	set handlerCall to handlerCall as text
	set {prevTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {" #", " --"}} -- trailing comment
	set {handlerCall, AppleScript's text item delimiters} to {first item of (text items of handlerCall), prevTID}
	return (text (second word of handlerCall) thru -1 of handlerCall) -- skip `on/to`
end checkForHandler

to wrapHandler(scriptText, handlerName, handlerCall, dateInfo) -- assemble and return a handler code insertion script
	set addedLine to item (((last character of scriptText is not in {return, linefeed}) as integer) + 1) of {"", newline}
	set {sourceTerm, lineOffset} to item (((editor is "Script Debugger") as integer) + 1) of {{"text", " + 1"}, {"source text", ""}}
	set theCode to "
# `" & handlerName & "` handler wrapper  " & wrapperComment & "
# " & dateInfo & "  " & authorOption & "

set handlerCall to \"" & escapeString(trimWhitespace from handlerCall) & "\"

set handlerCode to \"" & scriptText & addedLine & "\"

# A script for inserting the above handler declaration or call statement at the current selection or insertion point:
tell application \"" & editor & "\" to tell document 1
   set insertionPoint to (first item of (get character range of the selection))" & lineOffset & "
   if insertionPoint ≤ 3 then -- beginning of file
      set contents of selection to handlerCall
   else
      set blankLines to true -- insert handler code if there are two or more preceding blank lines (at least 3 newline characters)
      repeat with aCharacter in (characters of (text (insertionPoint - 3) thru (insertionPoint - 1) of (get its " & sourceTerm & ")))
         if aCharacter is not in {return, linefeed} then set blankLines to false
      end repeat
      set contents of selection to item ((blankLines as integer) + 1) of {handlerCall, handlerCode}
   end if" & newline & tab & item ((compileOption as integer) + 1) of {"-- ", ""} & "compile
end tell
"
	return theCode
end wrapHandler

to wrapCode(scriptText, snippetName, dateInfo) -- assemble and return a snippet code insertion script
	set theCode to "
# `" & snippetName & "` code wrapper  " & wrapperComment & "
# " & dateInfo & "   " & authorOption & "

set theCode to \"" & scriptText & "\"

# A script for inserting the above generic code at the current selection or insertion point:
tell application \"" & editor & "\" to tell document 1
   set contents of selection to theCode" & newline & tab & item ((compileOption as integer) + 1) of {"-- ", ""} & "compile
end tell
"
	return theCode
end wrapCode

to outputWrapper(theCode, documentName) -- save the wrapper script or open it in a new document
	try
		if saveOption then -- save without opening new document
			(do shell script "osacompile -e " & quoted form of theCode & " -o " & quoted form of POSIX path of (destination & documentName)) -- escape the escaped code for the shell
		else -- make a new document for review and/or to save with a different path/name
			set theCode to escapeString(theCode) -- escape the escaped code for a string
			tell application editor to activate
			if editor is "Script Debugger" then -- document is given the default name
				try -- workaround for early return bug
					run script "tell application \"Script Debugger\" to (make new document with properties {source text:\"" & theCode & "\", name:\"" & documentName & "\"})"
				on error number -1712 -- only trapping this one, any others are captured later
					log "Error -1712: 'AppleEvent timed out.' - new document has been created, error ignored…"
				end try
			else -- Script Editor document is not renamed - a backing file is required, might as well just let the user do it
				run script "tell application \"Script Editor\" to (make new document with properties {text:\"" & theCode & "\"})"
			end if
			if compileNewDocuments then tell application editor to compile document 1
		end if
	on error errorMessage number errorNumber
		my performSelectorOnMainThread:"showAlert:" withObject:{messageText:"AutoCodeWrapper Output Error", infoText:errorMessage & "  (" & errorNumber & ")"} waitUntilDone:true
	end try
end outputWrapper


##############################
-->> Utility Handlers
##############################

to escapeString(theString as text) -- escape characters for an AppleScript string
	set {escapeCharacter, charactersToEscape} to {"\\", {"\\", quote}}
	repeat with aCharacter in charactersToEscape
		if contents of aCharacter is in theString then
			set {prevTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, aCharacter}
			set {itemList, AppleScript's text item delimiters} to {text items of theString, escapeCharacter & aCharacter}
			set {theString, AppleScript's text item delimiters} to {itemList as text, prevTID}
		end if
	end repeat
	return theString
end escapeString

# Trim whitespace from a string with/without leading and/or trailing - given arguments are optional
to trimWhitespace from (theString as text) given leading:(leading as boolean) : true, trailing:(trailing as boolean) : true
	set whiteSpace to {space, tab, return, linefeed} -- most others (NBSP, etc) are not accepted or trimmed from compiled text
	if theString is "" then return ""
	if leading then repeat while the first character of theString is in whiteSpace
		if (count theString) is 1 then return ""
		set theString to text 2 thru -1 of theString
	end repeat
	if trailing then repeat while the last character of theString is in whiteSpace
		if (count theString) is 1 then return ""
		set theString to text 1 thru -2 of theString
	end repeat
	return theString
end trimWhitespace


##############################
-->> NSAlert Handlers
##############################

to showAlert:arguments -- common alert activation and error/options dispatch
	if not usingEditor then |+|'s NSApplication's sharedApplication()'s setActivationPolicy:(|+|'s NSApplicationActivationPolicyAccessory) -- don't change the policy of the editor
	activate me
	if arguments is missing value then
		getOptions()
	else -- error alert
		tell |+|'s NSAlert's alloc()'s init()
			its setMessageText:(messageText of arguments)
			its setInformativeText:(infoText of arguments)
			its setIcon:(|+|'s NSImage's alloc()'s initByReferencingFile:("/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"))
			its runModal()
		end tell
	end if
end showAlert:

to getOptions() -- get a few option choices for the current run
	tell |+|'s NSAlert's alloc()'s init() to try
		set accessory to my makeAccessory()
		its addButtonWithTitle:"Use Defaults" -- continue with default settings (buttons start at 1000)
		its addButtonWithTitle:"Apply Changes" -- temporarily apply new settings for this run
		its addButtonWithTitle:"Cancel"
		its addButtonWithTitle:"Reveal Scripts Folder"
		its setMessageText:(editor & " AutoCodeWrapper Options:")
		its setIcon:(|+|'s NSImage's alloc()'s initByReferencingFile:("/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/General.icns"))
		its setAccessoryView:accessory
		tell (its runModal as integer)
			if it is 1001 then my applyAccessoryValues(accessory)
			if it is 1002 then error "User cancelled." number -128
			if it is 1003 then
				tell application "Finder" to reveal (((path to scripts folder) as text) & "Applications:" & editor & ":")
				error "Not continuing from `Reveal` option." number 2700
			end if
		end tell
	on error errorMessage number errorNumber
		set failure to {errorMessage:errorMessage, errorNumber:errorNumber}
	end try
end getOptions

to makeAccessory() -- UI items for the initial options dialog
	tell application "System Events" to set saveName to (get name of disk item destination)
	set dark to (|+|'s NSApplication's sharedApplication's effectiveAppearance's |name|) is (|+|'s NSAppearanceNameDarkAqua)
	set boxColor to item ((dark as integer) + 1) of {|+|'s NSColor's quaternaryLabelColor, |+|'s NSColor's tertiaryLabelColor}
	tell (|+|'s NSBox's alloc()'s initWithFrame:{{0, 0}, {410, 177}})
		its setBoxType:(|+|'s NSBoxCustom)
		its setTitlePosition:(|+|'s NSNoTitle)
		its setCornerRadius:20.0
		its setFillColor:boxColor
		its setBorderColor:boxColor
		its addSubview:(my (makeCheckbox at {12, 140} given title:"Check for a selection before using clipboard contents", tag:111, state:selectionOption))
		its addSubview:(my (makeCheckbox at {12, 120} given title:"Compile the target document after inserting text", tag:222, state:compileOption))
		set checkbox to (my (makeCheckbox at {12, 100} given title:"Auto save the wrapper script to \"" & saveName & "\"", tag:333, state:saveOption))
		checkbox's setToolTip:(POSIX path of destination)
		its addSubview:checkbox
		its addSubview:(my (makeTextField at {9, 66} with label given stringValue:"Save prefix:", tooltip:"Auto save name prefix"))
		its addSubview:(my (makeTextField at {89, 70} given stringValue:prefixOption, tag:444, tooltip:"Auto save name prefix"))
		its addSubview:(my (makeTextField at {9, 36} with label given stringValue:"Author info:", tooltip:"Wrapper author info"))
		its addSubview:(my (makeTextField at {89, 40} given stringValue:authorOption, tag:555, tooltip:"Wrapper author info"))
		its addSubview:(my (makeTextField at {9, 6} with label given stringValue:"Comment:", tooltip:"Wrapper comment"))
		its addSubview:(my (makeTextField at {89, 10} given tag:666, tooltip:"Wrapper comment"))
		return it
	end tell
end makeAccessory

to applyAccessoryValues(accessoryView) -- update option globals from alert values
	tell accessoryView's contentView
		set selectionOption to (its viewWithTag:111)'s state as boolean
		set compileOption to (its viewWithTag:222)'s state as boolean
		set saveOption to (its viewWithTag:333)'s state as boolean
		set prefixOption to (its viewWithTag:444)'s stringValue as text
		set authorOption to (its viewWithTag:555)'s stringValue as text
		set wrapperComment to (its viewWithTag:666)'s stringValue as text
	end tell
end applyAccessoryValues

to makeCheckbox at (origin as list) given title:(title as text), tag:(tag as integer) : 0, state:(state as boolean) : false
	set {target, action} to item (((tag is 333) as integer) + 1) of {{missing value, null}, {me, "checkboxAction:"}}
	tell (|+|'s NSButton's checkboxWithTitle:title target:target action:action)
		its setFrameOrigin:origin
		its setTag:tag
		its setState:state
		return it
	end tell
end makeCheckbox

on checkboxAction:sender -- enable the prefix textField with the checkbox
	set parentView to sender's superview -- accessoryView box
	(parentView's viewWithTag:444)'s setEnabled:(sender's state)
end checkboxAction:

to makeTextField at (origin as list) given label:(label as boolean) : false, stringValue:(stringValue as text) : "", tag:(tag as integer) : 0, tooltip:(tooltip as text) : ""
	if label then tell (|+|'s NSTextField's labelWithString:stringValue)
		its setFrame:{origin, {85, 24}}
		its setToolTip:tooltip
		return it
	end tell
	tell (|+|'s NSTextField's textFieldWithString:stringValue)
		its setFrame:{origin, {298, 24}}
		its setTag:tag
		its setToolTip:tooltip
		return it
	end tell
end makeTextField

