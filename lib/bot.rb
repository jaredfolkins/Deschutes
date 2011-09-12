class Bot

  HOST = 'http://recordings.co.deschutes.or.us/'
  CURRENT_DIR = File.dirname(__FILE__)
  DB_FILE = CURRENT_DIR + '/../db/database.yml'
  BROWSER_LOG_FILE = CURRENT_DIR + "/../log/browser.log"
  BROWSER_TWO_LOG_FILE = CURRENT_DIR + "/../log/browser_two.log"

  attr_reader :browser, :browser_two, :profiler, :image_type

  def initialize
    setup_db
    setup_browser
    @image_type = get_image_type
  end

  def setup_db
    dbconfig = YAML::load(File.open(DB_FILE))
    ActiveRecord::Base.establish_connection(dbconfig)
  end

  def setup_browser
    #@browser = Mechanize.new { |a| a.log = Logger.new(BROWSER_LOG_FILE) }
    #@browser_two = Mechanize.new { |a| a.log = Logger.new(BROWSER_TWO_LOG_FILE) }

    @browser = Mechanize.new
    @browser_two = Mechanize.new

    @browser.max_history = 10
    @browser_two.max_history = 10

    redirect = true
    @browser.redirect_ok = redirect
    @browser_two.redirect_ok = redirect

    agent_alias = "Mac FireFox"

    @browser.user_agent_alias = agent_alias
    @browser_two.user_agent_alias = agent_alias

    headers = {
      'Referer' => 'http://recordings.co.deschutes.or.us/Search.asp',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0) Gecko/20100101 Firefox/4.0',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language' => 'en-us,en;q=0.5',
      'Accept-Encoding' => 'gzip,deflate',
      'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
      'Keep-Alive' => '115',
      'Connection' => 'keep-alive'
    }

    @browser.request_headers = headers
    @browser_two.request_headers = headers

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

  def submit_search_by_subdivision_and_lot(subdivision,lot)
    @browser_two.get(HOST + "Login.asp")
    @browser_two.get(HOST + "Search.asp")
    search_form = @browser_two.page.form("frmMain")
    search_form.cmbDocumentType = 5
    search_form.radiobuttons_with(:name => 'rbOrder')[1].check
    search_form.radiobuttons_with(:name => 'rbDocTypeOpt')[1].uncheck
    search_form.field_with(:name => 'dfSubdivision').value = subdivision
    search_form.field_with(:name => 'dfLegal1').value = lot
    @browser_two.submit(search_form)
  end

  def save_mortgage_deed(mortgage)
    unless mortgage.subdivision.length < 4
      page = submit_search_by_subdivision_and_lot(mortgage.subdivision, mortgage.lot)
      unless no_records_found?(page)
        if search_results_page?(page)
          page.links_with(:href => /Detail.asp\?INSTRUMENT_ID=\d+/).each_with_index do | link, index |
            if index == 0
              matches = link.href.match(/Detail.asp\?INSTRUMENT_ID=(\d+)/)
              instrument_id = matches[1] unless matches.nil?
              body = link.click.body
              document = Storage.new(body)
              document.parse
              document.instrument_id = instrument_id
              unless document.tables_count > 12
                save_deed(document, instrument_id)
                save_mortgage_deed_relation(mortgage, document)
                puts "    |-- #{document.meta}"
              end
            end
          end
        else
          document = Storage.new(page.body)
          document.parse
          puts "    |-- #{document.meta}"
          save_deed(document)
          #todo save_mortage_deed_relation ? needs to be here
        end
      end
    end
  end

  def no_records_found?(page)
    page.body.to_s.match(/No\srecords\sfound/) ? true : false
  end

  def skip_pages(total)
    total.times do
      if next_link?(@browser.page)
        click_next_link(@browser.page)
      else
        puts "You have skipped too far, no more pages!"
      end
    end
  end

  def run_loop
    while next_link?(@browser.page) do
      #Memprof.trace{
        page = @browser.page
        iterate_search_page(page)
        click_next_link(page)
      #}
    end
  end

  def traverse_tree_from_page(body)
      document = Storage.new(body).parse
      if document.tables.count > 1
        puts "\n+ #{document.meta}\n|_"
        mortgage = get_mortgage(document)
        save_mortgage_and_related_documents(mortgage)
        save_related_documents(mortgage)
        save_mortgage_deed(mortgage)
      end
  end

  def iterate_search_page(page)
    page.links_with(:href => /Detail.asp\?INSTRUMENT_ID=\d/).each_with_index do | link, index |
      traverse_tree_from_page(link.click.body)
    end
  end

  def get_mortgage(document)
    unless document.mortgage?
      document
    else
      instrument_id = document.get_mortgage_instrument_id
      mortgage = Storage.new go_to_page(instrument_id)
      mortgage.instrument_id = instrument_id
      mortgage.parse
    end
  end

  def save_mortgage_and_related_documents(mortgage)
    puts "  + #{mortgage.meta}"
    Document.create(
      :volpage => mortgage.id,
      :recording_date => mortgage.recording_date,
      :doctype => mortgage.type,
      :subtype => mortgage.subtype,
      :instrument_id => mortgage.instrument_id) unless Document.exists?(:volpage => mortgage.id)
  end

  def save_related_documents(mortgage)
    unless mortgage.make_reference.nil?
      puts "  |_"
      mortgage.make_reference.each_with_index do | reference, index |
        page = go_to_page(reference[:instrument_id])
        unless page.nil?
          document = Storage.new(page)
          document.instrument_id = reference[:instrument_id]
          document.parse
          puts "    |-- ""#{document.meta}"
          save_and_process_pdf_default_notices(document)
          save_mortgage_make_reference(document, mortgage, index)
          save_document(document, mortgage)
        end
      end
    end
  end

  def define_highest_rank(index)
    index == 0 ? true : false
  end

  def save_document(document,mortgage)
    Document.create(
      :volpage => document.id,
      :recording_date => document.recording_date.to_s,
      :doctype => document.type.to_s,
      :subtype => document.subtype,
      :instrument_id => document.instrument_id) unless Document.exists?(:volpage => document.id)
  end

  def save_deed(document, instrument_id = nil)
    Document.create(
      :volpage => document.id,
      :recording_date => document.recording_date.to_s,
      :doctype => document.type.to_s,
      :subtype => document.subtype,
      :instrument_id => instrument_id) unless Document.exists?(:volpage => document.id)
  end

  def save_mortgage_deed_relation(mortgage,document)
    MortgageDeed.where(:mortgage_volpage => mortgage.id).map(&:destroy)
    MortgageDeed.create(:mortgage_volpage => mortgage.id.to_s, :deed_volpage => document.id.to_s)
  end

  def save_mortgage_make_reference(document, mortgage, rank)
    if MortgageMakeReference.exists?(:mortgage_volpage => mortgage.id.to_s, :document_volpage => document.id.to_s)
      relation = MortgageMakeReference.find_by_mortgage_volpage_and_document_volpage(mortgage.id.to_s, document.id.to_s)
      relation.update_attribute(:rank, rank)
    else
      MortgageMakeReference.create(:mortgage_volpage => mortgage.id.to_s, :document_volpage => document.id.to_s, :rank => rank)
    end
  end

  def save_and_process_pdf_default_notices(document)
    if document.subtype.match(/DEF.-.Notice\sof\sDefault\s&\sElection\sto\sSell/)
      delete_files_from_dirs
      document.pdf_file = get_document_pdf(document.pdf_url)
      document.save_pdf_file
      convert_pdf_to_png(document)
      convert_png_to_txt(document)
      save_pdf_output_to_database(document)
    end
  end

  def click_next_link(page)
    url = page.body.to_s.match(/<a href=(Results\.asp\?START=\d+)>Next/i)
    puts "\n=========NEXT: (#{url}) ==========\n"
    page.link_with(:href => url[1]).click
    url = nil
  end

  def go_to_page(instrument_id)
    begin
      @browser.get(HOST + "Detail.asp?INSTRUMENT_ID=#{instrument_id}")
      @browser.page.body
    rescue
      puts "go_to_page() failed with #{instrument_id}"
      nil
    end
  end

  def search_results_page?(page)
    page.body.to_s.match(/<b>Search\sResults<\/b>/i) ? true : false
  end

  def next_link?(page)
    url = page.body.to_s.match(/<a href=(Results\.asp\?START=\d+)>Next/i)
    page.link_with(:href => url[1]) ? true : false
  end

  def get_document_pdf(pdf_url)
    @browser.get(HOST + pdf_url)
  end

  def convert_pdf_to_png(document)
    tmp_pdf = CURRENT_DIR + "/../storage/pdf/#{document.id}.pdf"
    tmp_image = CURRENT_DIR + "/../storage/tmp/#{document.id}.#{@image_type}"
    system "convert -quiet -density 300 #{tmp_pdf} -depth 16 #{tmp_image} 2>/dev/null"
  end

  def convert_png_to_txt(document)
    tmp_dir = "#{CURRENT_DIR}/../storage/tmp/"
    txt_dir = "#{CURRENT_DIR}/../storage/txt/"
    Dir.glob("#{tmp_dir}*.#{@image_type}") do |file|
      system "tesseract #{file} #{tmp_dir}#{document.id}"
      system "touch #{txt_dir}#{document.id}.txt"
      system "cat #{tmp_dir}#{document.id}.txt >> #{txt_dir}#{document.id}.txt"
    end
  end

  def get_image_type
    os = `uname -a`
    if linux?(os)
      'png'
    elsif mac?(os)
      'tiff'
    end
  end

  def linux?(os)
    os.to_s.match(/Linux/) ? true : false
  end

  def mac?(os)
    os.to_s.match(/Darwin/) ? true : false
  end

  def save_pdf_output_to_database(document)
    txt_dir = "#{CURRENT_DIR}/../storage/txt/"
    File.open("#{txt_dir}#{document.id}.txt", "rb") do | file |
      pdf = Pdf.find_or_initialize_by_volpage(document.id.to_s)
      pdf.update_attributes({ :content => file.read })
    end
  end

  def delete_files_from_dirs
    system "rm -f #{CURRENT_DIR}/../storage/tmp/*"
    system "rm -f #{CURRENT_DIR}/../storage/txt/*"
  end
end
