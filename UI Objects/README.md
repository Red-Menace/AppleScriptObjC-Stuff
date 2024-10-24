# UI Objects

A collection of handlers for creating various UI objects in a Cocoa-AppleScript script.  Handlers are general-purpose and medium duty, and although often used features and options (plus a little guarding) are included, they can be added or removed as desired, and  Xcode is not needed.

Handlers are self-contained and can be mixed and matched as desired, for example an `NSBox` can be populated with some checkboxes and used as an accessory view in a panel or alert, or a menu can be created for a floating window.

Note that many controls need to be be used with a run loop (such as in a stay-open application) or modal dialog (also from a `performSelectorOnMainThread:withObject:waitUntilDone:true`) in order to see any UI changes.  For example, while a control may remain when used in a Script Editor, the script will have finished executing so changes may not update the log or the UI. 

Most handlers use labels for given arguments so that they can be optional, and include a default value.  An AppleScript defined label is used for the first user parameter name so the others can be skipped as desired, for example:

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

* NSAlert †
  * Plain
  * Extended with text field font/color, giveup timer, and accessory view support
* NSBox
* NSButton
    * Push Buttons
    * CheckBox and Radio buttons (individual and grouped in a box)
* NSComboBox
* NSComboButton
* NSDatePicker
* NSImageView
* NSMenu (including submenus)
* NSOpenPanel-NSSavePanel †
* NSPathControl
* NSPopover
* NSPopUpButton
* NSProgressIndicator †
    * Simple bar/spinner indicator
    * Controller script/class (combined indicator with text fields and cancel button)
* NSSegmentControl
* NSSlider-NSLevelIndicator
* NSStatusItem †
* NSSwitch
* NSTextField (includes NSSecureTextField)
* NSTextView (includes NSScrollView and wrapping)
* NSWindow-NSPanel †


† These scripts include a run handler so that they can also be used for testing and laying out UI items.

