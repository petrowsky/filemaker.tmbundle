#!/usr/bin/env ruby -rcgi

# By Henrik Nyh &lt;http://henrik.nyh.se&gt; 2007-06-26
# Free to modify and redistribute with credit.

# Adapted for FileMaker bundle by Donovan Chandler 2011-05-25

# SUPPORT_PATH = [ENV['TM_SUPPORT_PATH']
SUPPORT_PATH = "/Library/Application\ Support/TextMate/Support/"

%w{ui web_preview escape}.each { |lib| require "%s/lib/%s" % SUPPORT_PATH, lib] }

NAME = "Grep in Project"
HEAD  = <<-HTML
  <style type="text/css">
    table { font-size:0.9em; border-collapse:collapse; border-bottom:1px solid #555; }
    h2 { font-size:1.3em; }
    tr { background:#FFF; }
    tr.odd { background:#EEE; }
    td { vertical-align:top; white-space:nowrap; padding:0.4em 1em; color:#000 !important; }
    tr td:first-child { text-align:right; padding-right:1.5em; }
    td a { color:#00F !important; }
    tr.binary { background:#E8AFA8; }
    tr.binary.odd { background:#E0A7A2; }
    tr#empty { border-bottom:1px solid #FFF; }
    tr#empty td { text-align:center; }
    tr.newFile, tr.binary { border-top:1px solid #555; }
    .keyword { font-weight:bold; background:#F6D73A; margin:0 0.1em; }
    .ellipsis { color:#777; margin:0 0.5em; }
  </style>
  <script type="text/javascript">
    function reveal_file(path) {
      const quote = '"';
      const command = "osascript -e ' tell app "+quote+"Finder"+quote+"' " +
                        " -e 'reveal (POSIX file " +quote+path+quote + ")' " +
                        " -e 'activate' " + 
                      " -e 'end' ";
      TextMate.system(command, null);
    }

  function findPos(obj) {
    var curleft = curtop = 0;
    if (obj.offsetParent) {
      curleft = obj.offsetLeft
      curtop = obj.offsetTop
      while (obj = obj.offsetParent) {
        curleft += obj.offsetLeft
        curtop += obj.offsetTop
      }
    }
    return {left: curleft, top: curtop};
  }
  
  function resizeTableToFit() {
    var table = document.getElementsByTagName("table")[0];
    const minWidth = 450, minHeight = 250;

    var pos = findPos(table);
    var tableFitWidth = table.offsetWidth + pos.left * 2;
    var tableFitHeight = table.offsetHeight + pos.top + 50;
    var screenFitWidth = screen.width - 150;
    var screenFitHeight = screen.height - 150;

    var setWidth = tableFitWidth > screenFitWidth ? screenFitWidth : tableFitWidth;
    var setHeight = tableFitHeight > screenFitHeight ? screenFitHeight : tableFitHeight;  
    setWidth = setWidth < minWidth ? minWidth : setWidth;
    setHeight = setHeight < minHeight ? minHeight : setHeight;

    window.resizeTo(setWidth, setHeight);
  }
  
  </script>
HTML

RESIZE_TABLE = <<-HTML
  <script type="text/javascript">
    resizeTableToFit();
  </script>
HTML

def ellipsize_path(path)
  path.sub(/^(.{30})(.{10,})(.{30})$/) { "#$1⋯#$3" }
end

def escape(string)
  CGI.escapeHTML(string)
end

def bail(message)
  puts <<-HTML
    <h2>#{ message }</h2>
  HTML
  html_footer
  exit
end

directory = ENV['TM_PROJECT_DIRECTORY'] || 
            ( ENV['TM_FILEPATH'] && File.dirname(ENV['TM_FILEPATH']) )

puts html_head(
  :window_title => NAME,
  :page_title   => NAME,
  :sub_title    => directory || "Error",
  :html_head    => HEAD
)

bail("Not in a saved file") unless directory

# query = TextMate::UI.request_string(:title => "Grep in Project", :prompt => "Find this:", :default => %x{pbpaste -pboard find})
query = '(?=[\b\s]).+?(?=\()'
bail("Search aborted") unless query
IO.popen('pbcopy -pboard find', 'w') { |copy| copy.print query }

puts <<-HTML
  <h2>Searching for “#{ escape(query) }”</h2>
  <table>
HTML

# TODO: Respect ENV['TM_SELECTED_FILES']
command = %{cd "#{directory}"; find . \\( -path '*/.svn' -or -path '*/vendor/rails' \\) -prune -or -type f -print0 | xargs -0 grep -nr --ignore-case --exclude='*.log' #{e_sh query}}

IO.popen(command) do |pipe|

  # Used to highlight matches
  query_re = Regexp.new( Regexp.escape(CGI.escapeHTML(query)), Regexp::IGNORECASE)
  
  last_path = path = i = nil
  pipe.each_with_index do |line, i|

    if line =~ /^(Binary file )(.*?) matches/
      prefix, file = $1, $2
      path = directory + file[1..-1]
      puts <<-HTML
        <tr class="binary #{ 'odd' unless i%2==0 }">
          <td>
            #{ prefix }
            <a href="javascript:reveal_file('#{ escape(path) }')" title="#{ escape(path) }">#{ ellipsize_path(file) }</a>
          </td>
          <td></td>
        </tr>
        #{ RESIZE_TABLE if i%100==0 }
      HTML
      next
    end

    line.gsub!(/^([^:]+):(\d+):(.*)$/) do

      relative_path, line_number, content = $1, $2, $3.strip
      path = directory + relative_path[1..-1]
      url = "txmt://open/?url=file://#{path}&line=#{line_number}"
      
      content = escape(content).
                  # Highlight keywords
                  gsub(query_re) { %{<strong class="keyword">#$&</strong>} }.
                  # Ellipsize before, between and after keywords
                  gsub(%r{(^[^<]{25}|</strong>[^<]{15})([^<]{20,})([^<]{15}<strong|[^<]{25}$)}) do
                    %{#$1<span class="ellipsis" title="#{escape($2)}">⋯</span>#$3}
                  end
      <<-HTML

        <tr class="#{ 'odd' unless i%2==0 } #{ 'newFile' if (path != last_path) }">
          <td>
            <a href="#{ url }" title="#{ "%s:%s" % [path, line_number] }">
              #{ "%s:%s" % [ellipsize_path(relative_path), line_number] }
            </a>
          </td>
          <td>#{ content }</td>
        </tr>

      HTML
    end
    puts line
    last_path = path

  end

  if i
    # A paragraph inside the table ends up at the top even though it's output
    # at the end. Something of a hack :)
    i += 1
    puts <<-HTML
      <p>#{i} matching line#{i==1 ? '' : 's'}:</p>
      #{RESIZE_TABLE}
    HTML
  else
    puts <<-HTML
      <tr id="empty"><td colspan="2">No results.</td></tr>
    HTML
  end
    
end

puts <<-HTML
</table>
HTML

html_footer