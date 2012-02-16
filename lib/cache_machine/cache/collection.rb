module CacheMachine
  module Cache
    module Collection
      extend ActiveSupport::Concern
      DEFAULT_DEPENDENCY_OPTIONS = { :on => :after_save }

      module ClassMethods
        def register_cache_dependency(klass, collection_name, options = {})
          options.reverse_merge!(CacheMachine::Cache::Collection::DEFAULT_DEPENDENCY_OPTIONS)

          #collection_klass.register_cache_dependency @cache_resource, collection_name, { :scope   => options[:scope],
          #                                                                               :members => collection_members,
          #                                                                               :on      => options[:on] }

          # Add callback to reset cache when self is updated/(use options[:on])
          # Add members here to reset the cache
          # Add scope to cattr_accessor
          #
        end
      end
    end
  end
end