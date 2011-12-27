#!/usr/bin/ruby
#
# DESCRIPTION
# Loads custom function text onto pasteboard for pasting into FileMaker.
# Requires format specified in custom function template supplied with bundle.
#
# require '/Users/donovan/Library/Application Support/TextMate/Bundles/filemaker.tmbundle/Support/lib/FMSnippet.rb'
require 'FMSnippet.rb'
include FileMaker

# text = STDIN.read
text = '2+2 
// NAME: function ( number )'

# Documentation
if text.empty?
	puts <<EOF
DESCRIPTION
	Loads custom function text onto pasteboard for pasting into FileMaker.
	Requires format specified in custom function template supplied with bundle.

EXAMPLE USAGE:
	Create a new document from the FileMaker custom function template
		Select File > New From Template > FileMaker > Custom Function
	Fill in the blanks
	Then run this command again

TIPS:
	If you want to customize this command, you have to dig into the command definition in the bundle editor
EOF
	exit
end

# begin

	# Parse function attributes
	calc = text.functionAsSnippet("NAME:")
  # puts calc.to_s

	# Create function snippet
	doc = FMSnippet.new(calc)
	puts doc.inspect
	puts "------"
  puts doc.to_s
	exit
	
	# Load to pasteboard
	doc.setClipboard

	# Return feedback
	puts "Function ready to paste into FileMaker"

# rescue
  # puts "Unrecognized function format"
#   
# end