class DeschutesDocument


  VERY_HEALTHY = 3
  HEALTHY = 2
  POOR = 1
  DEAD = 0

  attr_accessor :nokogiri_document, :are_referenced, :make_reference, :legal_descriptions, :tables, :root
  attr_accessor :id, :vol, :page, :type, :subtype, :pdf_url
  attr_accessor :first_make_reference

  def initialize(document)
    @nokogiri_document = verify_or_create_nokogiri_document(document)
  end

  def verify_or_create_nokogiri_document(document)
    document.kind_of?(Nokogiri) ? document.to_s :  Nokogiri::HTML(document.to_s)
  end

  def deed?
    unless @are_referenced.nil?
      @are_referenced.last[:document_type].match(/Deed/) ? true : false
    end
  end

  def get_deed_instrument_id
    @are_referenced.last[:instrument_id] if deed?
  end

  def parse
    parse_and_set_tables
    parse_and_set_are_referenced
    parse_and_set_make_reference
    parse_and_set_id
    parse_and_set_vol
    parse_and_set_page
    parse_and_set_type
    parse_and_set_subtype
    self
  end

  def parse_and_set_type
    regex = /DOCUMENT\sTYPE:<\/b><\/font><\/td>\n<td><font size="2">(.*)<\/font><\/td>/
    matches = @tables[:details].to_s.match(regex)
    @type = matches[1] unless matches.nil?
  end

  def parse_and_set_subtype
    regex = /DOC\sSUBTYPE:<\/b><\/font><\/td>\n<td><font size="2">(.*)<\/font><\/td>/
    matches = @tables[:details].to_s.match(regex)
    @subtype = matches[1] unless matches.nil?
  end

  def parse_and_set_id
    unless @tables[:details].nil?
      regex = /(\d{4}\-\d+)/m
      matches = @tables[:details].to_s.match(regex)
      @id = matches[1] unless matches.nil?
    end
  end

  def parse_and_set_page
    unless @tables[:details].nil?
      regex = /(\d{4})\-\d+/m
      matches = @tables[:details].to_s.match(regex)
      @vol = matches[1] unless matches.nil?
    end
  end

  def parse_and_set_vol
    unless @tables[:details].nil?
      regex = /\d{4}\-(\d+)/m
      matches = @tables[:details].to_s.match(regex)
      @page = matches[1] unless matches.nil?
    end
  end

  def parse_and_set_pdf_url
    unless @tables[:details].nil?
      regex = /a\shref=("ViewImage.asp\?INST_ID=\d*&amp;TEMP_ID=\d*&amp;TYPE=PDF")/i
      matches = @tables[:details].to_s.match(regex)
      @pdf_url = matches[1] unless matches.nil?
    end
  end

  def parse_and_set_are_referenced
    @are_referenced = []

    @tables[:are_referenced].xpath("//table//tr").each do | tr |
      row = {}
      tr.xpath("td").each_with_index do | td , index |
        row[set_are_referenced_symbol_on_index(index)] = td.text rescue ''
        regex = /INSTRUMENT_ID=(\d*)/
        matches = td.to_s.match(regex)
        row[:instrument_id] = matches[1] unless matches.nil?
      end

      @are_referenced << row

      if @are_referenced.last[:instrument_id].nil?
        @are_referenced = nil
      end

    end
  end

  def parse_and_set_make_reference
    @make_reference = []
    @tables[:make_reference].xpath("//table//tr").each do | tr |
      row = {}
      tr.xpath("td").each_with_index do | td , index |
        row[set_are_referenced_symbol_on_index(index)] = td.text rescue ''
        regex = /INSTRUMENT_ID=(\d*)/
        matches = td.to_s.match(regex)
        row[:instrument_id] = matches[1] unless matches.nil?
      end
      @make_reference << row

      if @make_reference.last[:instrument_id].nil?
        @make_reference = nil
      end
    end
  end

  # Method takes a noko giri object 
  # and creates a hash of seperate nokogiri objects 
  # of the tables we need
  def parse_and_set_tables
    @tables = {}
    @nokogiri_document.xpath(".//table").each_with_index do | table , index |
      if index.odd?
        key = define_key_based_on_index(index)
        noko = Nokogiri::HTML(table.to_s)
        noko.xpath("/html/body/table").each do | table |
          @tables[key] = table
        end
      end
    end
  end

  def set_are_referenced_symbol_on_index(index)
    case index
      when 0 then :document_id
      when 1 then :book_page
      when 2 then :document_type
    end
  end

  def define_key_based_on_index(index)
    case index
      when 1 then :details
      when 3 then :return_to
      when 5 then :parties
      when 7 then :legal_descriptions
      when 9 then :are_referenced
      when 11 then :make_reference
    end
  end
end
