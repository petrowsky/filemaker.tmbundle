#!/usr/bin/env ruby
#
# fmsnippet.rb - helps manipulate and construct FileMaker clipboard XML (snippets)
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

require 'erb'

class Hash
  def delete_blank
    delete_if{|k, v| v.to_s.empty? or v.instance_of?(Hash) && v.delete_blank.empty?}
  end
end

module FileMaker

  PATH_BASE = File.dirname(__FILE__)
  PATH_ENCODE = "#{PATH_BASE}/encoding.sh"
  
  require "#{PATH_BASE}/fmcalc.rb"
  include FMCalc

  def escape_shell
    self.to_s.gsub(/'/,"'\\\\''")
  end

  # Replaces high ascii characters with placeholders for transfer to AppleScript
  def encode_text
    text = @text.escape_shell
    @text = `"#{PATH_ENCODE}" '#{text}'`
  end
  
  # def paste
  #   IO.popen('pbcopy', 'w+') { |clipboard| clipboard.print self.to_s }
  #   `osascript -e 'tell application "System Events" to keystroke "v" using {command down}'`
  # end
  
  require 'open3'
  def paste
    text = self.to_s
    # Open3.popen3( 'pbcopy' ) { |stdin, stdout, stderr| stdin << text }
    Open3.popen3( 'pbcopy' ) do
      |stdin, stdout, stderr|
      stdin.write(text)
      stdin.close_write
      stderr.read.split("\n").each do |line|
        puts "[parent] stderr: #{line}"
      end
    end
    `osascript -e 'tell application "System Events" to keystroke "v" using {command down}'`
  end

  class FMSnippet
    include FMCalc

    ROOT = 'fmxmlsnippet'
    PATH_PASTE = "#{PATH_BASE}/PasteSnippet.applescript"

    attr_accessor :type

    # types = {partial,layout_object}
    def initialize(xmlText='')
      @text = xmlText
      @isPartial = true unless xmlText =~ /\<#{ROOT}[\s\>]/
    end

    def set_type(type='')
      case @text
      when /\<Layout/, /\<ObjectStyle/, type == 'LayoutObjectList'
        @type = 'LayoutObjectList'
        @boundTop = 0
      else
        @type = 'FMObjectList'
      end
    end
    
    # Ensures snippet objects are wrapped in root XML elements
    def enclose
      self.set_type
      header = %Q{<?xml version="1.0" encoding="UTF-8"?>\n<#{ROOT} type="#{@type}">}
      footer = "\n</#{ROOT}>"
      if @type == 'LayoutObjectList' && !@text.match(/<Layout/i)
        @text = @text.insert(0,"\n  <Layout>")
      end
      @text = @text.insert(0,header) unless @text.to_s.include?("<#{ROOT}")
      if @type == 'LayoutObjectList' && !@text.match(/<\/Layout>/i)
        @text = @text.concat("\n  </Layout>")
      end
      @text = @text.concat(footer) unless @text.include?("</#{ROOT}>")
    end

    def to_s
      self.enclose
      @text.lstrip!
      @text
    end

    def self.step
      new!('partial')
    end

    # ------------------------------------
    # Clipboard Interaction
    # ------------------------------------

    def set_clipboard
      text = self.to_s.escape_shell
      shellScript = %Q[osascript "#{PATH_PASTE}" '#{text}']
      begin
        system shellScript
      rescue
        error = "Invalid XML. Try running Tidy first."
        puts error
        raise ClipboardError error
      end
    end

    # ------------------------------------
    # Custom Function
    # ------------------------------------

    def customFunction(name,params,calculation)
      template = %q{
    <CustomFunction id="" functionArity="1" visible="True" parameters="<%= params %>" name="<%= name %>">
      <Calculation><![CDATA[<%= calculation %>]]></Calculation>
    </CustomFunction>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    # ------------------------------------
    # Script and Script Step
    # ------------------------------------

    def stepComment(text=" ")
      template = %q{
    <Step enable="True" id="" name="Comment">
      <Text><%= text %></Text>
    </Step>
  }.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    def stepCommentHeader(text=" ")
      template = %q{
    <Step enable="True" id="" name="Comment"/>
    <Step enable="True" id="" name="Comment">
      <Text>__________________________________________________</Text>
    </Step>
    <Step enable="True" id="" name="Comment">
      <Text><%= text %></Text>
    </Step>
    <Step enable="True" id="" name="Comment"/>
  }.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    def stepIf(calculation)
      template = %q{
    <Step enable="True" id="" name="If">
      <Calculation><![CDATA[<%= calculation %>]]></Calculation>
    </Step>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    def stepElseIf(calculation)
      template = %q{
    <Step enable="True" id="" name="Else If">
      <Calculation><![CDATA[<%= calculation %>]]></Calculation>
    </Step>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    def stepElse
      template = %q{<Step enable="True" id="" name="Else"/>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    def stepEndIf
      template = %q{<Step enable="True" id="" name="End If"/>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    # options includes { ((table, field)|fieldQualified), repetition, calculation }
    # TODO: See YARD for how to document params
    def stepSetField(options={})
      # options = { :repetition => 2 }.merge(options)
      fieldQualified = options[:fieldQualified]
      table = options[:table] ||= field_table(fieldQualified)
      field = options[:field] ||= field_name(fieldQualified)
      repetition = options[:repetition]

      # FIXME: Repetition element being created for number reps
      repCalc = repetition.class == Fixnum ? nil : repetition
      rep = repCalc ? 0 : repetition
      template = %q{
    <Step enable="True" id="" name="Set Field">
      <Calculation><![CDATA[<%= options[:calculation] %>]]></Calculation>
      <Field table="<%= table %>" id="" repetition="<%= rep %>" name="<%= field %>"></Field>
      % if repCalc
      <Repetition>
       <Calculation><![CDATA[<%= repCalc %>]]></Calculation>
      </Repetition>
      % end
    </Step>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    def stepSetVariable(name,rep,calc)
      template = %q{
    <Step enable="True" id="" name="Set Variable">
      <Value>
        <Calculation><![CDATA[<%= calc %>]]></Calculation>
      </Value>
        % unless rep == 1 || nil
      <Repetition>
        <Calculation><![CDATA[<%= rep %>]]></Calculation>
      </Repetition>
        % end
      <Name><%= name %></Name>
    </Step>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    # fieldArray includes { field, direction }
    def stepSort(fieldArray,hideDialog=true)
      template = %q{
    <Step enable="True" id="" name="Sort Records">
      <NoInteract state="<%= Boolean(hideDialog).to_s.capitalize %>"/>
      <Restore state="True"/>
      <SortList value="True">
        % fieldArray.each do |field_cur|
          % direction = field_cur[:direction] || "Ascending"
          % fieldQualified = field_cur[:field]
          % table = field_table(fieldQualified)
          % name = field_name(fieldQualified)
          <Sort type="<%= direction.capitalize %>">
            <PrimaryField>
              <Field table="<%= table %>" id="" name="<%= name %>"/>
            </PrimaryField>
          </Sort>
        % end
      </SortList>
    </Step>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    # ------------------------------------
    # Table, Field, Layout Object
    # ------------------------------------

    # options includes { type, comment, isGlobal, repetitions, calculation }
    def field(name,options={})
      name = field_name(name)
      options = {
        :type         => "Text",
        :isGlobal     => false,
        :repetitions  => 1
      }.merge(options.delete_blank)
      calc = options[:calculation]
      isGlobal = Boolean(options[:isGlobal]) ? "True" : "False"
      template = %q{
    <Field id="" dataType="<%= options[:type] %>" fieldType="<%= options[:calculation].nil? ? 'Normal' : 'Calculated' %>" name="<%= name %>">
      <Calculation table=""><![CDATA[<%= options[:calculation] %>]]></Calculation>
      <Comment><%= options[:comment] %></Comment>
      <Storage indexLanguage="English" global="<%= isGlobal %>" maxRepetition="<%= options[:repetitions] %>"/>
    </Field>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end

    # TODO: Finish converting documentation to YARD format
    # Generates field objects to paste onto FileMaker layout
    #
    # @param [Hash] options
    #   options includes { ((field, table) | fieldQualified), tooltip, font, fontSize, objectName, fieldHeight, fieldWidth, verticalSpacing}
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
        :fieldHeight  => 12,
        :fieldWidth   => 120
      }.merge(options.delete_blank)
      fieldLeft = 10
      verticalSpacing = options[:verticalSpacing] || options[:fieldHeight] + 2
      @boundTop += verticalSpacing
      template = %q{
      <ObjectStyle id="0" fontHeight="<%= options[:fontSize].to_i + 3 %>" graphicFormat="5" fieldBorders="0">
        <CharacterStyle mask="">
          <Font-family codeSet="" fontId=""><%= options[:font] %></Font-family>
          <Font-size><%= options[:fontSize] %></Font-size>
          <Face>0</Face>
          <Color>#000000</Color>
        </CharacterStyle>
      </ObjectStyle>
      <Object type="Field" name="<%= options[:objectName] %>" flags="0" portal="-1" rotation="0">
        <StyleId>0</StyleId>
        <Bounds top="<%= @boundTop %>" left="<%= fieldLeft %>" bottom="<%= @boundTop + options[:fieldHeight].to_i %>" right="<%= fieldLeft.to_i + options[:fieldWidth].to_i %>"/>
        <ToolTip>
          <Calculation><![CDATA[<%= options[:tooltip] %>]]></Calculation>
        </ToolTip>
        <FieldObj numOfReps="1" flags="" inputMode="0" displayType="0" quickFind="0">
          <Name><%= fieldQualified %></Name>
          <DDRInfo>
            <Field name="<%= field %>" id="1" repetition="1" maxRepetition="1" table="<%= table %>"/>
          </DDRInfo>
        </FieldObj>
      </Object>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @text << tpl.result(binding)
    end
    
  end

end