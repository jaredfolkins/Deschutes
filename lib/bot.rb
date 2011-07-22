class Bot

  HOST = 'http://recordings.co.deschutes.or.us/'

  @browser

  def initialize
    setup_db
    setup_browser
  end

  def setup_db
    dbconfig = YAML::load(File.open('./db/database.yml'))
    ActiveRecord::Base.establish_connection(dbconfig)
  end

  def setup_browser
    @browser = Mechanize.new { |a| a.log = Logger.new("./log/mechanize.log") }
    @browser.redirect_ok = true
    @browser.user_agent_alias = 'Mac FireFox'
    @browser.request_headers = {
      'Referer' => 'http://recordings.co.deschutes.or.us/Search.asp',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0) Gecko/20100101 Firefox/4.0',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language' => 'en-us,en;q=0.5',
      'Accept-Encoding' => 'gzip,deflate',
      'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
      'Keep-Alive' => '115',
      'Connection' => 'keep-alive'
    }
  end

  # In order for your cookie to be set correctly
  # You first have to call /Login.asp
  def emulate_javascript_set_cookie
    @browser.get(HOST + "Login.asp")
    @browser.get(HOST + "Search.asp")
  end

  def submit_search_form
    emulate_javascript_set_cookie
    search_form = @browser.page.form("frmMain")
    search_form.cmbTypeGroups = 1
    search_form.radiobuttons_with(:name => 'rbDocTypeOpt')[1].check
    search_form.radiobuttons_with(:name => 'rbOrder')[1].check
    search_form.radiobuttons_with(:name => 'rbNameType')[1].check
    @browser.submit(search_form)
  end

  def run_loop
    while next_link?(@browser.page) do
      page = @browser.page
      iterate_search_page(page)
      click_next_link(page)
    end
  end

  def iterate_search_page(page)
    page.links_with(:href => /Detail.asp\?INSTRUMENT_ID=\d/).each do | link |
      document = Storage.new(link.click.parser)
      document.parse
      deed = get_deed(document)
      save_deed_and_related_documents(deed)
    end
  end

  def get_deed(document)
    unless document.deed?
      document
    else
      instrument_id = document.get_deed_instrument_id
      deed = Storage.new go_to_page(instrument_id)
      deed.instrument_id = instrument_id
      deed.parse
    end
  end

  def save_deed_and_related_documents(deed)
    puts "+ #{deed.meta}"
    save_related_documents(deed)
    Document.create(:volpage => deed.id, :created => deed.recording_date, :doctype => deed.type, :subtype => deed.subtype, :instrument_id => deed.instrument_id) unless Document.exists?(:volpage => deed.id)
  end

  def save_related_documents(deed)
    unless deed.make_reference.nil?
      puts "|_"
      deed.make_reference.each_with_index do | reference, index |

        document = Storage.new(go_to_page(reference[:instrument_id]))
        document.instrument_id = reference[:instrument_id]
        document.parse
        puts "  |-- ""#{document.meta}"

        highest_rank = false
        if index == 0
          highest_rank = true
        end

        if document.subtype.match(/DEF.-.Notice\sof\sDefault\s&\sElection\sto\sSell/)
          delete_files_from_dirs
          document.pdf_file = get_document_pdf(document.pdf_url)
          document.save_pdf_file
          convert_pdf_to_png(document)
          convert_png_to_txt(document)
          save_pdf_output_to_database(document)
        end

        if Relation.exists?(:deed_volpage => deed.id.to_s, :document_volpage => document.id.to_s)  
          relation = Relation.find_by_deed_volpage_and_document_volpage(deed.id.to_s, document.id.to_s)
          relation.update_attribute(:highest_rank, highest_rank)
        else
          Relation.create(:deed_volpage => deed.id.to_s, :document_volpage => document.id.to_s, :highest_rank => highest_rank)        
        end 
        string = document.type
        Document.create(
          :volpage => document.id, 
          :created => document.recording_date.to_s, 
          :doctype => document.type.to_s, 
          :subtype => document.subtype, 
          :instrument_id => document.instrument_id) unless Document.exists?(:volpage => deed.id)
      end
    end
  end

  def click_next_link(page)
    puts "\n===========NEXT=============\n"
    url = page.parser.to_s.match(/<a href="(Results\.asp\?START=\d+)">Next\s\d+<\/a>/)
    page.link_with(:href => url[1]).click
  end

  def go_to_page(instrument_id)
    uri  = HOST + "Detail.asp?INSTRUMENT_ID=#{instrument_id}"
    @browser.get(uri)
    @browser.page.parser
  end

  def next_link?(page)
    url = page.parser.to_s.match(/<a href="(Results\.asp\?START=\d+)">Next\s\d+<\/a>/)
    page.link_with(:href => url[1]) ? true : false
  end

  def get_document_pdf(pdf_url)
    @browser.get(HOST + pdf_url)
  end
  
  def convert_pdf_to_png(document)
    system "convert -quiet -density 300 ./tmp/#{document.id}.pdf -depth 8 ./tmp/#{document.id}.png 2>/dev/null"
  end

  def convert_png_to_txt(document)
    Dir.glob("./tmp/*.png") do |file|
      system "tesseract #{file} ./tmp/#{document.id}"
      system "touch ./storage/txt/#{document.id}.txt"
      system "cat ./tmp/#{document.id}.txt >> ./storage/txt/#{document.id}.txt"
    end
  end

  def save_pdf_output_to_database(document)
    File.open("./storage/txt/#{document.id}.txt", "rb") do | file |
      Pdf.create(:volpage => document.id.to_s, :content => file.read) unless Pdf.exists?(:volpage => document.id.to_s)
    end
  end
  
  def delete_files_from_dirs
    system "rm ./tmp/*"    		
    system "rm ./storage/txt/*"    		
  end
end
