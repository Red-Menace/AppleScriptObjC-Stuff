# UI Objects

A collection of handlers for creating various UI objects in a Cocoa-AppleScript script.  Handlers are general-purpose and medium duty (often used features and options, with some guarding). Xcode is not needed.

Handlers can be mixed and matched as desired, for example an `NSBox` can be populated with some checkboxes and used as an accessory view in a panel or alert, or a menu can be created for a floating window.

Note that controls need to be be used in a modal dialog or stay-open application (also from a `performSelectorOnMainThread:withObject:waitUntilDone:true`) in order to see any changes (accessory view, etc).  Even though the control may remain when used in a Script Editor, the script will finish executing and won't see any changes. 

The handlers use labels for given arguments so that they can be optional, and include a default value.  An AppleScript defined label is used for the first user parameter name so the others can be skipped as desired, for example:

```
   to makeWhatever at origin given foo:foo : "foo", bar:bar : "bar", baz:baz : "baz"
      log origin
      log foo
      log bar
      log baz
   end makeWhatever

   makeWhatever at {0, 0} given baz:"What the heck is a baz, anyway?"
   makeWhatever at {0, 0}
```

Note that when calling a handler, any boolean handler arguments will be rearranged by the script editors when compiled, and are formatted using `with` or `without` before the given arguments, for example:

```
   makeWhatever at {0, 0} given foo:"test", bar:true
      -- becomes --
   makeWhatever at {0, 0} with bar given foo:"test"  
```

----
Handlers include the following objects/classes:

* NSAlert
  * Simple
  * Extended with text field font/color, giveup timer, and accessory view support
* NSBox
* NSButton
    * Push Buttons
    * CheckBox and Radio buttons (individual and grouped in a box)
* NSComboBox
* NSImageView
* NSMenu (including submenus)
* NSOpenPanel-NSSavePanel
* NSPathControl
* NSPopover
* NSPopUpButton
* NSTextField (includes NSSecureTextField)
* NSWindow-NSPanel

The NSAlert, NSWindow, and Open/Save panel scripts include a run handler, so they can also be used for testing and laying out UI items.

