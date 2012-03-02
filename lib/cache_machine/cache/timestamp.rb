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
          CacheMachine::Cache::timestamps_adapter.fetch_timestamp(self.name) { Time.now.to_i.to_s }
        end

        # Resets timestamp of class collection.
        #
        def reset_timestamp
          CacheMachine::Cache::timestamps_adapter.reset_timestamp(self.name)
        end
      end
    end
  end
end
