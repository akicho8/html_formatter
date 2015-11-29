$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'html_formatter'

puts HtmlFormatter.parse("<html><head><title>hello</title></head><body>world</body></html>")
# >> <html>
# >>   <head>
# >>     <title>hello</title>
# >>   </head>
# >>   <body>
# >>     world
# >>   </body>
# >> </html>
