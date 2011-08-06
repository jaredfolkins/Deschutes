require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'yaml'

# required gems
require 'active_record'
require 'mechanize'
require 'nokogiri'
require 'htmlentities'
require 'mysql'

# required files
require'./lib/bot'
require'./lib/storage'
require'./lib/document'
require'./lib/mortgage_make_reference'
require'./lib/mortgage_deed'
require'./lib/pdf'
