require "spec_helper"

module HtmlFormatter
  describe CLI do
    it "execute" do
      proc { CLI.execute([]) }.should_not raise_error
    end
  end
end
