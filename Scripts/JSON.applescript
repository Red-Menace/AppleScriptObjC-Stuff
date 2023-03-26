
use framework "Foundation"
use scripting additions


on run -- example
	set theRecord to {testing:{one:"1", |2|:2, three:3.3, |list|:{missing value}}}
	set theList to {"List item", 4, 8.8, missing value, {"Another list"}, theRecord}
	
	set test to (generateJSON for theList)
	log result
	
	try
		set fileRef to (open for access ((path to desktop) as text) & "Sample.json" with write permission)
		set eof fileRef to 0
		write test to fileRef
		close access fileRef
	on error errmess
		try
			close access fileRef
		end try
		error errmess
	end try
	
	set JSONString to read (choose file of type "public.json")
	return (parseJSON from JSONString)
end run


# Parse JSON from a string into a data structure - without coercion, the result is left as a Cocoa object.
to parseJSON from sourceString given coercion:coerce : true
	if class of sourceString is not string then error "parseJSON error: source is not a string"
	set theString to current application's NSString's stringWithString:sourceString
	set theData to theString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
	set {object, anyError} to current application's NSJSONSerialization's JSONObjectWithData:theData options:0 |error|:(reference)
	if object is missing value then error "parseJSON error: " & (anyError's userInfo's objectForKey:"NSDebugDescription")
	if coerce then if (object's isKindOfClass:(current application's NSArray)) as boolean then
		return object as list
	else
		return object as record
	end if
	return object -- leave as NSArray or NSDictionary
end parseJSON


# Generate a JSON string for a list or record.
to generateJSON for someObject -- someObject needs to be a list, record, or objC equivalent
	set {theData, anyError} to current application's NSJSONSerialization's dataWithJSONObject:someObject options:(current application's NSJSONWritingPrettyPrinted) |error|:(reference)
	if theData is missing value then error "generateJSON error: " & (anyError's userInfo's objectForKey:"NSDebugDescription")
	set JSONString to current application's NSString's alloc()'s initWithData:theData encoding:(current application's NSUTF8StringEncoding)
	return JSONString as string
end generateJSON

