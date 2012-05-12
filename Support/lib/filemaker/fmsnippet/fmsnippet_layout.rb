#!/usr/bin/env ruby -KU
# encoding: UTF-8
#
# fmsnippet_layout.rb - helps manipulate and construct fmxmlsnippets for layouts
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

require 'erb'
require 'rexml/document'

class FileMaker::Snippet

  # Returns array of object names from fmxmlsnippet of layout objects
  def extract_object_names
    doc = REXML::Document.new(self.to_s)
    doc.elements.to_a("//Object").reduce([]){|memo,e| memo << e.attributes['name'] }
  end
  
  def extract_object_css
    doc = REXML::Document.new(self.to_s)
    doc.elements.to_a("//LocalCSS").reduce([]){|memo,e| memo << e.text.lstrip }
  end

  # Constructs layout field object and appends to @text
  # @param [Hash] options Hash containing field object attributes
  # @option options [String] :field Name of field
  # @option options [String] :table Name of table
  # @option options [String] :fieldQualified Fully qualified field name (e.g., CONTACT::NAME). Can be used in lieu of field and table options
  # @option options [String] :tooltip
  # @option options [String] :font
  # @option options [Integer] :fontSize
  # @option options [String] :objectName
  # @option options [Integer] :fieldHeight
  # @option options [Integer] :fieldWidth
  # @option options [Integer] :verticalSpacing
  # @return [String] XML element generated for object
  def layoutField(options={})
    @boundTop = 0 if @boundTop.nil?
    fieldQualified = options[:fieldQualified]
    if fieldQualified
      table = field_table(fieldQualified)
      field = field_name(fieldQualified)
    else
      table = options[:table]
      field = options[:field]
      fieldQualified = table + "::" + field
    end
    options = {
      :font         => "Verdana",
      :fontSize     => 12,
      :fieldWidth   => 120
    }.merge(options.delete_blank)
    options[:fieldHeight] ||= options[:fontSize] + 6
    fieldLeft = 10
    verticalSpacing = options[:verticalSpacing] || options[:fieldHeight] + 2
    @boundTop += verticalSpacing
    template = %q{
  		<Object type="Field" key="" LabelKey="" name="<%= options[:objectName] %>" flags="" rotation="0">
  			<Bounds top="<%= @boundTop %>" left="<%= fieldLeft %>" bottom="<%= @boundTop + options[:fieldHeight].to_i %>" right="<%= fieldLeft.to_i + options[:fieldWidth].to_i %>"/>
  			<FieldObj numOfReps="1" flags="" inputMode="0" displayType="0" quickFind="1" pictFormat="5">
  				<Name><%= fieldQualified %></Name>
  				<Styles>
  					<LocalCSS>
  					self {
  						font-family: -fm-font-family(<%= options[:font] %>);
  						font-size: <%= options[:fontSize] %>;
  					}
  					</LocalCSS>
  				</Styles>
  			</FieldObj>
  		</Object>}.gsub(/^\s*%/, '%')
    tpl = ERB.new(template, 0, '%<>')
    @text << tpl.result(binding)
    {:top => @boundTop, :left => fieldLeft}
  end
  
  # Constructs layout field object with label and appends to @text
  def layoutFieldWithLabel(fieldOptions,labelText,labelOptions={},labelOuterMargin = 11)
    bounds = self.layoutField(fieldOptions)
    labelOptions[:width] ||= 100
    labelOptions = {
      :top    => bounds[:top].to_i,
      :left   => bounds[:left].to_i - labelOptions[:width].to_i - labelOuterMargin.to_i
    }.merge(labelOptions.delete_blank)
    self.layoutText(labelText,labelOptions)
  end
    
  # Constructs layout text object and appends to @text
  # @param [String] text String to display
  # @param [Hash] options Hash containing text object attributes
  # @option options [String] :font
  # @option options [Integer] :fontSize
  # @option options [Integer] :height
  # @option options [String] :justification Alignment of text. 1 for left, 2 for center, 3 for right.
  # @option options [Integer] :leftMargin Padding of text inside of object
  # @option options [Integer] :rightMargin Padding of text inside of object
  # @option options [String] :textColor Hex value of text color
  # @option options [Integer] :width
  def layoutText(text,options={})
    return nil unless text
    options = {
      :font         => "Verdana",
      :fontSize     => 12,
      :justification  => 3,
      :textColor    => '#000000',
      :width        => 120
    }.merge(options.delete_blank)
    options[:height] ||= options[:fontSize].to_i + 6
    template = %q{
      <Object type="Text" key="" LabelKey="0" name="" flags="0" rotation="0">
      	<Bounds top="<%= options[:top].to_i %>" left="<%= options[:left].to_i %>" bottom="<%= options[:top].to_i + options[:height].to_i %>" right="<%= options[:left].to_i + options[:width].to_i %>"/>
      	<TextObj flags="0">
      		<Styles>
      			<LocalCSS>
      			self {
      				font-size: <%= options[:fontSize] %>;
      				text-align: <%= options[:justification] %>;
      				<%= "-fm-paragraph-margin-left: #{options[:leftMargin].to_i};" if options[:leftMargin] %>
      				<%= "-fm-paragraph-margin-right: #{options[:RightMargin].to_i};" if options[:RightMargin] %>
      			}
      			</LocalCSS>
      		</Styles>
      		<CharacterStyleVector>
      			<Style>
      				<Data>Title</Data>
      				<CharacterStyle mask="32695">
      					<Font-family codeSet="" fontId=""><%= options[:font] %></Font-family>
      					<Font-size><%= options[:fontSize] %></Font-size>
      					<Face>0</Face>
      					<Color><%= options[:textColor] %></Color>
      				</CharacterStyle>
      			</Style>
      		</CharacterStyleVector>
      	</TextObj>
      </Object>
    }.gsub(/^\s*%/, '%')
    tpl = ERB.new(template, 0, '%<>')
    @text << tpl.result(binding)
  end
    
end