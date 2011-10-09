require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

describe HtmlFormatter::CLI do
  it "execute" do
    proc{HtmlFormatter::CLI.execute([])}.should_not raise_error
  end
end
