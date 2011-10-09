#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# コマンドライン用
#
require "html_formatter/html_formatter"
require "optparse"
require "pathname"

class HtmlFormatter
  class CLI
    def self.execute(argv = ARGV)
      options = {}
      oparser = OptionParser.new{|oparser|
        oparser.on("-c", "簡易タグ対応チェック"){|options[:validate]|}
      }
      oparser.parse!(argv)

      ok_count = 0
      error_count = 0
      argv.each{|fname|
        fname = Pathname(fname).expand_path
        html_formatter = HtmlFormatter.new(fname.read)
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
      }
      if options[:validate] || error_count.nonzero?
        p [:ok_count, ok_count, :error_count, error_count]
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  HtmlFormatter::CLI.execute
end
