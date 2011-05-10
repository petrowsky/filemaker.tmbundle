require 'erb'

# class REXML::Document
class FMSnippet
  TEMPLATE_HEADER = '<?xml version="1.0" encoding="UTF-8"?>'
  TEMPLATE_FOOTER = "\n</fmxmlsnippet>"
  
  # types = {layout_object}
  def initialize(type)
    @type = 
      if type == 'layout_object'
        'LayoutObjectList'
      else
        'FMObjectList'
      end
    @template = %!
#{TEMPLATE_HEADER}
<fmxmlsnippet type="#{@type}">!
  end
  
  def to_s
    @template << TEMPLATE_FOOTER
    @template.lstrip!
  end
  
  # ------------------------------------
  # Generic functionality
  # ------------------------------------
  
  def getFieldTable(fieldName)
    if fieldName.include?("::")
      return fieldName.split(/::/)[0]
    end
  end
  
  def getFieldName(fieldName)
    if fieldName.include?("::")
      return fieldName.split(/::/)[1]
    else
      fieldName
    end
  end
  
  # def Boolean(string)
  #   return true if string== true || string.downcase =~ (/(true|t|yes|y|1)$/i)
  #   return false if string== false || string.nil? || string.downcase =~ (/(false|f|no|n|0)$/i)
  #   raise ArgumentError.new(“invalid value for Boolean: \”#{string}\”")
  # end
  
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
  
  def stepSort(fieldArray,hideDialog="True")
    hideDialog = "True"
    template = %q{
  <Step enable="True" id="" name="Sort Records">
    <NoInteract state="<%= hideDialog %>"/>
    <Restore state="True"/>
    <SortList value="True">
      % fieldArray.each do |field_cur|
        % direction = field_cur[:direction] || "Ascending"
        % fieldQualified = field_cur[:field]
        % table = getFieldTable(fieldQualified)
        % name = getFieldName(fieldQualified)
        <Sort type="<% field_cur['direction'] %>">
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
  def stepSetField(options={})
    # options = { :repetition => 2 }.merge(options)
    fieldQualified = options[:fieldQualified]
    if fieldQualified
      table = getFieldTable(fieldQualified)
      field = getFieldName(fieldQualified)
    else
      table = options[:table]
      field = options[:field]
    end
    repetition = options[:repetition]
    
    repCalc = repetition.class == Fixnum ? nil : repetition
    rep = repCalc ? 0 : repetition
  #   repTemplate = %q{
  # <Repetition>
  #   <Calculation><![CDATA[<%= repCalc %>]]></Calculation>
  # </Repetition>}.gsub(/^\s*%/, '%')
  #   repTemplate = repCalc ? "\n" + repTemplate : nil
  #   template = %q{
  # <Step enable=\"True\" id=\"\" name=\"Set Field\">
  #   <Calculation><![CDATA[<%= options[:calculation] %>]]></Calculation>
  #   <Field table=\"<%= table %>\" id=\"\" repetition=\"<%= rep %>\" name=\"<%= field %>\"></Field>
  #   <%= repTemplate %>
  # </Step>}.gsub(/^\s*%/, '%')
    template = %q{
  <Step enable=\"True\" id=\"\" name=\"Set Field\">
    <Calculation><![CDATA[<%= options[:calculation] %>]]></Calculation>
    <Field table=\"<%= table %>\" id=\"\" repetition=\"<%= rep %>\" name=\"<%= field %>\"></Field>
    % if repCalc
    <Repetition>
     <Calculation><![CDATA[<%= repCalc %>]]></Calculation>
    </Repetition>
    % end
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
    isGlobal = options[:isGlobal] ? "True" : "False"
    template = %q{
  <Field id="" dataType="<%= options[:type] %>" fieldType="Normal" name="<%= name %>">
    <Calculation table=""><![CDATA[<%= options[:calculation] %>]]></Calculation>
    <Comment><%= options[:comment] %></Comment>
    <Storage indexLanguage="English" global="<%= isGlobal %>" maxRepetition="<%= options[:repetitions] %>"/>
  </Field>}.gsub(/^\s*%/, '%')
    tpl = ERB.new(template, 0, '%<>')
    @template << tpl.result(binding)
  end
  
  # options includes { ((field, table) | fieldQualified), tooltip, font, fontSize}
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
      :font   => "Verdana",
      :fontSize => "12"
    }.merge(options)
    template = %q{
  <Layout>
    <ObjectStyle id="0" fontHeight="" graphicFormat="5" fieldBorders="0">
      <CharacterStyle mask="32567">
        <Font-family codeSet="" fontId="">Verdana</Font-family>
        <Font-size><%= options[:fontSize] %></Font-size>
        <Face>0</Face>
        <Color>#000000</Color>
      </CharacterStyle>
    </ObjectStyle>
    <Object type="Field" flags="0" portal="-1" rotation="0">
      <StyleId>0</StyleId>
      <Bounds top=" 24.000000" left="214.000000" bottom=" 40.000000" right="293.000000"/>
      <ToolTip>
        <Calculation><![CDATA[<%= options[:tooltip] %>]]></Calculation>
      </ToolTip>
      <FieldObj numOfReps="1" flags="" inputMode="0" displayType="0" quickFind="0">
        <Name><%= fieldQualified %></Name>
        <DDRInfo>
          <Field name="<%= field %>" id="1" repetition="1" maxRepetition="1" table="<%= table %>"/>
        </DDRInfo>
      </FieldObj>
    </Object>
  </Layout>}.gsub(/^\s*%/, '%')
    tpl = ERB.new(template, 0, '%<>')
    @template << tpl.result(binding)
  end
  
end