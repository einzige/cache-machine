require "cache_machine/cache/map"

module CacheMachine
  module Cache
    extend ActiveSupport::Concern

    # Enable cache by default.
    @enabled = true

    # Supported by default cache formats.
    @formats = [nil, :ehtml, :html, :json, :xml]

    # Returns if cache is enabled.
    #
    # @return [ false, true ]
    def self.enabled?
      @enabled
    end

    # Returns currently set formats.
    #
    # @return [Array<Symbol>]
    def self.formats
      @formats
    end

    # Enables/disables cache.
    #
    # @param [ false, true ] is_enabled
    def self.enabled= is_enabled
      @enabled = is_enabled
    end

    # Sets default formats.
    #
    # @note Empty format entry will always be present.
    #
    # @param [ Array<Symbol> ] formats
    def self.formats= formats
      @formats = [nil] | [*formats]
    end

    included do
      after_save    { self.class.reset_timestamps }
      after_destroy { self.class.reset_timestamps }
    end

    module ClassMethods

      # Initializes tracking associations to write and reset cache.
      #
      # @example Cache associated collections.
      #   acts_as_cache_machine_for :cats, :dogs
      # @example Cache result of method to be expired when collection changes.
      #   acts_as_cache_machine_for :cats => :cat_ids
      # @example Cache and expire dependent collections (_mouse_ change invalidates all other collection caches by chain)
      #   acts_as_cache_machine_for :mouses => :cats, :cats => [:dogs, :bears], :dogs, :bears
      #
      # @param [ Hash<Symbol, Array> ] associations Cache Map
      def acts_as_cache_machine_for *associations
        Time.zone ||= ActiveSupport::TimeZone[0]

        include CacheMachine::Cache::Map
        cache_associated(associations)
      end
      alias :cache_map :acts_as_cache_machine_for

      # Returns timestamp of class collection.
      #
      # @example Return timestamp of the class.
      #   MyActiveRecordClass.timestamp
      #
      # @param [ Symbol ] format
      #
      # @return [ String ]
      def timestamp format = nil
        Rails.cache.fetch(timestamp_key format) { Time.now.to_i.to_s }
      end

      # Returns cache key to fetch timestamp from memcached.
      #
      # @param [ Symbol ] format
      #
      # @return [ String ]
      def timestamp_key format = nil
        [self.name, format, 'timestamp'].join '_'
      end

      # Returns cache key of anything with timestamp attached.
      #
      # @example Return timestamped key of the class.
      #   MyActiveRecordClass.timestamped_key
      #
      # @param [Symbol] format
      #
      # @return [ String ]
      def timestamped_key format = nil
        [timestamp_key(format), timestamp(format)].join '_'
      end

      # Resets timestamp of class collection.
      #
      # @param [ Symbol ] format
      def reset_timestamp format = nil
        cache_key = timestamp_key format
        CacheMachine::Logger.info "CACHE_MACHINE (reset_timestamp): deleting '#{cache_key}'."
        Rails.cache.delete(cache_key)
      end

      # Resets all timestams for all formats.
      def reset_timestamps
        CacheMachine::Cache.formats.each { |format| reset_timestamp format }
      end
    end
  end
end

