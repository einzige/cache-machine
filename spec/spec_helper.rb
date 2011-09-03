require "active_record"
require "rails"
require "logger"
require "rspec"
require "rspec-rails"
require "cache_machine/logging"
require "cache_machine/cache"
require "cache_machine/cache/map"
require "cache_machine"

RSpec.configure { |config| config.mock_with :rspec }

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "db/sqlite3.test.db")
CacheMachine::Logger.level = :info
ActiveRecord::Base.logger = Logger.new(STDOUT)

Object.const_set "RAILS_CACHE", ActiveSupport::Cache.lookup_store(:memory_store) # You can set memcached
