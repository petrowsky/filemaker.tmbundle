# Introduction

This bundle provides tools for developing solutions in FileMaker Pro (a proprietary RDBMS). It provides basic features like syntax highlighting and tab triggers for calcuations. But it goes much deeper, allowing you to generate code and even interact directly with FileMaker objects on your clipboard.

# Features

* Tab triggers for FileMaker's functions
* Documentation for functions, script steps and error codes
* Commands
	* Manipulating/generating calculations
	* Manipulating/generating FileMaker clipboard XML
	* Extracting data from the DDR
	* Extracting data from import.log files
* Syntax highlighting
	* FileMaker
	* FileMaker Clipboard
	* FileMaker Log
	* FileMaker Hash (Generated using #( ) custom function)
* Code folding

## Tab Triggers

This feature was last modified by Matt Petrowsky.

Tab triggers exist for every native FileMaker function, each named after the function itself. Templates are included for function parameters to allow you to tab through them.  To discover or modify the abbreviated tab triggers, find the function in the FileMaker bundle menu (Bundles>FileMaker>[Function Category]>[Function Name]).

Keyword shorthand versions of words:

<table>
	<tr><th>Word</th><th>Shortcut</th></tr>
	<tr><td>record</td><td>rec</td></tr>
	<tr><td>number</td><td>num</td></tr>
	<tr><td>summary</td><td>sum</td></tr>
	<tr><td>timestamp</td><td>ts</td></tr>
	<tr><td>evaluate</td><td>eval</td></tr>
	<tr><td>object</td><td>ob</td></tr>
	<tr><td>value(s)</td><td>val</td></tr>
</table>

For example, typing "leftval" will expand to "LeftValues ( template1 ; template2 )"

## Function Enclosing

## Documentation Lookup

Place your cursor on a work and press ^H to search for related documentation. Documentation is provided for the following:

* Functions (native, fmsauc, SimpleDialog, SuperContainer)
* Script steps
* Error codes (including AppleScript errors)

A search window will appear if no entries are found.

## Commands

Functions are organized according to the type of text being worked with.

Commands postfixed with "**" do not work.
Commands postfixed with "*" are incomplete but functional.

### Calculations

### Calculation Generation

Allows you to programmatically write code using simpler arrays and lists.  Here's an example you might use if you were using transactions and were writing values from global fields to local fields:

1. Create first column (target field names)
	* Type in names of fields
	* Extract list of field names (using other command)
1. Create second column (values)
	* Type in values
	* Generate field names from first column (using regular expression or shell script)
1. Run "Build Set Field Steps" command
1. Paste new script steps into FileMaker
	* See following section, Clipboard, for more details

### Clipboard

Handles XML text extracted from the FileMaker clipboard.  There are two central commands for this functionality:

<table>
	<tr><th>Shortcut</th><th>Name</th><th>Action</th></tr>
	<tr><td>⌘+Opt+b</td><td>Get Snippet From Clipboard</td><td>Opens FileMaker clipboard contents as new XML document</td></tr>
	<tr><td>⌘+b</td><td>Load Snippet to Clipboard</td><td>Loads current XML document to FileMaker's clipboard as snippet</td></tr>
</table>

Note, you must have the current XML document assigned to the FileMaker Clipboard language in order to use these shortcuts.

Here's a very simple example of how a workflow might look:

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

#### Clipboard Manipulation Utilities

There are several utilities available to help you manipulate the clipboard:

* AppleScript (takes some knowhow)
* fmClipboardBroker (free!)
* bBox plug-in (free!)
* Clip Manager (excellent, full-featured utility)
* ScriptMaster Advanced (allows access to FileMaker clipboard)

### DDR

Helps you extract specific information from the DDR.

### Logs

Helps you extract specific information from FileMaker's import log files, which describe your paste and import actions.

# Preferences

Preferences will favor conventions adopted by the FOCUS Framework at Beezwax.

# Syntax Highlighting

Provided for the following formats:

* FileMaker
* FileMaker Clipboard
	* Basically XML, but it should provide highlighting for FileMaker syntax within that XML
* FileMaker Log
	* Very basic, but those logs can be very difficult to read without it!

# Usage Tips

## To open calculations in TextMate faster

I find copy/paste sufficient, but you may have higher ambitions.  Here are some ideas:

* Use QuickKeys to quickly copy your dialog content to a temporary text file opened in TextMate
* Trigger a shell script or AppleScript using TextExpander
* TextMate provides some functionality for this use case, but I have not looked to see if FileMaker supports it

## Becoming a power user

### Read a tutorial

Here's a good place to start: [TextMate Tutorials and More](http://projects.serenity.de/textmate/tutorials/basics/) By Stanley Rost (maintainer of TODO bundle)

### Learn which commands are available to you

Other bundles, or maybe even this one, may have many useful commands you have not noticed before.  You can easily find what's available to you by browsing the menu's.  Even easier, try selecting something and pressing ^ ⌘T to show the Budles > Select Bundle Item... menu option.

### Learn to manipulate text

Manipulating text can make your development much more efficient.  Sometimes the power trip can also provide a thrill in itself!  Learning to use tools like shell scripts — grep, sed, awk — will give you many returns.  You can run one-off scripts against your documents using the menu option Text > Filter Through Command.

## To create your own commands or customizations

Look in the help docs to get started.  To peruse the bundle contents, open the Bundle Editor by selecting Bundles > Bundle Editor > Show Bundle Editor.

TextMate supports multiple languages.  I've found that Ruby has some great resources for learning and is very easy to practice.  You can test it out using irb in the terminal or run your scripts from within TextMate.

# Known Bugs

* Function snippets are not loading to the clipboard

# How to Report Bugs or Request Features

Issues are being tracked on github [here](https://github.com/DonovanChan/filemaker.tmbundle/issues "github issues page")

# History

Original bundle by Charles Ross, puvinyel@znp.pbz  
Next incarnation by Matt Petrowsky (simplified version)  
Forked 3/12/11 from Matt by Donovan Chandler (added commands and additional languages)

Source available on [GitHub](https://github.com/DonovanChan/filemaker.tmbundle)

# Contact

Donovan Chandler  
Beezwax Datatools, Inc.  
donovan_c@beezwax.net
