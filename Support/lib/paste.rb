#!/usr/bin/env ruby
#
# clipboard.rb - helps get and put FileMaker objects on the clipboard
# 
# Copyright (C) 2010-2011  Donovan Chandler
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

module FileMaker
  
  PATH_BASE = File.dirname(__FILE__)
  PATH_PASTE = "#{PATH_BASE}/PasteSnippet.applescript"
  PATH_ENCODE = "#{PATH_BASE}/encoding.sh"

  def self.encode_text(text)
    `"#{PATH_ENCODE}" "#{text}"`
  end
  
  def encode_text(text)
    self.encode_text(text)
  end

  def set_clipboard(text)
    shellScript = %Q[osascript "#{PATH_PASTE}" "#{encode_text(text)}"]
    system shellScript
  end
  
end