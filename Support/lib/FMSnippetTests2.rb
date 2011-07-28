#!/usr/bin/ruby
#
# DESCRIPTION
#	Generates FileMaker snippet of field layout objects
#
# USAGE
#	col1 = fully qualified field name
#	col2 = tooltip (optional)
#	col3 = font (optional)
#	col4 = fontSize (optional)
#	col5 = objectName (optional)
#

require 'FMSnippet.rb'

# Open document
# text = STDIN.read
text = "Contact Management::Address_Type1\nContact Management::Address_Type2"
doc = FMSnippet.new("layout_object")

# Generate Fields
xml = ""
text.split(/\n/).each { |row|
	col = row.split(/\t/)
	arg = {
		:fieldQualified	=> col[0],
		:tooltip			=> col[1],
		:font			=> col[2],
		:fontSize			=> col[3],
		:objectName		=> col[4]
	}
	doc.layoutField(arg)
}

print doc