require 'rubygems'
require 'bundler/setup'
require 'freeform'
require 'freeform/builder/builders'
require 'freeform/builder/view_helper'
require 'active_model'
require 'rails/all'
require 'rspec/rails'

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

RSpec.configure do |config|
  # some (optional) config here
end