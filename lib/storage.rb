class Storage 

  VERY_HEALTHY = 3
  HEALTHY = 2
  POOR = 1
  DEAD = 0

  attr_accessor :nokogiri_document, :are_referenced, :make_reference, :legal_descriptions, :tables, :instrument_id
  attr_accessor :id, :vol, :page, :type, :subtype, :pdf_file, :pdf_url, :recording_date, :subdivision, :lot
  attr_accessor :first_make_reference
  attr_accessor :tables_count

  def initialize(document)
    document = remove_custom_indexes(document)
    @nokogiri_document = verify_or_create_nokogiri_document(document)
    @tables = {}
    @are_referenced = []
    @make_reference = []
  end

  def save_pdf_file
    if @pdf_file.kind_of?(Mechanize::File)
      @pdf_file.save("./storage/pdf/#{@id}.pdf")
    end
  end

  def verify_or_create_nokogiri_document(document)
    document.kind_of?(Nokogiri) ? document.to_s :  Nokogiri::HTML(document.to_s)
  end

  def mortgage?
    unless @are_referenced.nil?
      @are_referenced.last[:document_type].match(/Deed/) ? true : false
    end
  end

  def get_mortgage_instrument_id
    @are_referenced.last[:instrument_id] if mortgage?
  end

  def meta
     "#{@tables_count} || #{@id} || #{@recording_date} || #{@instrument_id} || #{@type} || #{@subtype} || #{@subdivision} || #{@lot}"
  end

  def remove_custom_indexes(document)
    matches = document.match(/(<BR><B><FONT\sCOLOR="gray"\ssize=3>Custom\sIndexes<\/FONT><\/B><BR>.*<\/TABLE>).*<BR><B><FONT\sCOLOR="gray"\ssize=3>The\sfollowing\sdocuments\s<FONT\sCOLOR="red">are\sreferenced/im)
    if matches.nil?
      document
    else
      document.gsub(matches[1], '')
    end
  end

  def parse
    parse_and_set_tables
    if @tables.count > 1
      parse_and_set_are_referenced
      parse_and_set_make_reference
      parse_and_set_id
      parse_and_set_vol
      parse_and_set_page
      parse_and_set_type
      parse_and_set_subtype
      parse_and_set_recording_date
      parse_and_set_pdf_url
      parse_and_set_legal_descriptions
    end
    self
  end

  def parse_and_set_recording_date
    regex = /RECORDING\sDATE:.*<FONT\ssize="2">(\d{1,2})\/(\d{1,2})\/(\d{4})/im
    matches = @tables[:details].to_s.match(regex)
    year = matches[3] unless matches.nil? 
    month = ''
    day = ''

    if matches[2].length == 1
      day = "0#{matches[2]}" unless matches.nil?
    else
      day = matches[2] unless matches.nil? 
    end

    if matches[1].length == 1
      month = "0#{matches[1]}" unless matches.nil?
    else
      month = matches[1] unless matches.nil? 
    end

    @recording_date = "#{year}-#{month}-#{day}" unless matches.nil?

  end

  def parse_and_set_type
    regex = /DOCUMENT\sTYPE:<\/b><\/font><\/td>\n<td><font size="2">(.*)<\/font><\/td>/
    matches = @tables[:details].to_s.match(regex)
    @type = matches[1].gsub(/&#160;/,' ') unless matches.nil?
    @type = @type.gsub(/&amp;/,'&')
    @type = @type.gsub(/&nbsp;/,' ')
  end

  def parse_and_set_subtype
    regex = /DOC\sSUBTYPE:<\/b><\/font><\/td>\n<td><font size="2">(.*)<\/font><\/td>/
    matches = @tables[:details].to_s.match(regex)
    @subtype = matches[1].gsub(/&#160;/,' ') unless matches.nil?
    @subtype = @subtype.gsub(/&amp;/, '&')
    @subtype = @subtype.gsub(/&nbsp;/,' ')
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
      regex = /a\shref="(ViewImage.asp\?INST_ID=\d*&amp;TEMP_ID=\d*&amp;TYPE=PDF)"/i
      matches = @tables[:details].to_s.match(regex)
      @pdf_url = matches[1] unless matches.nil?
    end
  end

  def parse_and_set_legal_descriptions
    @tables[:legal_descriptions].xpath("//table//tr").each do | tr |
      row = {}
      tr.xpath("td").each_with_index do | td , index |
        row[set_legal_descriptions_symbol_on_index(index)] = td.text rescue nil
      end
      @legal_descriptions = row
      @subdivision = row[:subdivision].gsub(/[^0-9A-Za-z\s]/,'')
      @lot = row[:lot].gsub(/[^0-9A-Za-z\s]/,'')
    end
  end

  def parse_and_set_are_referenced
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
    tables = @nokogiri_document.xpath(".//table")
    @tables_count = tables.count
    unless @tables_count > 12
      tables.each_with_index do | table , index |
        if index.odd?
          key = define_key_based_on_index(index)
          noko = Nokogiri::HTML(table.to_s)
          noko.xpath("/html/body/table").each do | table |
            @tables[key] = table
          end
          noko = nil
        end
      end
    end
  end

  def set_legal_descriptions_symbol_on_index(index)
    case index
      when 0 then :subdivision
      when 1 then :lot
      when 2 then :block
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
