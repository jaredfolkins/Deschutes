class BendMaps

  URI = 'http://www.bendmaps.com/dialvolpage.php?vol_page='

  attr_accessor :browser

  def initialize
    setup_browser
  end

  def setup_browser
    @browser = Mechanize.new
    @browser.max_history = 10
  end

  def retrieve_address(volpage)
    @browser.get(URI + volpage)
    response = save_dial_record(@browser.page.body, volpage)
  end

  def save_dial_record(body, volpage)
    unless body.nil?
      DialRecord.create(
        :volpage => volpage,
        #:address => TODOARDDRESS <---
        :account_number => mortgage.instrument_id) unless DialRecord.exists?(:volpage => mortgage.id)
    end
  end

  def parse_response

  end
end
