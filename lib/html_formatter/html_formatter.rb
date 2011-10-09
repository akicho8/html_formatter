# -*- coding: utf-8; compile-command: "ruby -Ku ../../spec/html_formatter_spec.rb" -*-
#
# HTMLの整形
#
#   source = '
#     <!doctype html>
#     <html>
#       <head>
#         <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
#         <title>title</title>
#       </head>
#       <body>
#       <div><p><img src="icon.png" /><br/><span>title</span></p></div>
#       </body>
#     </html>
#   '
#
#   puts HtmlFormatter.parse(source) #=>
#
#     <!doctype html>
#     <html>
#       <head>
#         <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
#         <title>title</title>
#       </head>
#       <body>
#         <div>
#           <p><img src="icon.png" /><br/><span>title</span></p>
#         </div>
#       </body>
#     </html>
#
# オリジナル:
#
#   RubyでHTMLを自動整形する - sdyuki-devel
#   http://d.hatena.ne.jp/sdyuki/20071103/1194071945
#
# 簡単に使うには？
#
#   p HtmlFormatter.parse(File.read("index.html"))
#
# オプションを設定ではなく一部書き換えて実行するには？
#
#   obj = HtmlFormatter.new{|obj|obj.options[:block_tags].delete("li")}
#   p obj.options #=> {...}
#   obj.source = File.read("index.html")
#   p obj.parse #=> "<html>..."
#

require "rubygems"
require "active_support"
require "strscan"

class HtmlFormatter
  class DepthError < StandardError; end

  #
  # 簡単に使うためのインターフェイス
  #
  #   p parse("<html>...</html>") #=> "<html>\n</html>"
  #
  def self.parse(source, options = {}, &block)
    new(source, options, &block).parse
  end

  class << self
    alias run parse
  end

  #
  # 余計なスペースと改行を全削除
  #
  #   p html_pack("<div>\n</div>") #=> "<div></div>"
  #
  def self.html_pack(str)
    str.to_s.gsub(/\s*\n\s*/, "").strip
  end

  #
  # 空行を削除
  #
  #   p delete_blank_lines("<div>\n \n</div>") #=> "<div>\n</div>"
  #
  def self.delete_blank_lines(str)
    str.to_s.gsub(/^\s*?\n/, "")
  end

  attr_reader :options
  attr_accessor :source
  attr_accessor :depth

  def initialize(source = nil, options = {}, &block)
    @source = source
    @options = {
      # 自分の上下で必ず改行されていたいブロック系タグ
      :block_tags         => %w(html head body title div p ul dl li map h1 h2 h3 h4 h5 h6 h7 h8 h9 hr script link area meta),

      # 子要素が必ず次の行に来て欲しいタグ
      :child_open         => %w(html head body div ul dl map),

      # 単体で完結するタグであってもインラインと見なすタグ
      :inline_tags        => %w(img br),

      :indent_width       => 2,     # インデント幅
      :trace              => false, # トレースモード(デバッグ用)
      :html_pack          => true,  # 最初にHTMLの余計な隙間を削除するか？
      :delete_blank_lines => true,  # 最後に空行を除外するか？
    }.merge(options)

    if block_given?
      yield self
    end
  end

  #
  # 整形してHTMLを返す
  #
  def parse
    str = @source
    if @options[:html_pack]
      str = self.class.html_pack(str)
    end
    @scanner = StringScanner.new(str)

    @depth = 0
    @body = ""

    # スペースと > と / 以外のものがタグの名前になる
    # 「スラッシュ以外」を含むのは <br /> でなく <br/> という記述があるため
    while length = @scanner.exist?(/<\/?([^\ >\/]+)[^>]*>/)
      @params = {}
      @params[:all]       = @scanner[0]                                   # タグの全体: <div id="main">
      @params[:name]      = @scanner[1]                                   # タグの名前: div
      @params[:text]      = @scanner.peek(length - @scanner.matched_size) # タグの前にあるテキスト
      @params[:not_close] = !@scanner.matched.match(/\A<\//)              # 閉じタグ以外か？(<!DOCTYPE> 等もここが true になる)
      @params[:only]      = !!@scanner.matched.match(/\/>\z/)             # 一つだけで簡潔しているタグか？
      @params[:doc]       = !!@params[:name].match(/\A!\w+/)              # !DOCTYPE 類か？
      @params[:comment]   = (@params[:name] == "!--")                     # コメントか？
      @params[:block]     = @options[:block_tags].include?(@params[:name])
      @params[:inline]    = @options[:inline_tags].include?(@params[:name])

      if @options[:trace]
        p [@scanner.matched_size, length, @params]
      end

      insert(@params[:text])
      if @params[:comment] || @params[:doc]
        insert_enter
        insert_all
        insert_enter
      elsif @params[:only]  # 単体で完結するタグはデフォルトでブロックと見なす
        if @params[:inline] # 例外として <img src="..." /> や <br/> はインラインと見なす
          insert_all
        else
          insert_enter
          insert_all
          insert_enter
        end
      else
        if @params[:not_close]
          if @params[:block]
            insert_enter
          end
          insert_all
          if child_open?
            insert_enter(1)
          end
        else
          if child_open?
            insert_enter(-1)
          end
          insert_all
          if @params[:block]
            insert_enter
          end
        end
      end
      @scanner.pos += length
    end

    insert(@scanner.rest)
    if @options[:delete_blank_lines]
      @body = self.class.delete_blank_lines(@body)
    end

    @body.strip
  end

  private

  #
  # body や div のように次に必ずリターンを入れるか？
  #
  def child_open?
    @options[:child_open].include?(@params[:name])
  end

  #
  # 現在の深さに対応したインデントの取得
  #
  def indents
    " " * (@options[:indent_width] * @depth)
  end

  #
  # 改行を挿入
  #
  def insert_enter(relative_depth = 0)
    @depth += relative_depth
    if @depth < 0
      raise DepthError, "#{@body}"
    end
    insert("\n#{indents}")
  end

  #
  # マッチしたタグを属性含めて挿入
  #
  def insert_all
    insert(@params[:all])
  end

  #
  # 指定の文字列を挿入
  #
  def insert(str)
    @body << str.to_s
  end
end

if __FILE__ == $PROGRAM_NAME
  # puts HtmlFormatter.parse("<li>X</li>")
  # puts HtmlFormatter.parse("<li><a href='x'><sup>X</sup></a></li>")
  # puts HtmlFormatter.parse("<a href='x'><sup>X</sup></a>")
  # puts HtmlFormatter.parse("<a><sup>X</sup></a>")
  # puts HtmlFormatter.parse("<div id='main'>S<a><span>X</span>A<meta/>B</a>A<!-- X -->B</div>")
  # puts HtmlFormatter.parse("<head><title>X</title><link a='1' /></head>")
  # puts HtmlFormatter.parse("A<p>B<sup>C<meta/>D</sup>E</p>F")
  # puts HtmlFormatter.parse("<!DOCTYPE>a<html>b<head>c</head>d</html>e")
  source = '
    <script type="text/javascript">
      //<![CDATA[
        "a

          b"
      //]]>
    </script>
  '
  puts HtmlFormatter.parse(source, :trace => true, :html_pack => false)
end
