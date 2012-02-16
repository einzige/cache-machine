module CacheMachine
  module Cache
    module Timestamp
      extend ActiveSupport::Concern

      included do
        after_destroy { self.class.reset_timestamp }
        after_save    { self.class.reset_timestamp }
      end

      module ClassMethods

        # Returns timestamp of class collection.
        #
        # @example Return timestamp of the class.
        #   MyActiveRecordClass.timestamp
        #
        # @param [ Symbol ] format
        #
        # @return [ String ]
        def timestamp(format = nil)
          CacheMachine::Cache::timestamps_adapter.fetch(timestamp_key format) { Time.now.to_i.to_s }
        end

        # Returns cache key to fetch timestamp from cache.
        #
        # @param [ Symbol ] format
        #
        # @return [ String ]
        def timestamp_key(format = nil)
          [self.name, format, 'timestamp'].compact.join '_'
        end

        # Returns cache key of anything with timestamp attached.
        #
        # @example Return timestamped key of the class.
        #   MyActiveRecordClass.timestamped_key
        #
        # @param [Symbol] format
        #
        # @return [ String ]
        def timestamped_key(format = nil)
          [timestamp_key(format), timestamp(format)].join '_'
        end

        # Resets timestamp of class collection.
        #
        # @param [ Symbol ] format
        def reset_timestamp(format = nil)
          cache_key = timestamp_key format
          CacheMachine::Logger.info "CACHE_MACHINE (reset_timestamp): deleting '#{cache_key}'."
          CacheMachine::Cache::timestamps_adapter.delete(cache_key)
        end
      end
    end
  end
end