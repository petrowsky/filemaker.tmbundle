#!/usr/bin/env ruby -KU
# encoding: UTF-8
#
# fmcalc.rb - manipulates FileMaker calculations
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

# Manipulates FileMaker calculations
module FMCalc
  
  # here = File.dirname(__FILE__)
  # require "#{here}/comments.rb"
  # include Comments

  # Coerces string into boolean.
  # @param [String] string String to coerce into boolean
  # @return [true, false] Defaults to true unless string = (false|f|no|0)
  def Boolean(string)
    string = string.to_s
    case string
      when /^(false|f|no|0)$/i
        false
      else
        string.class == String
    end
  end
  
  # Extracts names of functions used in text
  # @param [String] text Calculation containing function names to extract
  # @return [Array] Names of functions in text
  def extract_functions(text)
    text.to_s.scan(/[#a-zA-Z\._-]+?(?=\s*\()/)
  end

  # Generates custom function snippet from FileMaker calculation
  # @param [String] prefixToExampleSyntax String that precedes example of custom function's syntax
  # @example
  #   %Q{Substitute ( text ; currentDelimiter ; " " )\n//TabDelimit ( text ; currentDelimiter )}.parse_function("Name:")
  # @return [String,nil] XML element generated for custom function. Nil if syntax is unrecognized.
  def parse_function(prefixToExampleSyntax)
    calc = self.to_s
    begin
      string =
        calc.match(/^\/\*.*?[\n\s]*#{prefixToExampleSyntax}[\s\n]*(.+?)\n/m) ||
        calc.match(/^\/\/.*?\s*#{prefixToExampleSyntax}\s*(.+?)$/m)
      nameFull = string[1]
      name = nameFull.match(/\s*(.+?)\(/)[1].strip
      params = nameFull.match(/\((.*?)\)/)[1].gsub(/\s*/,'')
      FMSnippet.new.customFunction(name,params,calc).to_s
    rescue
      nil
    end
  end

  # Parses fully qualified field name to return table occurrence
  # @param [String] fieldName Fully qualified field name
  # @return [String] Name of table occurrence
  # @example
  #   puts field_table('CONTACT_PARENT::NAME') # =>  'CONTACT_PARENT'
  def field_table(fieldName)
    fieldName = fieldName.to_s
    if fieldName.include?("::")
      fieldName.split(/::/)[0]
    end
  end

  # Parses fully qualified field name to return name of field
  # @param [String] fieldName Fully qualified field name
  # @return [String] Name of field
  # @example
  #   puts field_name('CONTACT::NAME') # => 'NAME'
  def field_name(fieldName)
    fieldName = fieldName.to_s
    if fieldName.include?("::")
      fieldName.split(/::/)[1]
    else
      fieldName
    end
  end

  # Delimiter prepended to parameters in script names and documentation to indicate they're optional
  $paramDelimOptional = "-"
  # Delimiter used in script names and documentation to indicate "or" relationship between parameters
  $paramDelimOr = "|"

  # Provides default mapping between string and local variable
  # @param [String] name Variable name
  # @return [String] Full variable name
  # @example
  #   puts param_to_var('contact') # => '$_contact'
  def param_to_var(name)
    return "$_#{name}"
  end

  # Returns default calculation for extracting script parameters
  # @param [String] name Name of FileMaker script parameter
  # @return [String] FileMaker calculation used to extract parameter. Strips optionality indicator declared in $paramDelimitOptional.
  # @example
  #   puts param_extract('-id') # => '#P ( "ID" )'
  def param_extract(name)
    return '#P ( "' + param_clean(name).upcase + '" )'
  end

  # Returns true if named script parameter is optional
  # @param [String] name Name of parameter (including optionality indicator prefix defined in $paramDelimOptional)
  # @return [true, false]
  def param_is_optional(name)
    name.start_with?($paramDelimOptional)
  end

  # Strips extraneous indicators from parameter name
  # @param [String] name Name of parameter (including optionality indicator prefix defined in $paramDelimOptional)
  def param_clean(name)
    return nil if !name
    res = name.dup
    res.slice!(/#{$paramDelimOptional}/u)
    res
  end

  # Returns array of script parameters from string
  # @param [String] scriptName String containing script input parameters
  # @return [Array] Each input parameter
  # @example
  #   scriptName = 'script ( param1 ; -optionalParam ) : output'
  #   puts parse_params(scriptName) # => '["param1","-optionalParam"]'
  def parse_params(scriptName)
    params = scriptName.match(/\((.+)\)/)
    return nil unless params
    params[1].split(/;/).map{|x| x.strip}
  end
  
  # Returns array of script result parameters in text
  # @param [String] scriptName String containing result parameters
  # @return [Array] Each output parameter
  # @example
  #   scriptName = 'script ( param1 ; -optionalParam ) : output'
  #   puts parse_results(scriptName) # => '["output"]'
  def parse_results(scriptName)
    params = scriptName.match(/:(.*$)/)
    return nil unless params
    params[1].split(/;/).map{|x| x.strip}
  end

  # Returns calculation with operators and delimiters moved to end of each line
  # @param [String] calculation
  # @return [String] Calculation with operators and delimiters moved to end of each line
  # @example
  #   calc = "Let ( [\n\tanimal = \"dog\" //comment\n\t; habitat = \"house\"\n\t] ;\nanimal\n)"
  #   puts append_delims(calc) # => "Let ( [\n\tanimal = \"dog\" ; //comment\n\thabitat = \"house\"\n\t] ;\nanimal\n)"
  # @todo Remove quoted strings, cplus comments, and c comments before processing
  # @todo Fix bug whereby delim is inserted after comments
  # @todo Figure out how to encode not-equals and exponent signs properly
  def append_delims(calculation)
    # Preserve special delimiters like '];' with placeholders
    calculation.gsub!(/^(\s*)\](\s*);(\s*)$/,"\\1::93::\\2::59::\\3")

    regex = /^(\s*(?:\/\*.*?\/\*)*)           (?# Leading whitespace and comments)
            ([;&+\-<>≤≥#{94.chr}]
            |(?:and|or|not|xor))\s*
            /xu

    delim = nil
    array = calculation.split("\n").reverse.map do |line|

      # Skip comments
      if line =~ %r{^(\s*|\s*//)$}
        line
      else
        # Append delim from previous line
        # line = delim ? line.gsub(/(?:\s*|(\s*\/\/.*?))$/,"#{delim}\\1") : line
        # puts line.match(/(?:\s*|(\s*\/\/.*?))$/).inspect
        line = delim ? line.gsub(/(?:\s*|(\s*\/\/.*?))$/," #{delim}\\1") : line

        # Store delim to carry to next line
        match = line.match(regex)
        delim = match ? match[2] : nil

        # Strip delim from current line
        line.gsub!(regex,"\\1")
        line
      end
    end
    calculation = array.reverse.join("\n")
    calculation.gsub('::93::',']').gsub('::59::',';')
  end


  
  # Returns calculation with operators and delimiters moved to begining of each line
  # @param [String] calculation
  # @return [String] Calculation with operators and delimiters moved to begining of each line
  # @example
  #   calc = "Let ( [\n\tanimal = \"dog\" ; //comment\n\thabitat = \"house\"\n\t] ;\nanimal\n)"
  #   puts prepend_delims(calc) # => "Let ( [\n\tanimal = \"dog\" //comment\n\t; habitat = \"house\"\n\t] ;\nanimal\n)"
  # @todo Remove quoted strings, cplus comments, and c comments before processing
  def prepend_delims(calculation)
    # Preserve special delimiters like '];' with placeholders
    calculation.gsub!(/^(\s*)\](\s*);(\s*)$/,"\\1::93::\\2::59::\\3")

    regex = /\s*
            ([;&+\-<>≤≥≠^]
            |(?:and|or|not|xor))
            (?:\s*|(\s*\/\/.*?))?$          (?# Preserve end-of-line comments)
            /x

    delim = nil
    array = calculation.split("\n").map do |line|

      # Skip comments
      if line =~ %r{^\s*//}
        line
      else
        # Prepend delim from previous line
        line = delim ? line.gsub(/^(\s*)/,"\\1#{delim} ") : line

        # Store delim to carry forward
        match = line.match(regex)
        delim = match ? match[1] : nil

        # Strip delim from current line
        line.gsub!(regex,"\\2")
        line
      end
    end
    calculation = array.join("\n")
    calculation.gsub('::93::',']').gsub('::59::',';')
  end
  
  # Returns list of appended lines as List( ) calculation
  # @param [String] calculation Calculation to be converted
  # @return [String] Calculation wrapped in List( ) function with any trailing ampersand (&) on a line replaced with a semi-colon (;)
  # @example
  #   puts to_list("$_dog &\n$_cat &\n$_mouse") # => "List (\n$_dog ;\n$_cat ;\n$_mouse\n)"
  def to_list(calculation)
    return '' unless calculation
    calculation.gsub!(/&\s*$/,";")
    return "List (\n  #{calculation}\n)"
  end
  
  # Stub currently just used for testing and documentation
  def function_example
    %Q{
number ^ 2

/* ---------------------------------- //
NAME:
\tsquared ( number )

NOTES:
\tThe important part is to prepend your syntax example with "NAME:"

*/}
  end
  
end