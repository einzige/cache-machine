require "active_record"
require "rails"
require "logger"
require "rspec"
require "rspec-rails"
require "cache-machine"

RSpec.configure { |config| config.mock_with :rspec }

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "db/sqlite3.test.db")

CacheMachine::Logger.level  = :info

Object.const_set "RAILS_CACHE", ActiveSupport::Cache.lookup_store(:memory_store) # You can set memcached

::Rails.cache.clear

ActiveRecord::Base.logger = Logger.new(nil)
CacheMachine::Logger.logger = Logger.new(nil)

require 'fixtures'