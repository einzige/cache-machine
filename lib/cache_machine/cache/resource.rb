module CacheMachine
  module Cache
    module Resource
      extend ActiveSupport::Concern

      included do
        CacheMachine::Logger.info "CACHE_MACHINE: bind cache-map on class #{self.name}"
        cattr_accessor :cached_collections
        self.cached_collections = []
      end

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
        def define_timestamp timestamp_name, options = {}, &block
          options[:timestamp] = block if block

          define_method timestamp_name do
            fetch_cache_of(timestamp_key_of(timestamp_name), options) do
              CacheMachine::Logger.info "CACHE_MACHINE (define_timestamp): deleting old timestamp '#{timestamp_name}'."
              delete_cache_of timestamp_name # Case when cache expired by time.
              Time.now.to_i.to_s
            end
          end
        end
      end

      module InstanceMethods

        # Returns ids of an association.
        #
        # @param [ String, Symbol ] association
        #
        # @return [ Array ]
        def association_ids(association)
          pk = self.class.reflect_on_association(association).klass.primary_key.to_sym
          send(association).map &pk
        end

        # Returns associated relation from cache.
        #
        # @param [ String, Symbol ] association_name
        #
        # @return [ ActiveRecord::Relation ]
        def associated_from_cache(association_name)
          klass = self.class.reflect_on_association(association_name).klass
          klass.where(klass.primary_key => CacheMachine::Cache::map_adapter.association_ids(self, association_name))
        end

        # Returns cache key of the member.
        #
        # @param [ String, Symbol ] member
        #
        # @return [ String ]
        def cache_key_of(member)
          CacheMachine::Cache::Map.resource_cache_key(self.class, self.send(self.class.primary_key), member)
        end

        # Fetches cache of the member.
        #
        # @example Fetch cache of associated collection to be refreshed every hour.
        #   @instance.fetch_cache_of :association, :timestamp => lambda { custom_instance_method },
        #                                          :expires_in => 1.hour
        #
        # @param [ Symbol ] _member
        # @param [ Hash ] options
        #
        # @return [ * ]
        def fetch_cache_of _member, options = {}, &block
          expires_in = if expires_at = options[:expires_at]
            expires_at = expires_at.call if expires_at.kind_of? Proc

            if expires_at.kind_of? Time
              expires_at - Time.now
            else
              raise ArgumentError, "expires_at is not a Time"
            end
          else
            options[:expires_in]
          end

          CacheMachine::Logger.info "CACHE_MACHINE (fetch_cache_of): reading '#{cache_key}'."
          CacheMachine::Cache::storage_adapter.fetch(cache_key_of(_member), :expires_in => expires_in, &block)
        end

        # Removes all caches using map.
        def delete_all_caches
          self.class.cached_collections.each &method(:delete_cache_of)
        end

        # Recursively deletes cache by map starting from the member.
        #
        # @param [ Symbol ] member
        def delete_cache_of(member)
          reflection = self.class.reflect_on_association(member)

          if reflection
            reflection.klass.reset_resource_cache(self.class, member)
          else
            delete_cache_of_only member
          end
        end


        # Deletes cache of the only member ignoring cache map.
        #
        # @param [ Symbol ] member
        def delete_cache_of_only(member)
          CacheMachine::Cache::Map.reset_cache_on_map(self.class,
                                                      self.send(self.class.primary_key),
                                                      member)
        end

        # Returns timestamp cache key for anything.
        #
        # @param [ String, Symbol ] anything
        #
        # @return [ String ]
        def timestamp_key_of anything
          [self.class.name, self.to_param, anything, 'timestamp'].join '_'
        end

        # Returns timestamp of anything from memcached.
        #
        # @param [ String, Symbol ] anything
        #
        # @return [ String ]
        def timestamp_of anything
          key = timestamp_key_of anything
          CacheMachine::Logger.info "CACHE_MACHINE (timestamp_of): reading timestamp '#{key}'."
          CacheMachine::Cache::timestamps_adapter.fetch_timestamp(key) { Time.now.to_i.to_s }
        end

        # Returns cache key of +anything+ with timestamp attached.
        #
        # @return [ String ]
        def timestamped_key_of anything, options = {}
          [cache_key_of(anything, options), timestamp_of(anything)].join '_'
        end

        # Deletes cache of anything from memory.
        def reset_timestamp_of anything
          cache_key = timestamp_key_of anything
          CacheMachine::Logger.info "CACHE_MACHINE (reset_timestamp_of): deleting '#{cache_key}'."
          CacheMachine::Cache::timestamps_adapter.reset_timestamp(cache_key)
        end
      end
    end
  end
end