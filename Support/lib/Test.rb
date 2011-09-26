#!/usr/bin/env ruby
#
# Test file
#

require 'tm_dialog'

dialog = TM_Dialog.new

strPrepend = dialog.input('Enter the string to prepend.',
  'TABLE::'
)
colNum = dialog.input('Enter the column to prepend to.',
  1
).to_i
colNum = colNum - 1

puts colNum