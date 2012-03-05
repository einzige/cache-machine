module CacheMachine
  module Cache
    module Resource
      extend ActiveSupport::Concern

      included do
        CacheMachine::Logger.info "CACHE_MACHINE: bind cache-map on class #{self.name}"

        include CacheMachine::Cache::Associations
        include CacheMachine::Cache::Scope

        cattr_accessor :cached_collections
        self.cached_collections = []

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
        def fetch_cache_of(_member, options = {}, &block)
          expires_in = if expires_at = options[:expires_at]
            expires_at = expires_at.call if expires_at.kind_of? Proc

            if expires_at.is_a? Date
              expires_at = expires_at.to_time
            end

            if expires_at.kind_of? DateTime
              expires_at - DateTime.now
            else
              raise ArgumentError, "expires_at is not a Date or DateTime"
            end
          else
            options[:expires_in]
          end

          if expires_in && expires_in < 0
            yield
          else
            if options.has_key? :timestamp
              unless self.class.respond_to? options[:timestamp]
                raise ArgumentError, "Undefined timestamp '#{options[:timestamp]}' for class #{self.class}"
              end

              _member = CacheMachine::Cache::Map.timestamped_resource_member_key(self.class,
                                                                                 self.send(self.class.primary_key),
                                                                                 _member,
                                                                                 self.class.send(options[:timestamp]))
            end
            CacheMachine::Logger.info "CACHE_MACHINE (fetch_cache_of): reading '#{cache_key_of(_member)}'."
            CacheMachine::Cache::storage_adapter.fetch(cache_key_of(_member), :expires_in => expires_in, &block)
          end
        end
        alias fetch_cache fetch_cache_of

        # Removes all caches using map.
        def delete_all_caches
          self.class.cached_collections.each &method(:delete_cache_of)
        end
        alias reset_all_caches delete_all_caches

        # Recursively deletes cache by map starting from the member.
        #
        # @param [ Symbol ] member
        def delete_cache_of(member)
          reflection = self.class.reflect_on_association(member)

          if reflection
            reflection.klass.reset_resource_cache(self, member)
          else
            delete_cache_of_only member
          end
        end
        alias delete_cache delete_cache_of

        # Deletes cache of the only member ignoring cache map.
        #
        # @param [ Symbol ] member
        def delete_cache_of_only(member)
          CacheMachine::Cache::Map.reset_cache_on_map(self.class, self.send(self.class.primary_key), member)
        end
        alias delete_member_cache delete_cache_of_only

        # Deletes cache of anything from memory.
        #
        # @param [ String, Symbol ] anything
        def reset_timestamp_of(anything)
          self.reset_resource_timestamp(self.class, self.send(self.class.primary_key), anything)
        end
        alias reset_timestamp reset_timestamp_of
      end
    end
  end
end
