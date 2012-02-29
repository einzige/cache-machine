module CacheMachine
  module Cache
    module Collection
      extend ActiveSupport::Concern

      DEFAULT_DEPENDENCY_OPTIONS = { :on => :after_save, :scope => :scoped }

      included do
        include CacheMachine::Cache::Associations

        cattr_accessor :cache_map_members
        self.cache_map_members = {}


        # Updates cache of the related resources.
        #
        # @param [ Class ] cache_resource
        def update_resource_collections_cache!(cache_resource)
          self.class.cache_map_members[cache_resource].each do |collection_name, options|
            ((options[:members].try(:keys) || []) << collection_name).each do |member|  # FIXME: use with options and formats
              cache_map_ids = CacheMachine::Cache::map_adapter.reverse_association_ids(self, cache_resource, collection_name)
              CacheMachine::Cache::Map.reset_cache_on_map(cache_resource, cache_map_ids, member)
            end
          end
        end

        # Updates cache of the related resource.
        #
        # @param [ Class ] cache_resource
        def update_dependent_cache!(cache_resource = nil)
          if cache_resource
            update_resource_collections_cache!(cache_resource)
          else
            self.class.cache_map_members.keys.each &:update_resource_collections_cache!
          end
        end

        # Returns all ids from resource associated with this collection member.
        #
        # @param [ Class ] cache_resource
        # @param [ String, Symbol ] collection_name
        #
        # @return [ Array ]
        def cache_map_ids(cache_resource, collection_name)
          pk                  = self.class.primary_key.to_sym
          resource_table_name = cache_resource.table_name
          resource_pk         = cache_resource.primary_key.to_sym

          cache_resource.joins(collection_name).
              where(collection_name => { pk => self.send(pk) }).
              select("#{resource_table_name}.#{resource_pk}").to_a.map &resource_pk
        end
      end

      module ClassMethods

        # Builds cache dependency.
        #
        # @param [ Class ] cache_resource
        # @param [ String, Symbol ] collection_name
        # @param [ Hash ] options
        def register_cache_dependency(cache_resource, collection_name, options = {})
          return if self.cache_map_members[cache_resource].try('[]', collection_name)

          options.reverse_merge!(CacheMachine::Cache::Collection::DEFAULT_DEPENDENCY_OPTIONS)

          # Save dependency options.
          (self.cache_map_members[cache_resource] ||= {}).tap do |resource_collection|
            resource_collection[collection_name] = options
          end

          # Prepare callbacks to be executed when it is time to expire the cache.
          reset_cache_proc = Proc.new do
            update_resource_collections_cache!(cache_resource)
          end

          # Bind callbacks.
          [*options[:on]].each { |callback| self.send(callback, &reset_cache_proc) }
        end

        # Resets cache of associated resource instance.
        #
        # @param resource_instance
        # @param [ String, Symbol ] association_name
        def reset_resource_cache(resource_instance, association_name)
          CacheMachine::Cache::Map.reset_cache_on_map(resource_instance.class,
                                                      resource_instance.send(resource_instance.class.primary_key),
                                                      association_name)

          collection = self.cache_map_members[resource_instance.class][association_name]

          if collection && collection[:members]
            collection[:members].each do |member, options|
              CacheMachine::Cache::Map.reset_cache_on_map(resource_instance.class,
                                                          resource_instance.send(resource_instance.class.primary_key),
                                                          member)
            end
          end
        end
      end
    end
  end
end
