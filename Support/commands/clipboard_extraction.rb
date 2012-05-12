#!/usr/bin/env ruby -KU
# encoding: UTF-8
#
# clipboard_extraction.rb - Extracts data from FileMaker fmxmlsnippets
#
# Author::      Donovan Chandler (mailto:donovan_c@beezwax.net)
# Copyright::   Copyright (c) 2010-2012 Donovan Chandler
# License::     Distributed under GNU General Public License <http://www.gnu.org/licenses/>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

base_path = File.dirname(File.dirname(__FILE__))

$LOAD_PATH.unshift(File.expand_path(base_path) + '/resources')

require base_path + '/lib/commands.rb'
require base_path + '/lib/filemaker.rb'
# require './lib/commands.rb'
# require './lib/filemaker.rb'
include FileMaker

tips = %Q{
}

# Returns readable version of exception, providing additional info if debugging is on (FileMaker::DEBUG_ON = true)
# @param [Object] Exception object
# @return [String] Readable exception message
def return_error(exception)
  if FileMaker::DEBUG_ON
    exception.message + "\n\n" + exception.backtrace.join("\n")
  else
    exception.message
  end
end

desc "Given fmxmlsnippet of layout objects, extracts all CSS."
doc %Q{
## Extract Layout Object CSS

### Description
Given an fmxmlsnippet of layout objects, extracts CSS styling for those objects.
Separates each object with string delimiter:
`-------------`
}
command :extract_css do |text|
  begin
    delim = "\n-------------\n"
    doc = Snippet.new(text)
    doc.extract_object_css.join(delim)
  rescue => e
    puts return_error(e)
  end
end