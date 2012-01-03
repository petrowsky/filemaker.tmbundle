#!/usr/bin/ruby

require 'fmsnippet.rb'
include FileMaker

text = '2+2 
// NAME: function ( number )'

# begin

	# Parse function attributes
	calc = text.parse_function("NAME:")

	# Create function snippet
	doc = FMSnippet.new(calc)
	print doc
	
	# Load to pasteboard
	doc.set_clipboard

	# Return feedback
  puts "Function ready to paste into FileMaker"

# rescue
  # puts "Unrecognized function format"
#   
# end