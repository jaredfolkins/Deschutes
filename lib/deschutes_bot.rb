class DeschutesBot

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

  def emulate_javascript_set_cookie
    host = 'http://recordings.co.deschutes.or.us/'
    # In order for your cookie to be set correctly
    # You first have to call /Login.asp
    @browser.get(host + 'Login.asp')
    # Then call /Search.asp
    @browser.get(host + 'Search.asp')
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
      document = DeschutesDocument.new(link.click.parser)
      document.parse
      deed = get_deed(document)
      save_deed_and_related_documents(deed)
    end
  end

  def get_deed(document)
    unless document.deed?
      document
    else
      deed = DeschutesDocument.new go_to_page(document.get_deed_instrument_id)
      deed.parse
    end
  end

  def save_deed_and_related_documents(deed)
    puts "+ #{deed.meta}"
    save_related_documents(deed)
    #deed.save
  end

  def save_related_documents(deed)
    unless deed.make_reference.nil?
      puts "|_"
      deed.make_reference.each_with_index do | reference, index |
        deed.first_make_reference = reference[:document_id] if index == 0
        document = DeschutesDocument.new(go_to_page(reference[:instrument_id]))
        document.parse
        document.pdf_file = get_document_pdf(document.pdf_url)
        document.save_pdf_file
        puts "  |-- ""#{document.meta}"
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
end
