# TextMate Bundle for FileMaker

## Introduction

Provides syntax highlighting, code snippets, quick documentation reference and robust code generating commands. You can even interact directly with FileMaker's clipboard from within this bundle.

This project was forked from a simpler version by Matt Petrowsky.  His bundle was a simplification of the original bundle by Charles Ross.  My version mostly adds to the commands.

For more information, please see the help file.  You can access that in the bundle menu or in the support folder.

## Features

* Tab triggers for FileMaker functions
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
* Code folding
* Help section

## Installation

### For easy installation

1. Download these files. (You should see a giant "Downloads" button on the top-right.)
1. Change the name of the downloaded folder to "FileMaker.tmbundle". (You will have to remove some metadata from the name.)
1. Double-click on the file.

That's it! TextMate will install the bundle  automatically into "~/Library/ApplicationSupport/TextMate/Bundles"

### For easy upgrades

You can set up the bundle as a git repository right where TextMate installs it. The easiest way to do this is probably to cd into the Bundles directory (see above) in Terminal, create a repo, and clone the files from here.  See http://help.github.com/ for info on getting started with github. Disclaimer: I'm not git master!

## History

Original bundle by Charles Ross, puvinyel@znp.pbz

Forked 3/12/11 by Donovan Chandler from Matt Petrowsky
