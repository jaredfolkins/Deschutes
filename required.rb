require `gem which memprof/signal`.chomp

require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'yaml'

# required gems
require 'active_record'
require 'mechanize'
require 'nokogiri'
#require 'htmlentities' TODO: confirm application works and remove
require 'mysql'
require 'chronic'

# required files
require'./lib/dbconnection'
require'./lib/bot'
require'./lib/storage'
require'./lib/document'
require'./lib/mortgage_make_reference'
require'./lib/mortgage_deed'
require'./lib/default_sale'
require'./lib/convert'
