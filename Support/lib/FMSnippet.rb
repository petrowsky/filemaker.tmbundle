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

module FMCalc
  
  def Boolean(string)
    string = string.to_s
    case string  
      when /^(false|f|no|0)$/i
        false
      else
        string.class == String
    end 
  end
  
  # Returns function as fmxmlsnippet
  # Depends on format of function comments
  def functionAsSnippet(examplePrefix)
    calc = self.to_s
    nameFull = 
      calc.match(/^\/\*.*?[\n\s]*#{examplePrefix}[\s\n]*(.+?)\n/m) ||
      calc.match(/^\/\/.*?\s*#{examplePrefix}\s*(.+?)$/m)
    nameFull = nameFull[1]
    name = nameFull.match(/\s*(.+?)\(/)[1].strip
    params = nameFull.match(/\((.*?)\)/)[1].gsub(/\s*/,'')
    FMSnippet.new.customFunction(name,params,calc).to_s
  end
  
  def getFieldTable(fieldName)
    fieldName = fieldName.to_s
    if fieldName.include?("::")
      return fieldName.split(/::/)[0]
    end
  end

  def getFieldName(fieldName)
    fieldName = fieldName.to_s
    if fieldName.include?("::")
      return fieldName.split(/::/)[1]
    else
      fieldName
    end
  end
  
  # Returns array of script parameters in string
  def parseParams(text)
    if text =~ /;/
      textArray = text.split(/;/)
    else
      textArray = text
    end
    result = []
    textArray.each do |param|
      param.strip!
      param[0] == "-" ? param.slice!(0) : param
      result << param
    end
    return result
  end
end

module FileMaker
  include FMCalc
  
  PATH_BASE = File.dirname(__FILE__)
  PATH_ENCODE = "#{PATH_BASE}/encoding.sh"

  def escapeForShell
    self.to_s.gsub(/'/,"'\\\\''")
  end

  def encodeText
    text = @template.escapeForShell
    @template = `"#{PATH_ENCODE}" '#{text}'`
  end
  
  class FMSnippet
    include FMCalc
    
    ROOT = 'fmxmlsnippet'
    TEMPLATE_HEADER = %Q{<?xml version="1.0" encoding="UTF-8"?>\n<#{ROOT} type="#{@type}">}
    TEMPLATE_FOOTER = "\n</#{ROOT}>"
    PATH_PASTE = "#{PATH_BASE}/PasteSnippet.applescript"
    
    attr_accessor :type
  
    # types = {partial,layout_object}
    def initialize(xmlText='')
      @template = xmlText
      @isPartial = true unless xmlText =~ /\<#{ROOT}[\s\>]/
    end
    
    def set(text)
      @template << text
    end
    
    def append(text)
      @template << text
    end
  
    def set_type
      case @template
      when /\<Layout/
        @type = 'LayoutObjectList'
        @boundTop = 0
      else
        @type = 'FMObjectList'
      end
    end
  
    def to_s
      self.set_type
      # @template = @template.insert(0,TEMPLATE_HEADER) unless @template.include?("<#{ROOT}")
      # @template = "XXXXXXX".concat(@template)
      # @template = @template.concat('</Layout>') if @type == 'LayoutObjectList' and @template.include?('</layout>') == false
      @template = @template.concat(TEMPLATE_FOOTER) unless @template.include?("</#{ROOT}>")
      @template.lstrip!
    end
  
    def self.step
      new!('partial')
    end
    
    # ------------------------------------
    # Clipboard Interaction
    # ------------------------------------

    def setClipboard
      text = self.to_s.escapeForShell
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
      @template << tpl.result(binding)
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
      @template << tpl.result(binding)
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
      @template << tpl.result(binding)
    end
  
    def stepIf(calculation)
      template = %q{
    <Step enable="True" id="" name="If">
      <Calculation><![CDATA[<%= calculation %>]]></Calculation>
    </Step>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @template << tpl.result(binding)
    end
  
    def stepElseIf(calculation)
      template = %q{
    <Step enable="True" id="" name="Else If">
      <Calculation><![CDATA[<%= calculation %>]]></Calculation>
    </Step>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @template << tpl.result(binding)
    end
  
    def stepElse
      template = %q{<Step enable="True" id="" name="Else"/>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @template << tpl.result(binding)
    end
  
    def stepEndIf
      template = %q{<Step enable="True" id="" name="End If"/>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @template << tpl.result(binding)
    end
  
    # options includes { ((table, field)|fieldQualified), repetition, calculation }
    # TODO: See YARD for how to document params
    def stepSetField(options={})
      # options = { :repetition => 2 }.merge(options)
      fieldQualified = options[:fieldQualified]
      table = options[:table] ||= getFieldTable(fieldQualified)
      field = options[:field] ||= getFieldName(fieldQualified)
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
      @template << tpl.result(binding)
    end
  
    def stepSetVariable(name,rep,calc)
      template = %q{  <Step enable="True" id="" name="Set Variable">
       <Value>
         <Calculation><![CDATA[<%= calc %>]]></Calculation>
       </Value>
       % unless rep == 1 || nil
       <Repetition>
         <Calculation><![CDATA[<%= rep %>]]></Calculation>
       </Repetition>
       % end
       <Name><%= name %></Name>
    </Step>
  }.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      if @isPartial
        tpl.result(binding)
      elsif
        @template << tpl.result(binding)
      end
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
          % table = getFieldTable(fieldQualified)
          % name = getFieldName(fieldQualified)
          <Sort type="<%= direction.capitalize %>">
            <PrimaryField>
              <Field table="<%= table %>" id="" name="<%= name %>"/>
            </PrimaryField>
          </Sort>
        % end
      </SortList>
    </Step>}.gsub(/^\s*%/, '%')
      tpl = ERB.new(template, 0, '%<>')
      @template << tpl.result(binding)
    end
  
    # ------------------------------------
    # Table, Field, Layout Object
    # ------------------------------------
  
    # options includes { type, comment, isGlobal, repetitions, calculation }
    def field(name,options={})
      name = getFieldName(name)
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
      @template << tpl.result(binding)
    end
  
    # TODO: Finish converting documentation to YARD format
    # Generates field objects to paste onto FileMaker layout
    #
    # @param [Hash] options 
    #   options includes { ((field, table) | fieldQualified), tooltip, font, fontSize, objectName, fieldHeight, fieldWidth, verticalSpacing}
    def layoutField(options={})
      fieldQualified = options[:fieldQualified]
      if fieldQualified
        table = getFieldTable(fieldQualified)
        field = getFieldName(fieldQualified)
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
      <ObjectStyle id="0" fontHeight="<%= options[:fontSize] + 3 %>" graphicFormat="5" fieldBorders="0">
        <CharacterStyle mask="">
          <Font-family codeSet="" fontId=""><%= options[:font] %></Font-family>
          <Font-size><%= options[:fontSize] %></Font-size>
          <Face>0</Face>
          <Color>#000000</Color>
        </CharacterStyle>
      </ObjectStyle>
      <Object type="Field" name="<%= options[:objectName] %>" flags="0" portal="-1" rotation="0">
        <StyleId>0</StyleId>
        <Bounds top="<%= @boundTop %>" left="<%= fieldLeft %>" bottom="<%= @boundTop + options[:fieldHeight] %>" right="<%= fieldLeft + options[:fieldWidth] %>"/>
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
      @template << tpl.result(binding)
    end
  end

  class Hash
    def delete_blank
      delete_if{|k, v| v.to_s.empty? or v.instance_of?(Hash) && v.delete_blank.empty?}
    end
  end
  
end