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
	global errorText
	set errorText to ""
	
	-- Localize parameters
	--set filePath to (item 1 of argv)
	set filePath to (path to "temp" from user domain as text) & "tempSnippet.xml"
	
	-- Get snippet from pasteboard
	tell application "FileMaker Pro Advanced"
		set snippetRecord to my getSnippet()
		if snippetRecord begins with "Unrecognized" then set errorText to snippetRecord
	end tell
	if errorText is not "" then return errorText
	
	-- Convert snippet to text
	set fileAlias to my saveText(snippetRecord, filePath)
	set theFile to open for access fileAlias
	set snippetText to read theFile as «class utf8»
	close access theFile
	if errorText is not "" then return errorText
	
	-- Convert CR to LF (recommended line ending in TextMate)
	set snippetText to searchReplaceText(snippetText, {character id 13}, {character id 10})
	
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

-- Handler: Retrieves FileMaker snippet from clipboard
--	You can often just print clipboardData as text, but this doesn't work for class XMLO
to getSnippet()
	try
		set clipboardData to the clipboard as record
	on error errMsg number errNum
		set errorText to "Invalid clipboard data" & return & errNum & ": " & errMsg
		return
	end try
	try
		set clipboardText to «class XMSC» of clipboardData
		return clipboardText
	end try
	try
		set clipboardText to «class XMSS» of clipboardData
		return clipboardText
	end try
	try
		set clipboardText to «class XMTB» of clipboardData
		return clipboardText
	end try
	try
		set clipboardText to «class XMFD» of clipboardData
		return clipboardText
	end try
	try
		set clipboardText to «class XMFN» of clipboardData
		return clipboardText
	end try
	try
		set clipboardText to «class XMLO» of clipboardData
		return clipboardText
	end try
	set errorText to "Unrecognized clipboard data"
end getSnippet