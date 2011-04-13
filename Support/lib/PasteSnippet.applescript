(*
NAME:
	PasteSnippet (v1.0)
	
PURPOSE:
	Loads fmxmlsnippet onto pasteboard in proper format for pasting into FileMaker.

PARAMETERS:
	1	Path to xml file being placed on pasteboard

HISTORY:
	Created 2011.03.23 by Donovan Chandler, donovan_c@beezwax.net

NOTES:
	This script is intended to be called using a command from the shell like this: osascript PasteSnippet.applescript "$XML_TEXT"
*)
------------------------------------------------

on run argv
	---- Parameters ----
	--set clipAlias to (item 1 of argv) as POSIX file
	set clipText to (item 1 of argv)
	if clipText equals "" then return "Error: Missing text"
	
	---- Settings ----
	-- Format of FileMaker object in clip [script|script_step|table|field|custom_function]
	set clipClass to determineClass(clipText)
	if clipClass begins with "Error" then return clipClass

	------------------------------------------------
	---- Convert clip to proper class ----
	set clipTextFormatted to convertClip(clipText, clipClass)

	---- Load to clipboard ----
	try
		set the clipboard to clipTextFormatted
		return "Snippet copied to clipboard"
	on error errMsg number errNum
		return "Error: " & errNum & ": " & errMsg
		--return "Error: Unrecognized format"
	end try
end run

------------------------------------------------
--  HANDLERS
------------------------------------------------

-- Handler: Converts xml text to FileMaker clipboard format
-- Parameters: clipText, outputClass [script|script_step|table|field|custom_function]
-- Methodology: Write text to temp file so that it can be converted from file
-- Formats:
--	XMSC for script definitions
--	XMSS for script steps
--	XMTB for table definitions
--	XMFD for field definitions
--	XMCF for custom functions
--	XMLO for layout objects
on convertClip(clipText, outputClass)
	set temp_path to (path to temporary items as Unicode text) & "FMClip.dat"
	set temp_ref to open for access file temp_path with write permission
	set eof temp_ref to 0
	write clipText to temp_ref
	close access temp_ref
	if outputClass is "XMSC" then
		set clipTextFormatted to read file temp_path as «class XMSC»
	else if outputClass is "XMSS" then
		set clipTextFormatted to read file temp_path as «class XMSS»
	else if outputClass is "XMTB" then
		set clipTextFormatted to read file temp_path as «class XMTB»
	else if outputClass is "XMFD" then
		set clipTextFormatted to read file temp_path as «class XMFD»
	else if outputClass is "XMFN" then
		set clipTextFormatted to read file temp_path as «class XMFN»
	else if outputClass is "XMLO" then
		set clipTextFormatted to read file temp_path as «class XMLO»
	else
		return "Error: Snippet class not recognized"
	end if
	return clipTextFormatted
end convertClip

-- Handler: Determines FileMaker pasteboard class of xml text
-- Formats:
--	XMSC for script definitions
--	XMSS for script steps
--	XMTB for table definitions
--	XMFD for field definitions
--	XMCF for custom functions
--	XMLO for layout objects
on determineClass(clipText)
	try
		set array to my split(clipText,"<")
		set child1 to item 3 of array
gdfdfd	on error errMsg number errNum
		--return "Error: " & errNum & ": " & errMsg
		return "Error: Unrecognized format"
	end try
	if child1 starts with "Script" then
		set theClass to "XMSC"
	else if child1 starts with "Step" then
		set theClass to "XMSS"
	else if child1 starts with "BaseTable" then
		set theClass to "XMTB"
	else if child1 starts with "Field" then
		set theClass to "XMFD"
	else if child1 starts with "CustomFunction" then
		set theClass to "XMFN"
	else if child1 starts with "Layout" then
		set theClass to "XMLO"
	else
		return "Error: Snippet format not recognized"
	end if
	return theClass
end determineClass

-- Handler: Splits string into array by delimiter
to split(someText, delimiter)
	set AppleScript's text item delimiters to delimiter
	set someText to someText's text items
	set AppleScript's text item delimiters to {""}
	return someText
end split

-- Handler: Searches and replaces string within text block
to searchReplaceText(theText, searchString, replaceString)
	set searchString to searchString as list
	set replaceString to replaceString as list
	set theText to theText as text
	
	set oldTID to AppleScript's text item delimiters
	repeat with i from 1 to count searchString
		set AppleScript's text item delimiters to searchString's item i
		set theText to theText's text items
		set AppleScript's text item delimiters to replaceString's item i
		set theText to theText as text
	end repeat
	set AppleScript's text item delimiters to oldTID
	
	return theText
end searchReplaceText

-- Handler: Returns text from file.  Prompts for file if no alias specified.
on readFile(fileAlias)
	if fileAlias = "" then
		set theFile to choose file with prompt (localized string "chooseFile")
	else
		set theFile to fileAlias
	end if
	try
		open for access theFile
		set fileText to (read theFile)
		close access theFile
		return fileText
	on error errMsg number errNum
		try
			close access theFile
		end try
		return "Error: " & errNum & ": " & errMsg
	end try
end readFile

--Handler: Returns patterncount
on patternCount(theText, matchString)
	set oldTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to {matchString}
	set countedPattern to count of text items of theText
	set AppleScript's text item delimiters to oldTID
	return countedPattern - 1
end PatternCount