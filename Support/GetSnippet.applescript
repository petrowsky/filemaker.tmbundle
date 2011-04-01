(*
NAME:
	GetSnippet (v1.0)
	
PURPOSE:
	Returns fmxmlsnippet from pasteboard as xml text
	
PARAMETERS:
	

HISTORY:
	Created 2011.03.23 by Donovan Chandler, donovan_c@beezwax.net

NOTES:
	Line endings are converted to line feed (LF)
*)
------------------------------------------------

on run argv
	-- Localize parameters
	--set filePath to (item 1 of argv)
	set filePath to (path to "temp" from user domain as text) & "tempSnippet.xml"
	
	-- Get snippet from pasteboard
	tell application "FileMaker Pro Advanced"
		set snippetRecord to my getSnippet()
	end tell
	
	-- Convert snippet to text
	set fileAlias to my saveText(snippetRecord, filePath)
	set theFile to open for access fileAlias
	set snippetText to read theFile as «class utf8»
	close access theFile
	
	-- Convert CR to LF (recommended line ending in TextMate)
	set snippetText to searchReplaceText(snippetText, {ascii character 13},{ascii character 10})
	
	-- Strip invalid characters left over from record
	--	You can also do this by retrieving the clipboard contents as 
	--	«class XMFN», etc. But this is more flexible.
	set charStart to offset of "<" in snippetText
	set snippetText to text charStart thru (length of snippetText) of snippetText
	return snippetText
end run

------------------------------------------------
--  HANDLERS
------------------------------------------------

-- Handler: Saves FileMaker object on clipboard to XML file
on getSnippet()
	--tell application "FileMaker Pro Advanced"
	try
		set clipboardData to the clipboard as record
		-- Alternative method: set clipboardText to «class XMSC» of clipboardData
		set clipboardText to clipboardData
		return clipboardText
	on error errMsg number errNum
		return "Invalid clipboard data" & return & errNum & ": " & errMsg
	end try
	--end tell
end getSnippet

-- Handler: Saves text to file
on saveText(theText, filePath)
	if filePath = "" then
		set filePath to choose file name with prompt "Choose file to write to"
	end if
	try
		set fileRef to open for access filePath with write permission
		set eof of fileRef to 0
		write theText to fileRef starting at eof
		close access fileRef
	on error
		try
			close access fileRef
		end try
	end try
	return filePath as alias
end saveText

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