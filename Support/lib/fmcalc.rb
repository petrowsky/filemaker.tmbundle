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
  def parse_function(prefixToExampleSyntax)
    calc = self.to_s
    nameFull =
      calc.match(/^\/\*.*?[\n\s]*#{prefixToExampleSyntax}[\s\n]*(.+?)\n/m) ||
      calc.match(/^\/\/.*?\s*#{prefixToExampleSyntax}\s*(.+?)$/m)
    nameFull = nameFull[1]
    name = nameFull.match(/\s*(.+?)\(/)[1].strip
    params = nameFull.match(/\((.*?)\)/)[1].gsub(/\s*/,'')
    FMSnippet.new.customFunction(name,params,calc).to_s
  end

  def field_table(fieldName)
    fieldName = fieldName.to_s
    if fieldName.include?("::")
      return fieldName.split(/::/)[0]
    end
  end

  def field_name(fieldName)
    fieldName = fieldName.to_s
    if fieldName.include?("::")
      return fieldName.split(/::/)[1]
    else
      fieldName
    end
  end

  # Returns array of script parameters in text
  def parse_params(text)
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
  
  def function_example
    %Q{
number ^ 2

/* —————————————————————————————— //
NAME:
\tsquared ( number )

NOTES:
\tThe important part is to prepend your syntax example with "NAME:"

*/}
  end
  
end