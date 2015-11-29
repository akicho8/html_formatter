# -*- coding: utf-8 -*-
#
# コマンドライン用
#
require "optparse"
require "pathname"

require "html_formatter/parser"

module HtmlFormatter
  class CLI
    def self.execute(argv)
      options = {}
      oparser = OptionParser.new do |oparser|
        oparser.on("-c", "簡易タグ対応チェック") { |v|
          options[:validate] = v
        }
      end
      oparser.parse!(argv)

      ok_count = 0
      error_count = 0
      argv.each do |fname|
        fname = Pathname(fname).expand_path
        html_formatter = Parser.new(fname.read)
        begin
          formated_html = html_formatter.parse
        rescue HtmlFormatter::DepthError => error
        end
        if options[:validate]
          if html_formatter.depth.zero?
            puts "ok: #{fname}"
            ok_count += 1
          else
            puts "error: #{fname}"
            error_count += 1
          end
        else
          if error
            STDERR.puts "#{error.class.name}: #{fname}"
            error_count += 1
          end
          if formated_html
            puts formated_html
          end
        end
      end
      if options[:validate] || error_count.nonzero?
        p [:ok_count, ok_count, :error_count, error_count]
      end
    end
  end
end

if $0 == __FILE__
  HtmlFormatter::CLI.execute
end
