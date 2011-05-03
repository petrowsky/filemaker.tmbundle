require 'FMSnippet.rb'

# Open the document and create root
doc = FMSnippet.new("")

fieldArray = []
fieldArray << {
  :field    => "FOCUS::ID",
  :direction  => "Descending"
}
fieldArray << {
  :field    => "CONTACT::name",
  :direction  => "Descending"
}
doc.stepSort(fieldArray,"True")
doc.stepSort(fieldArray,"True")

puts doc