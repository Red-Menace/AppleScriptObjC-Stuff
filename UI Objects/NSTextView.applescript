
use AppleScript version "2.5" -- Sierra (10.12) or later for new enumerations
use framework "Foundation"
use scripting additions


(* NSTextView example:
property mainWindow : missing value -- globals can also be used
property textView : missing value
property scrollView: missing value

set loremText to "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque vestibulum venenatis velit, non commodo diam pretium sed. Etiam viverra erat a lacus molestie id euismod magna lacinia. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vestibulum ac augue magna, eu pharetra leo. Donec tortor tortor, tristique in ornare nec, feugiat vel justo. Nunc iaculis interdum pellentesque. Quisque vel rutrum nibh. Phasellus malesuada ipsum quis diam ullamcorper rutrum. Nullam tincidunt porta ante, in aliquet odio molestie eget. Donec mollis, nibh euismod pulvinar fermentum, magna nunc consectetur risus, id dictum odio leo non velit. Vestibulum vitae nunc pulvinar augue commodo sollicitudin."

set my textView to makeTextView at {20, 50} given dimensions:{350, 80}, textString:loremText -- given arguments are optional
set my scrollView to makeScrollView for textView with wrapping -- embed textView into scrollView

mainWindow's contentView's addSubview:scrollView
*)


# Make and return an NSTextView.
to makeTextView at origin given dimensions:dimensions : {200, 28}, textString:textString : "Testing", textFont:textFont : missing value, textColor:textColor : missing value, backgroundColor:backgroundColor : missing value, drawsBackground:drawsBackground : missing value, editable:editable : missing value, selectable:selectable : missing value
	tell (current application's NSTextView's alloc's initWithFrame:{origin, dimensions})
		its setAutoresizingMask:(current application's NSViewWidthSizable)
		its setHorizontallyResizable:true
		if textFont is not missing value then its setFont:textFont
		if textColor is not missing value then its setTextColor:textColor
		if backgroundColor is not missing value then its setBackgroundColor:backgroundColor
		if drawsBackground is not missing value then its setDrawsBackground:drawsBackground
		if editable is not missing value then its setEditable:editable
		if selectable is not missing value then its setSelectable:selectable
		its setString:textString
		return it
	end tell
end makeTextView

# Make and return an NSScrollView for the given textView.
to makeScrollView for textView given borderType:borderType : missing value, verticalScroller:verticalScroller : true, wrapping:wrapping : true
	if textView is missing value then return missing value
	tell (current application's NSScrollView's alloc's initWithFrame:(textView's frame))
		its setAutoresizingMask:(((current application's NSViewWidthSizable) as integer) + ((current application's NSViewHeightSizable) as integer))
		if borderType is not missing value then its setBorderType:borderType -- 0-3 or NSBorderType enum
		if verticalScroller is not in {false, missing value} then its setHasVerticalScroller:true
		its setDocumentView:textView
		my (setWrapMode for textView given wrapping:wrapping)
		return it
	end tell
end makeScrollView

# (re)set a wrapping mode for the given textView.
# The horizontal scroller is set as needed.
# Note that there needs to be a run loop to update the UI if dynamically changing the wrap mode.
to setWrapMode for textView given wrapping:wrapping : true
	if textView is missing value then return missing value
	if wrapping is true then -- wrap at textView width
		set theSize to (textView's enclosingScrollView's contentSize) as list -- NSSize coercion is a bit buggy
		set theWidth to width of first item of theSize
		# set theWidth to first item of second item of (textView's frame as list) -- alternate
		set layoutSize to current application's NSMakeSize(theWidth, 1.0E+4)
		textView's enclosingScrollView's setHasHorizontalScroller:false
		textView's textContainer's setWidthTracksTextView:true
	else -- no wrapping
		set layoutSize to current application's NSMakeSize(1.0E+4, 1.0E+4)
		textView's setMaxSize:layoutSize
		textView's enclosingScrollView's setHasHorizontalScroller:true
		textView's textContainer's setWidthTracksTextView:false
	end if
	textView's textContainer's setContainerSize:layoutSize
	textView's enclosingScrollView's setNeedsDisplay:true
	return wrapping
end setWrapMode

#
# NSBorderType:
# NSNoBorder = 0
# NSLineBorder = 1
# NSBezelBorder = 2
# NSGrooveBorder = 3
#

