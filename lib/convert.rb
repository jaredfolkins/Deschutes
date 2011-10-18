class Convert < Dbconnection

  PDF_STAGING = CURRENT_DIR + "/../storage/convert/pdf/"
  TXT_PATH = CURRENT_DIR + "/../storage/convert/txt/"
  TMP_PATH = CURRENT_DIR + "/../storage/convert/tmp/"
  FAIL_PATH = CURRENT_DIR + "/../storage/convert/fail/"
  DPI = [150, 300, 450, 600]

  attr_accessor :total_documents, :total_successes

  def run
    @total_documents = 0
    @total_successes = 0
    setup_db
    if confirm_single_process
      convert!
    end
  end

  #TODO I probably should do something with File.flock() here
  def confirm_single_process
    #basically, we should only be seeing the current running process, any more, and we want to quit
    match = `ps -ef | pgrep -fl worker_[c]onvert.rb | wc -l`.match(/\s*(1)\s*/)
    unless match.nil?
      match[1] == '1' ? true : false
    end
  end

  def convert!
    Dir.glob("#{CURRENT_DIR}/../storage/pdf/*.pdf") do |path_to_pdf|
      delete_files_from_dirs
      volpage = parse_volpage_from_filename(path_to_pdf)
      puts "\nVolpage: #{volpage} || Percentage: #{percent_of} || Documents: #{@total_documents} || Successes: #{@total_successes}"
      move_pdf_to_staging(path_to_pdf)
      conversion_and_parsing_chain(volpage, path_to_pdf)
    end
  end

  def conversion_and_parsing_chain(volpage, path_to_pdf)
    sale_date = nil
    DPI.each_with_index do |dpi, index|
      index += 1
      convert_pdf_to_image(dpi, volpage, path_to_pdf)
      convert_image_to_txt(volpage)
      sale_date = parse_and_get_date_from_file(volpage)
      status = sale_date.nil? ? 'Fail   ' : 'Success'
      puts "Pass: #{index} || Status: #{status} || File: #{volpage}.pdf || Dpi: #{dpi} || Date: #{sale_date}"
      break unless sale_date.nil?
    end

    unless sale_date.nil?
      @total_documents += 1
      @total_successes += 1
      save_default_sale(volpage, sale_date)
    else
      @total_documents += 1
      move_pdf_to_fail(volpage)
    end
  end

  def percent_of
    percentage = @total_successes.to_f / @total_documents.to_f * 100.0
    percentage.to_s[0..1] + "%"
  end

  def move_pdf_to_fail(volpage)
    `mv #{PDF_STAGING}#{volpage}.pdf #{FAIL_PATH}#{volpage}.pdf`
  end

  def move_pdf_to_staging(path_to_pdf)
    `mv #{path_to_pdf} #{PDF_STAGING}`
  end

  def convert_pdf_to_image(dpi, volpage, path_to_pdf)
    pdf = "#{PDF_STAGING}#{volpage}.pdf"
    tmp_image = "#{TMP_PATH}#{volpage}.#{get_image_type}"
    `convert -quiet -density #{dpi.to_s} #{pdf} -depth 16 #{tmp_image} 2>/dev/null`
  end

  def convert_image_to_txt(volpage)
    Dir.glob("#{TMP_PATH}*.#{get_image_type}") do |image|
      txt_document = "#{TXT_PATH}#{volpage}.txt"
      `tesseract #{image} #{TMP_PATH}#{volpage} > /dev/null 2>&1`
      `rm #{txt_document}` if File.exists?(txt_document)
      `touch #{txt_document}`
      `cat #{TMP_PATH}#{volpage}.txt >> #{txt_document}`
    end
  end

  def parse_and_get_date_from_file(volpage)
    File.open("#{TXT_PATH}#{volpage}.txt", "rb") do | file |
      DefaultSales::parse_date(file)
    end
  end
  def save_default_sale(volpage, sale_date)
    default_sale = DefaultSales.find_or_initialize_by_volpage(volpage)
    default_sale.update_attributes({ :sale_date => sale_date })
  end

  def parse_volpage_from_filename(filename)
    matches = filename.match(/(\d+\-\d+)\.pdf/)
    unless matches[1].nil?
      matches[1]
    end
  end

  def delete_files_from_dirs
    `rm -f #{TMP_PATH}*`
  end

  def get_image_type
    os = `uname -a`
    if linux?(os)
      'tiff'
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
end
