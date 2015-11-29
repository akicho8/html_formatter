require "spec_helper"

RSpec.describe HtmlFormatter::CLI do
  it "execute" do
    proc { HtmlFormatter::CLI.execute([]) }.should_not raise_error
  end
end
