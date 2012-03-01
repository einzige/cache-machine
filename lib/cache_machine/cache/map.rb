module CacheMachine
  module Cache
    require 'cache_machine/cache/mapper'

    class Map
      cattr_accessor :registered_models
      self.registered_models = []

      cattr_accessor :registered_maps
      self.registered_maps = []

      # Draws cache dependency graph.
      #
      # @return [ nil ]
      def draw(&block)
        self.class.registered_maps << block
        nil
      end

      # Fills association map in cache.
      #
      # @param [ Class ] resource
      def self.fill_associations_map(resource)
        resource.find_each do |instance|
          resource.cached_collections.each do |collection_name|
            CacheMachine::Cache::map_adapter.association_ids(instance, collection_name)
            association_class = resource.reflect_on_association(collection_name).klass
            association_class.find_each do |associated_instance|
              CacheMachine::Cache::map_adapter.reverse_association_ids(resource, collection_name, associated_instance)
            end
          end
        end
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
          CacheMachine::Cache::storage_adapter.delete_content(key)

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
        CacheMachine::Cache::storage_adapter.delete_content(key)
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
