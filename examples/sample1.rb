# -*- coding: utf-8 -*-

begin
  require_relative "../lib/html_formatter"
rescue LoadError
  require File.expand_path(File.join(File.dirname(__FILE__), "../lib/html_formatter"))
end

puts HtmlFormatter.parse("<html><head><title>hello</title></head><body>world</body></html>")
# >> <html>
# >>   <head>
# >>     <title>hello</title>
# >>   </head>
# >>   <body>
# >>     world
# >>   </body>
# >> </html>
