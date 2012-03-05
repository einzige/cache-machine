module CacheMachine
  module Helpers
    module CacheHelper

      # Returns cached content for your views.
      #
      # @example Return html from cache.
      #   = cache_for @instance, :association do
      #     %div= @instance.associated_records
      #
      # @param [ ActiveRecord::Base ] record
      # @param [ Symbol ] cacheable
      # @param [ Hash ] options
      #
      # @return [ String ]
      def cache_for(record, cacheable, options = {}, &block)
        record.fetch_cache_of(cacheable, options) { capture &block }
      end
    end
  end
end
