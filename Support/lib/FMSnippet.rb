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
  # Script and Script Step
  # ------------------------------------
  
  def stepSort(fieldArray,hideDialog="True")
    hideDialog = "True"
    template = %q{
  <Step enable="True" id="" name="Sort Records">
    <NoInteract state="<%= "hideDialog" %>"/>
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
  
  # ------------------------------------
  # Table, Field, Layout Object
  # ------------------------------------
  
  
end