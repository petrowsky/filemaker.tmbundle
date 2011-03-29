# Introduction #

This is my ongoing enhancement of the FileMaker bundle posted by Matt Petrowsky.  His bundle was a simplification of the original bundle by Charles Ross.  This version mostly adds to the commands.

# Features #

- Tab triggers for FileMaker functions
- Commands
	- Manipulating/generating calculations
	- Manipulating/generating FileMaker clipboard XML
	- Extracting data from the DDR
	- Extracting data from import.log files
- Syntax highlighting
	- FileMaker
	- FileMaker Clipboard
	- FileMaker Log

## Tab Triggers ##

This feature was last modified by Matt Petrowsky.

Tab triggers exist for every native FileMaker function, each named after the function itself. Templates are included for function parameters to allow you to tab through them.  To discover or modify the abbreviated tab triggers, find the function in the FileMaker bundle menu (Bundles>FileMaker>[Function Category]>[Function Name]).

Keyword shorthand versions of words:

	record = rec
	number = num
	summary = sum
	timestamp = ts
	evaluate = eval
	object = ob
	value(s) = val

## Function Enclosing ##

## Documentation Lookup ##

This was created by Charles in the original bundle.  It has not yet been updated.

## Commands ##

Functions are organized according to the type of text being worked with.

Commands postfixed with "**" do not work.
Commands postfixed with "*" are incomplete but functional.

### Calculations ###

### Calculation Generation ###

Allows you to programmatically write code using simpler arrays, etc.  Here's an example you might use if you were using transactions and were writing values from global fields to local fields:

1. Create first column (target field names)
	* Type in names of fields
	* Extract list of field names (using other command)
1. Create second column (values)
	* Type in values
	* Generate field names from first column (using regular expression or shell script)
1. Run "Build Set Field Steps" command
1. Paste new script steps into FileMaker
	* See following section, Clipboard, for more details

### Clipboard ###

Handles XML text extracted from the FileMaker clipboard.  Here's a very simple example:

1. Copy script steps in FileMaker
1. Use fmClipboardBroker to save clipboard contents to text file
1. Manipulate text
	* Change variable names
	* Change table occurrence names
	* Change function name
	* Add function parameter
1. Save the text file
1. Return to fmClipboardBroker and load the new script steps onto your clipboard
1. Paste in your new script steps

#### Clipboard Manipulation Utilities ####

There are several utilities available to help you manipulate the clipboard:

* AppleScript (takes some knowhow)
* fmClipboardBroker (free!)
* bBox plug-in (free!)
* Clip Manager (excellent, full-featured utility)
* ScriptMaster Advanced (allows access to FileMaker clipboard)

### DDR ###

Helps you extract specific information from the DDR.

### Logs ###

Helps you extract specific information from FileMaker's import log files, which describe your paste and import actions.

# Preferences #

Preferences will favor conventions adopted by the FOCUS Framework at Beezwax.

# Syntax Highlighting #

Provided for the following formats:

* FileMaker
* FileMaker Clipboard
	* Basically XML, but it should provide highlighting for FileMaker syntax within that XML
* FileMaker Log
	* Very basic, but those logs can be very difficult to read without it!

# Usage Tips #

## To open calculations in TextMate faster ##

I find copy/paste sufficient, but you may have higher ambitions.  Here are some ideas:

* Use QuickKeys to quickly copy your dialog content to a temporary text file opened in TextMate
* Trigger a shell script or AppleScript using TextExpander
* TextMate provides some functionality for this use case, but I have not looked to see if FileMaker supports it

## Becoming a power user ##

### Read a tutorial ###

Here's a good place to start: [TextMate Tutorials and More](http://projects.serenity.de/textmate/tutorials/basics/) By Stanley Rost (maintainer of TO DO bundle)

### Learn which commands are available to you ###

Other bundles, or maybe even this one, may have many useful commands you have not noticed before.  You can easily find what's available to you by browsing the menu's.  Even easier, try selecting something and pressing ^ ⌘T to show the Budles > Select Bundle Item... menu option.

### Learn to manipulate text ###

Manipulating text can make your development much more efficient.  Sometimes the power trip can also provide a thrill in itself!  Learning to use tools like shell scripts — grep, sed, awk — will give you many returns.  You can run one-off scripts against your documents using the menu option Text > Filter Through Command.

## To create your own commands or customizations ##

Look in the help docs to get started.  To peruse the bundle contents, open the Bundle Editor by selecting Bundles > Bundle Editor > Show Bundle Editor.

TextMate supports multiple languages.  I've found that Ruby has some great resources for learning and is very easy to practice.  You can test it out using irb in the terminal or run your scripts from within TextMate.

# History #

Original bundle by Charles Ross, puvinyel@znp.pbz

Forked 3/12/11 by Donovan Chandler from Matt Petrowsky

# Contact #

Donovan Chandler

Beezwax Datatools, Inc.

donovan_c@beezwax.net