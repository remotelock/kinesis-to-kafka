require 'bundler'
Bundler.require(:default)
Bundler.require(:development) if ENV['ENV'] == 'development'

require './lib/kinesis_to_kafka'
