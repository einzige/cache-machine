module CacheMachine
  module Cache
    module Scope
      extend ActiveSupport::Concern

      included do
        cattr_accessor :cache_scopes
        self.cache_scopes = []
      end

      module ClassMethods

        # Returns scope used for cache-map defined for this class.
        #
        # @return [ ActiveRecord::Relation ]
        def under_cache_scopes
          result = self.scoped
          [*self.cache_scopes].each { |scope| result = result.send(scope) }
          result
        end
      end
    end
  end
end