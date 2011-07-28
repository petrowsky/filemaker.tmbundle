#!/usr/bin/env ruby
#
# fmsnippet.rb - helps manipulate and construct FileMaker clipboard XML (snippets)
#

require 'erb'

class FMSnippet
  TEMPLATE_HEADER = '<?xml version="1.0"?>'
  TEMPLATE_FOOTER = "\n</fmxmlsnippet>"
  
  # types = {partial,layout_object}
  def initialize(type)
    case type
    when 'partial'
      @template = ''
      @isPartial = true
      return
    when 'layout_object'
      @type = 'LayoutObjectList'
      @boundTop = 0
      @template = %!
#{TEMPLATE_HEADER}
<fmxmlsnippet type="#{@type}">
<Layout>!
    else
      @type = 'FMObjectList'
      @template = %!
#{TEMPLATE_HEADER}
<fmxmlsnippet type="#{@type}">!
    end
  end
  
  def to_s
    if @type == 'LayoutObjectList'
      @template << '</Layout>'
    end
    @template << TEMPLATE_FOOTER
    @template.lstrip!
  end
  
  def self.step
    new!('partial')
  end
  
  # ------------------------------------
  # Generic functionality
  # ------------------------------------
  
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
  
  def Boolean(string)
    string = string.to_s
    case string  
      when /^(false|f|no|0)$/i
        false
      else
        string.class == String
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
    <NoInteract state="<%= Boolean(hideDialog) %>"/>
    <Restore state="True"/>
    <SortList value="True">
      % fieldArray.each do |field_cur|
        % direction = field_cur[:direction] || "Ascending"
        % fieldQualified = field_cur[:field]
        % table = getFieldTable(fieldQualified)
        % name = getFieldName(fieldQualified)
        <Sort type="<%= direction %>">
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
    }.merge(options)
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
  #   options includes { ((field, table) | fieldQualified), tooltip, font, fontSize, objectName, fieldHeight, fieldWidth}
  def layoutField(options={})
    @boundTop += 20
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
      :fontSize     => "12",
      :fieldheight  => 12,
      :fieldWidth   => 120
    }.merge(options)
    fieldLeft = 200
    template = %q{
    <ObjectStyle id="0" fontHeight="" graphicFormat="5" fieldBorders="0">
      <CharacterStyle mask="32567">
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