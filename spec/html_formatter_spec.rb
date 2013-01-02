# -*- coding: utf-8 -*-
require "spec_helper"

module HtmlFormatter
  describe Parser do
    describe "initialize" do
      it { Parser.new.should be_an_instance_of(Parser) }
      it { Parser.new("", {}, &proc{}).should be_an_instance_of(Parser) }
      it { Parser.new{|obj|obj.options}.should be_an_instance_of(Parser) }
      it { Parser.new("").should be_an_instance_of(Parser) }
    end

    describe "class_parse" do
      it { Parser.parse("<html></html>").should == "<html>\n</html>" }
      it { Parser.parse("<span>text</span>").should == "<span>text</span>" }
      it { Parser.parse("<div><p>").should == "<div>\n  <p>" }
      it { Parser.parse("<body><div><p>text</p></div><body>").should == "<body>\n  <div>\n    <p>text</p>\n  </div>\n  <body>" }
      it { Parser.parse("1<br />2").should == "1<br />2" }
      it { Parser.parse("1<br>2<br/>3<br />4").should == "1<br>2<br/>3<br />4" }
      it { Parser.parse("1<img src=\"rails.png\" />2").should == "1<img src=\"rails.png\" />2" }
      it { Parser.parse("1<!-- c -->2").should == "1\n<!-- c -->\n2" }
      it { Parser.parse("<!doctype html>").should == "<!doctype html>" }
      it { Parser.parse("<!doctype html><!doctype html>").should == "<!doctype html>\n<!doctype html>" }
    end

    it "run" do
      Parser.run("<div></div>").should == "<div>\n</div>"
    end

    it "dirty_html" do
      input = '
<!DOCTYPE><!DOCTYPE>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="description" />
    <title>(title)</title>
    <link href="style.css" rel="stylesheet" type="text/css" media="all" />
  </head>
  <body class="main">
    A<p>B<!-- C -->D<span>E<img src="F" />G<!-- H -->I</span>J<!-- K -->L</p>M
    <div class="paging">
      N<p>O<img src="rails.png" />P<br/><br></br><a href="foo.html">Q</a>R</p>S
    T</div>U
  </body>
</html>
  '
      excepted = '
<!DOCTYPE>
<!DOCTYPE>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="description" />
    <title>(title)</title>
    <link href="style.css" rel="stylesheet" type="text/css" media="all" />
  </head>
  <body class="main">
    A
    <p>B
    <!-- C -->
    D<span>E<img src="F" />G
    <!-- H -->
    I</span>J
    <!-- K -->
    L</p>
    M
    <div class="paging">
      N
      <p>O<img src="rails.png" />P<br/><br></br><a href="foo.html">Q</a>R</p>
      ST
    </div>
    U
  </body>
</html>
'.strip
      Parser.parse(input).should == excepted
    end

    it "script" do
      input = '
<!doctype html>
<html>
  <head>
    <script src="prototype.js" type="text/javascript"></script>
    <script src="jquery-1.4.2.js" type="text/javascript"></script>
  </head>
  <body>
    <script type="text/javascript">
      //<![CDATA[
        jQuery.noConflict();
        (function($){
          $(document).ready(function(){

            $("#main").text("サンプル");
          });
        })(jQuery);
      //]]>
    </script>
               <div id="main"></div>
  </body>
</html>
  '
      excepted = '
<!doctype html>
<html>
  <head>
    <script src="prototype.js" type="text/javascript"></script>
    <script src="jquery-1.4.2.js" type="text/javascript"></script>
  </head>
  <body>
    <script type="text/javascript">
      //<![CDATA[
        jQuery.noConflict();
        (function($){
          $(document).ready(function(){
            $("#main").text("サンプル");
          });
        })(jQuery);
      //]]>
    </script>
    <div id="main">
    </div>
  </body>
</html>
'.strip
      Parser.parse(input, :html_pack => false).should == excepted
    end
  end
end
