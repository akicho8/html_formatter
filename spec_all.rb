Dir[File.expand_path(File.join(File.dirname(__FILE__), "spec/*_spec.rb"))].each{|filename|load(filename)}
