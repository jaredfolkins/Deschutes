require './required.rb'

bot = Bot.new
bot.submit_search_form
#page = bot.go_to_page(920850)
page = bot.go_to_page(1426112)
bot.traverse_tree_from_page(page)
