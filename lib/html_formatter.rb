module HtmlFormatter
  def self.parse(*args, &block)
    Parser.parse(*args, &block)
  end
end

require_relative "html_formatter/version"
require_relative "html_formatter/parser"
require_relative "html_formatter/cli"
