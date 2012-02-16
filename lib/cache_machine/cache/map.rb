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

      # Returns cache key for cache resource.
      #
      # @param [ Class ] resource
      # @param [ String, Numeric, Array ] id
      # @param [ String, Symbol ] member
      #
      # @return [ String ]
      def self.reset_cache_on_map(resource, ids, member)
        [*ids].each do |id|
          CacheMachine::Cache::storage_adapter.delete(resource_cache_key(resource, id, member))
        end
      end
    end
  end
end
