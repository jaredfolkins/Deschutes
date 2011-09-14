Dir.glob('./storage/txt/*.txt') do |file_pointer|
  file = File.open(file_pointer, "rb")
  date_string_block = file.read.match(/will\sbe\sheld(.*)\n(.*)\n(.*)\n/i)
  #date_regex = /(January|February|March|April|May|June|July|August|September|October|November|December)\s?,?\s?(\d)+\s?,?\s?(\d)+/i
  date_regex = /(\d)+\/(\d)+\/(\d)+/
  unless date_string_block.nil?
    puts "#{file_pointer} #{date_string_block.to_s.match(date_regex)}"
  end
end
