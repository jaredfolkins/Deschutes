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
require_relative 'lib/bot'
require_relative 'lib/storage'
require_relative 'lib/document'
require_relative 'lib/mortgage_make_reference'
require_relative 'lib/mortgage_deed'
require_relative 'lib/pdf'
