#setup root path
Dir.chdir "#{File.dirname(__FILE__)}"

require './required.rb'

#run the converter
Convert.new.run

