#!/usr/bin/env ruby -KU

require 'fmsnippet.rb'
include FileMaker

#!/usr/bin/ruby
#
# DESCRIPTION
#	Generates FileMaker snippet of Fields
#
# USAGE
#	Instructions printed when input is empty.
#	See documentation section below.
#
# FIXME Clipboard doesn't have correct text
#

# require ENV['TM_BUNDLE_SUPPORT'] + ENV['TM_PATH_SNIPPET']
include FileMaker
# $LOAD_PATH << "#{ENV['TM_SUPPORT_PATH']}/lib"
# require 'exit_codes.rb'

text = 'CONTACT::NameFirst'

# Documentation
if text.empty?
	tips = ENV['TM_DOC_TIPS']
	puts <<EOF
DESCRIPTION:
	Generates FileMaker snippet of Fields (to be pasted into any table).
	Uses selected text or entire document.

EXAMPLE USAGE:
	Select the lines below and run the command again to see it work.

CONTACT::NameFirst
CONTACT::Global\tNumber\tTrue\tComment for field\t10
CONTACT::Name_FL\tText\tFalse\tE.g., John Smith\t1\tCONTACT::NameFirst & CONTACT::NameLast
CONTACT::Name_FL\tText\t\t\t\tCONTACT::NameFirst & CONTACT::NameLast

PARAMETERS:
	col1 = field name (Fully qualified)
	col2 = field type (optional. Default = Text)
	col3 = is global? (optional. True = Global field. Default = False)
	col4 = comment (optional)
	col5 = max repetitions (optional)
	col6 = calculation (optional)

TIPS:
#{tips}
EOF
	TextMate.exit_replace_text
end

# Generate Fields
doc = FMSnippet.new
text.split(/\n/).each do |row|
	col = row.split(/\t/)
	name = col[0]
	isGlobal = col[2] || false
	arg = {
		:type		=> col[1],
		:isGlobal		=> isGlobal,
		:comment		=> col[3],
		:repetitions	=> col[4],
		:calculation	=> col[5]
	}
	doc.field(name,arg)
end

text.paste if Boolean(ENV['TM_AUTO_PASTE'])

sleep 1

#doc.set_clipboard