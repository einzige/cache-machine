require "cache_machine/adapters/rails"
require "cache_machine/adapters/redis"
require "cache_machine/cache/map"

module CacheMachine
  module Cache

    # Returns adapter used for storing maps of cache.
    #
    # @return [CacheMachine::Adapter]
    def self.map_adapter
      @map_adapter ||= CacheMachine::Adapters::Rails.new
    end

    # Sets adapter used for storing maps of cache.
    #
    # @param [CacheMachine::Adapter]
    def self.map_adapter=(adapter)
      @map_adapter = adapter
    end

    # Returns adapter used for storing content being cached.
    #
    # @return [CacheMachine::Adapter]
    def self.storage_adapter
      @storage_adapter ||= CacheMachine::Adapters::Rails.new
    end

    # Sets adapter used for storing content being cached.
    #
    # @param [CacheMachine::Adapter]
    def self.storage_adapter=(adapter)
      @storage_adapter = adapter
    end

    # Returns adapter used for storing content being cached.
    #
    # @return [CacheMachine::Adapter]
    def self.timestamps_adapter
      @timestamps_adapter ||= CacheMachine::Adapters::Rails.new
    end

    # Sets adapter used for storing content being cached.
    #
    # @param [CacheMachine::Adapter]
    def self.timestamps_adapter=(adapter)
      @timestamps_adapter = adapter
    end
  end
end