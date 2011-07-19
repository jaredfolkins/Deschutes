require 'spec_helper'

describe DeschutesDocument do
  def load_fixture(name)
      File.read(File.join('.', 'spec', 'fixtures', "#{name}.fixture"))
  end

  before(:each) do
    @document = DeschutesDocument.new(load_fixture('record_root'))
    @document.parse
  end

  describe "#verify_or_create_nokogiri_document" do
    it "verifies the document's class is Nokogiri or creates a Nokogiri object" do
      @document.nokogiri_document.should be_a_kind_of(Nokogiri::HTML::Document)
    end
  end

  describe "#parse_and_set_id" do
    it "should set the document id" do
      @document.parse_and_set_id
      @document.id.should_not be_nil
    end
  end

  describe "#parse_and_set_vol" do
    it "should set the document vol" do
      @document.parse_and_set_vol
      @document.vol.should_not be_nil
    end
  end

  describe "#parse_and_set_page" do
    it "should set the document page" do
      @document.parse_and_set_page
      @document.page.should_not be_nil
    end
  end

  describe "#parse_and_set_pdf_url" do
    it "should gather the pdf url and set the class variable" do
      @document.parse_and_set_pdf_url
      @document.pdf_url.should_not be_nil
    end
  end

  describe "#deed?" do
    it "returns true when document is deed" do
      document = DeschutesDocument.new(load_fixture('record_root'))
      document.parse
      document.should_not be_deed
    end

    it "returns true when document is not mortgage" do
      document = DeschutesDocument.new(load_fixture('record_not_root'))
      document.parse
      document.should be_deed
    end
  end

  describe "#parse_and_set_are_referenced" do
    it "parses the document and sets an array of documents that are referenced" do
      document = DeschutesDocument.new(load_fixture('record_not_root'))
    end
  end

  describe "#parse_and_set_type" do
    it "parses the document and sets the document type" do
      @document.parse_and_set_type
      @document.type.should_not be_nil
    end
  end

  describe "#parse_and_set_subtype" do
    it "parses the document and sets the document subtype" do
      @document.parse_and_set_subtype
      @document.subtype.should_not be_nil
    end
  end
end
