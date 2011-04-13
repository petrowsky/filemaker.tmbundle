require 'rexml/document'

class REXML::Document
	
	def newSnippet()
		# Open the document and create root
		doc = REXML::Document.new
		root = REXML::Element.new "fmxmlsnippet"
		root.attributes["type"] = "FMObjectList"
		doc.add_element root
		return doc
	end
	
	def newElements(text)
		REXML::Text.new(
			text.to_s,
			respect_whitespace=true,
			parent=nil,
			raw=true,
			entity_filter=nil,
			illegal=%r/\n\[.^/m           # match nothing!
		)
	end
	
	def getFieldTable(fieldName)
		if fieldName.include?("::")
			return fieldName.split(/::/)[0]
		end
	end
	
	def getFieldName(fieldName)
		if fieldName.include?("::")
			return fieldName.split(/::/)[1]
		else
			return fieldName
		end
	end
	
	# def Boolean(string)
	# 	return true if string== true || string.downcase =~ (/(true|t|yes|y|1)$/i)
	# 	return false if string== false || string.nil? || string.downcase =~ (/(false|f|no|n|0)$/i)
	# 	raise ArgumentError.new(“invalid value for Boolean: \”#{string}\”")
	# end
		
	# options includes { ((table, field)|fieldQualified), repetition, calculation }
	def setField(options={})
		options = { :repetition => 2 }.merge(options)
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
		repTemplate = <<-END
	<Repetition>
		<Calculation><![CDATA[#{repCalc}]]></Calculation>
	</Repetition>
END
		repTemplate = repCalc ? "\n" + repTemplate : nil
		template = <<-END
<Step enable=\"True\" id=\"\" name=\"Set Field\">
	<Calculation><![CDATA[#{options[:calculation]}]]></Calculation>
	<Field table=\"#{table}\" id=\"\" repetition=\"#{rep}\" name=\"#{field}\"></Field>#{repTemplate}
</Step>
END
		return template
	end
	
	# options includes { type, comment, isGlobal, repetitions, calculation }
	def field(name,options={})
		name = getFieldName(name)
		options = {
			:type			=> "Text",
			:isGlobal		=> false,
			:repetitions	=> 1
		}.merge(options)
		isGlobal = options[:isGlobal] ? "True" : "False"
		template = <<-END
<Field id="" dataType="#{options[:type]}" fieldType="Normal" name="#{name}">
	<Calculation table=""><![CDATA[#{options[:calculation]}]]></Calculation>
	<Comment>#{options[:comment]}</Comment>
	<Storage indexLanguage="English" global="#{isGlobal}" maxRepetition="#{options[:repetitions]}"/>
</Field>
END
		return template
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
			:font		=> "Verdana",
			:fontSize	=> "12"
		}.merge(options)
		template = <<-END
	<Layout>
		<ObjectStyle id="0" fontHeight="" graphicFormat="5" fieldBorders="0">
			<CharacterStyle mask="32567">
				<Font-family codeSet="" fontId="">Verdana</Font-family>
				<Font-size>#{options[:fontSize]}</Font-size>
				<Face>0</Face>
				<Color>#000000</Color>
			</CharacterStyle>
		</ObjectStyle>
		<Object type="Field" flags="0" portal="-1" rotation="0">
			<StyleId>0</StyleId>
			<Bounds top=" 24.000000" left="214.000000" bottom=" 40.000000" right="293.000000"/>
			<ToolTip>
				<Calculation><![CDATA[#{options[:tooltip]}]]></Calculation>
			</ToolTip>
			<FieldObj numOfReps="1" flags="" inputMode="0" displayType="0" quickFind="0">
				<Name>#{fieldQualified}</Name>
				<DDRInfo>
					<Field name="#{field}" id="1" repetition="1" maxRepetition="1" table="#{table}"/>
				</DDRInfo>
			</FieldObj>
		</Object>
	</Layout>
END
	end
	
end