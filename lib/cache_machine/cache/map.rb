module CacheMachine
  module Cache
    require 'cache_machine/cache/mapper'

    class Map

      # Draws cache dependency graph.
      #
      # @return [ nil ]
      def draw(&block)
        Mapper.new.instance_eval(&block)
        nil
      end

      # Returns cache key for cache resource.
      #
      # @param [ Class ] resource
      # @param [ String, Numeric ] id
      # @param [ String, Symbol ] member
      #
      # @return [ String ]
      def self.resource_cache_key(resource, id, member)
        "#{resource}##{id}:#{member}"
      end

      # Returns timestamp key for cache resource.
      #
      # @param [ Class ] resource
      # @param [ String, Numeric ] id
      # @param [ String, Symbol ] member
      #
      # @return [ String ]
      def self.timestamp_key(resource, id, member)
        "#{resource}##{id}:#{member}_timestamp"
      end

      # Returns cache key for cache resource.
      #
      # @param [ Class ] resource
      # @param [ String, Numeric ] id
      # @param [ String, Symbol ] member
      #
      # @return [ String ]
      def self.timestamped_resource_member_key(resource, id, member, timestamp)
        key = timestamp_key(resource, id, member)
        collection_timestamp = CacheMachine::Cache::timestamps_adapter.fetch_timestamp(key) { Time.now.to_i.to_s }
        "#{key}_#{collection_timestamp}_#{timestamp}"
      end

      # Returns cache key for cache resource.
      #
      # @param [ Class ] resource
      # @param [ String, Numeric, Array ] id
      # @param [ String, Symbol ] member
      #
      # @return [ String ]
      def self.reset_cache_on_map(resource, ids, member)
        [*ids].each do |id|
          key = resource_cache_key(resource, id, member)
          CacheMachine::Logger.info "Deleting cache by map: #{key}"
          CacheMachine::Cache::storage_adapter.delete(key)

          key = timestamp_key(resource, id, member)
          CacheMachine::Logger.info "CACHE_MACHINE (reset_timestamp_of): deleting '#{key}'."
          CacheMachine::Cache::timestamps_adapter.reset_timestamp(key)
        end
      end

      # Returns cache key for cache resource.
      #
      # @param [ Class ] resource
      # @param [ String, Numeric, Array ] id
      # @param [ String, Symbol ] member
      #
      # @return [ String ]
      def self.reset_resource_cache(resource, id, member)
        key = resource_cache_key(resource, id, member)
        CacheMachine::Logger.info "Deleting cache by map: #{key}"
        CacheMachine::Cache::storage_adapter.delete(key)
      end

      # Returns cache key for cache resource.
      #
      # @param [ Class ] resource
      # @param [ String, Numeric, Array ] id
      # @param [ String, Symbol ] member
      #
      # @return [ String ]
      def self.reset_resource_timestamp(resource, id, member)
        key = timestamp_key(resource, id, member)
        CacheMachine::Logger.info "CACHE_MACHINE (reset_timestamp_of): deleting '#{key}'."
        CacheMachine::Cache::timestamps_adapter.reset_timestamp(key)
      end
    end
  end
end
