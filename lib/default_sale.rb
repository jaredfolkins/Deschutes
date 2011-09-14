class DefaultSales < ActiveRecord::Base

  def parse_date(file)
    target = get_target_date_string(file)
    unless target.nil?
      words = get_date_words(target).to_s
      num = get_date_num(target).to_s
      if words.length > 4
        Chronic::parse words
      elsif num.length > 4
        Chronic::parse num
      end
    end
  end

  def get_target_date_string(file)
    target_date_regex = /will\sbe\sheld(.*)\n(.*)\n(.*)\n/i
    target_date_string = file.read.match(target_date_regex)
  end

  def get_date_words(target)
      date_regex_words = /(January|February|March|April|May|June|July|August|September|October|November|December)\s?,?\s?(\d)+\s?,?\s?(\d)+/i
      target.to_s.match(date_regex_words)
  end

  def get_date_num(target)
      date_regex_num_slash = /(\d)+\/(\d)+\/(\d)+/
      target.to_s.match(date_regex_num_slash)
  end
end
