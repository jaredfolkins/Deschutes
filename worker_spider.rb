# setup file of required files
require './required.rb'

bot = Bot.new
bot.submit_search_form
#bot.skip_pages(88)
bot.run_loop
