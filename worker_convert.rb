#setup root path
Dir.chdir "#{File.dirname(__FILE__)}"

require 'required.rb'

converter = Convert.new
converter.run

