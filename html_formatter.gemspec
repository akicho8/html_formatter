$:.push File.expand_path("../lib", __FILE__)
require "html_formatter/version"

Gem::Specification.new do |s|
  s.name         = "html_formatter"
  s.version      = HtmlFormatter::VERSION
  s.author       = "akicho8"
  s.email        = "akicho8@gmail.com"
  s.homepage     = "https://github.com/akicho8/html_formatter"
  s.summary      = "htmlnotagnonarabiwototonoemasu"
  s.description  = "htmlnotagnonarabiwototonoemasu"

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables  = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.rdoc_options = ["--line-numbers", "--inline-source", "--charset=UTF-8", "--diagram", "--image-format=jpg"]

  s.add_dependency "activesupport"
  s.add_development_dependency "rspec"
end
