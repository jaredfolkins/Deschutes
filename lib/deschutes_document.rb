class DeschutesDocument

  VERY_HEALTHY = 3
  HEALTHY = 2
  POOR = 1
  DEAD = 0

  attr_accessor :nokogiri_document, :are_referenced, :make_reference, :legal_descriptions, :tables, :root

  def initialize(document)
    create_nokogiri_object(document)
  end

  def parses
    parse_and_set_tables
    parse_and_set_are_referenced
    parse_and_set_make_reference
  end

  def create_nokogiri_object(document)
    if document.kind_of? Nokogiri
      @nokogiri_document = document.to_s
    else
      @nokogiri_document = Nokogiri::HTML(document.to_s)
    end
  end

  def is_root?
    @are_referenced.nil? || @are_referenced.count == 0 ? true : false
  end

  def get_root_instrument_id
    @are_referenced.last[:instrument_id]
  end

  def parse_and_set_are_referenced
    @are_referenced = []

    @tables[:are_referenced].xpath("//table//tr").each do | tr |
      row = {}
      tr.xpath("td").each_with_index do | td , index |
        row[set_are_referenced_symbol_on_index(index)] = td.text rescue ''
        regex = /INSTRUMENT_ID=(\d*)/
        if td.to_s.match(regex)
          row[:instrument_id] = td.to_s.match(regex)[1]
        end
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
        if td.to_s.match(regex)
          row[:instrument_id] = td.to_s.match(regex)[1]
        end
      end
      @make_reference << row
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
