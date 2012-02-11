require "active_record"
require "rails"
require "logger"
require "rspec"
require "rspec-rails"
require "cache-machine"

RSpec.configure { |config| config.mock_with :rspec }

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "db/sqlite3.test.db")

CacheMachine::Logger.level  = :info
CacheMachine::Cache.formats = [:ehtml, :json]

if ENV["ADAPTER"] == 'redis'
  url = "redis://zininserge:45fb4685efcf46c383d6938faca50885@carp.redistogo.com:9383/"
  uri = URI.parse(url)
  adapter = CacheMachine::Adapters::Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

  CacheMachine::Cache::map_adapter = adapter
  CacheMachine::Cache::storage_adapter = adapter
  CacheMachine::Cache::timestamps_adapter = adapter

  adapter.redis.flushdb
end

ActiveRecord::Base.logger = Logger.new(nil)

Object.const_set "RAILS_CACHE", ActiveSupport::Cache.lookup_store(:memory_store) # You can set memcached

require 'fixtures'
