# setup file of required files
require './required.rb'

bot = DeschutesBot.new
bot.submit_search_form
bot.run_loop
