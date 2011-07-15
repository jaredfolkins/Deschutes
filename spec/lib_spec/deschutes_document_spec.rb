require 'spec_helper'

describe DeschutesDocument do
  describe "#create_nokogiri_object" do
    it "if supplied document is not a nokogiri object" do
      document = DeschutesDocument.new('<html>')
      document.nokogiri_document.should be_a_kind_of(Nokogiri::HTML::Document)
    end
  end
  describe "#is_root?" do
    it "returns TRUE when document is root" do
      #pending
      #document = DeschutesDocument.new('<html>')
    end
  end
end
