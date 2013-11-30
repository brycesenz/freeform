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
spec = Gem::Specification.find_by_name("freeform")
gem_root = spec.gem_dir
Dir[("#{gem_root}/spec/support/**/*.rb")].each {|f| require f}

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
Rails.backtrace_cleaner.remove_silencers!

RSpec.configure do |config|
  # some (optional) config here
end