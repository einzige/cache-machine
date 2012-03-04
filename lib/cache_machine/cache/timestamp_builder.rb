module CacheMachine
  module Cache
    module TimestampBuilder
      extend ActiveSupport::Concern

      module ClassMethods

        # Defines timestamp for object.
        #
        # @example Define timestamp to be updated every hour.
        #   class MyModel < ActiveRecord::Base
        #     include CacheMachine::Cache
        #     define_timestamp(:my_timestamp, :expires_in => 1.hour) { my_optional_value }
        #   end
        #
        # @param [ String, Symbol ] timestamp_name
        # @param [ Hash ] options
        def define_timestamp(timestamp_name, options = {}, &block)
          (class << self; self end).send(:define_method, timestamp_name) do

            # Block affecting on timestamp.
            stamp_value = block_given? ? ([*block.call(self)] << 'stamp').join('_') : 'stamp'
            puts stamp_value

            # The key of timestamp itself.
            stamp_key_value = timestamp_key_of("#{timestamp_name}_#{stamp_value}")

            # The key of the key of timestamp.
            stamp_key = timestamp_key_of(timestamp_name)

            # The key of timestamp from the cache (previous value).
            cached_stamp_key_value = CacheMachine::Cache::timestamps_adapter.fetch_timestamp(stamp_key) { stamp_key_value }

            # Timestamp is updated. Delete old key from cache to do not pollute it with dead-keys.
            if stamp_key_value != cached_stamp_key_value
              CacheMachine::Cache::timestamps_adapter.reset_timestamp(cached_stamp_key_value)
            end

            CacheMachine::Cache::timestamps_adapter.fetch_timestamp(stamp_key_value, options) do
              Time.now.to_i.to_s
            end
          end
        end

        # Returns timestamp cache key for anything.
        #
        # @param [ String, Symbol ] anything
        #
        # @return [ String ]
        def timestamp_key_of(anything)
          "#{self.name}~#{anything}~ts"
        end
        alias timestamp_key timestamp_key_of
      end
    end
  end
end

ActiveRecord::Base.send :include, CacheMachine::Cache::TimestampBuilder