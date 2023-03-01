# frozen_string_literal: true

ENV['RUBY_ENV'] = 'test'

require 'rubygems'
require 'bundler/setup'
require "pry-byebug"
require "mongoid"
require "mongoid-avro"
require "rspec"

Mongoid.load!(
  File.join(Dir.pwd, 'spec', 'config', 'mongoid.yml'),
  ENV['RUBY_ENV'],
)

Bundler.require(:default, :test)

RSpec.configure do |config|
  config.order = :random
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  Mongoid.raise_not_found_error = false
end