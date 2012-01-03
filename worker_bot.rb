#setup root path
Dir.chdir "#{File.dirname(__FILE__)}"

# setup file of required files
require './required.rb'

#run the bot
Bot.new.run
