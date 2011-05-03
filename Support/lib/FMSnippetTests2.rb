#!/usr/bin/ruby
#
# DESCRIPTION
#	Generates FileMaker snippet of Sort script steps
#
# USAGE
#	col1 = test
#	col2 = sort field
#	col3 = sort direction
#	True \t TABLE::NAME \t ascending
#

require 'FMSnippet.rb'
# require ENV['TM_BUNDLE_SUPPORT'] + ENV['TM_PATH_SNIPPET']
#
# Open document
# text = STDIN.read
text = "True\tCONTACT::name\n\tCOMPANY::name"
doc = FMSnippet.new("")

# Insert Fields
xml = ""
rep = 0
text.split(/\n/).each { |row|
	col = row.split(/\t/)
	field = col[1]
	calc = col[0]
	if calc == ""
	  calc = "$_sort_field = GetFieldName ( #{field} )"
  end
	rep = rep + 1
  rep == 1 ? doc.stepIf(calc) : doc.stepElseIf(calc)
	arg = [{
		:field			=> field,
		:direction		=> col[2]
	}]
	doc.stepSort(arg,"True")
}
doc.stepEndIf
puts doc

# How to handle field name that's possibly split into two columns
# col = row.split(/\t/)
# if not col[0].include?("::")
#   col[0] = col[0] + '::' + col[1]
#   col.slice!(1)
# end