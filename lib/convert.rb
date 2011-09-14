class Convert < Dbconnection

  PDF_STAGING = CURRENT_DIR + "/../storage/convert/pdf/"
  TXT_PATH = CURRENT_DIR + "/../storage/convert/txt/"
  TMP_PATH = CURRENT_DIR + "/../storage/convert/tmp/"

  def run
    setup_db
    Dir.glob("#{CURRENT_DIR}/../storage/pdf/*.pdf") do |path_to_pdf|
      puts path_to_pdf
      delete_files_from_dirs
      volpage = parse_volpage_from_filename(path_to_pdf)
      move_pdf_to_staging(path_to_pdf)
      convert_pdf_to_image(volpage, path_to_pdf)
      convert_image_to_txt(volpage)
      save_txt_output_to_database(volpage)
    end
  end

  def move_pdf_to_staging(path_to_pdf)
    `mv #{path_to_pdf} #{PDF_STAGING}`
  end

  def convert_pdf_to_image(volpage,path_to_pdf)
    pdf = "#{PDF_STAGING}#{volpage}.pdf"
    tmp_image = "#{TMP_PATH}#{volpage}.#{get_image_type}"
    `convert -quiet -density 600 #{pdf} -depth 16 #{tmp_image} 2>/dev/null`
  end

  def convert_image_to_txt(volpage)
    Dir.glob("#{TMP_PATH}*.#{get_image_type}") do |image|
      txt_document = "#{TXT_PATH}#{volpage}.txt"
      `tesseract #{image} #{TMP_PATH}#{volpage}`
      `rm #{txt_document}` if File.exists?(txt_document)
      `touch #{txt_document}`
      `cat #{TMP_PATH}#{volpage}.txt >> #{txt_document}`
    end
  end

  def save_txt_output_to_database(volpage)
    File.open("#{TXT_PATH}#{volpage}.txt", "rb") do | file |
      pdf = DefaultSales.find_or_initialize_by_volpage(volpage)
      sale_date = pdf.parse_date(file)
      pdf.update_attributes({ :sale_date => sale_date })
    end
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
