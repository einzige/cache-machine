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
        # @return [ String ]
        def timestamp
          CacheMachine::Cache::timestamps_adapter.fetch(timestamp_key) { Time.now.to_i.to_s }
        end

        # Returns cache key to fetch timestamp from cache.
        #
        # @return [ String ]
        def timestamp_key
          "#{self.name}_timestamp"
        end

        # Returns cache key of anything with timestamp attached.
        #
        # @example Return timestamped key of the class.
        #   MyActiveRecordClass.timestamped_key
        #
        # @return [ String ]
        def timestamped_key
          "#{timestamp_key}_#{timestamp}"
        end

        # Resets timestamp of class collection.
        #
        def reset_timestamp
          cache_key = timestamp_key
          CacheMachine::Logger.info "CACHE_MACHINE (reset_timestamp): deleting '#{cache_key}'."
          CacheMachine::Cache::timestamps_adapter.reset_timestamp(cache_key)
        end
      end
    end
  end
end
