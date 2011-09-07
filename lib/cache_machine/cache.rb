require "cache_machine/cache/map"

module CacheMachine
  module Cache
    extend ActiveSupport::Concern

    # Supported cache formats. You can add your own.
    FORMATS = [nil, :ehtml, :html, :json, :xml]

    included do
      after_save    { self.class.reset_timestamps }
      after_destroy { self.class.reset_timestamps }
    end

    module ClassMethods
      # Initializes tracking associations to write and reset cache.
      # +associations+ parameter is to represent cache map with hash.
      #
      # ==== Examples
      #   # Cache associated collections
      #   acts_as_cache_machine_for :cats, :dogs
      #
      #   # Cache result of method to be expired when collection changes.
      #   acts_as_cache_machine_for :cats => :cat_ids
      #
      #   # Cache and expire dependent collections (_mouse_ change invalidates all other collection caches by chain)
      #   acts_as_cache_machine_for :mouses => :cats, :cats => [:gods, :bears], :gods, :bears
      def acts_as_cache_machine_for *associations
        include CacheMachine::Cache::Map
        cache_associated(associations)
      end

      # Returns timestamp of class collection.
      def timestamp format = nil
        Rails.cache.fetch(timestamp_key format) { Time.now.to_i.to_s }
      end

      # Returns cache key to fetch timestamp from memcached.
      def timestamp_key format = nil
        [self.name, format, 'timestamp'].join '_'
      end

      # Returns cache key of +anything+ with timestamp attached.
      def timestamped_key format = nil
        [timestamp_key(format), timestamp(format)].join '_'
      end

      # Resets timestamp of class collection.
      def reset_timestamp format = nil
        cache_key = timestamp_key format
        CacheMachine::Logger.info "CACHE_MACHINE (reset_timestamp): deleting '#{cache_key}'."
        Rails.cache.delete(cache_key)
      end

      def reset_timestamps
        FORMATS.each { |format| reset_timestamp format }
      end
    end
  end
end

