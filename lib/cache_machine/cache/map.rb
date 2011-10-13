module CacheMachine
  module Cache

    module Map
      extend ActiveSupport::Concern

      included do
        CacheMachine::Logger.info "CACHE_MACHINE: bind cache-map on class #{self.name}"

        # Stores associations map to be cached.
        cattr_accessor :cache_map
        self.cache_map = {}
      end

      module ClassMethods

        # Fills cache map.
        #
        # @param [ Hash<Symbol, Array> ] associations
        def cache_associated associations
          [*associations].each do |association|
            self.cache_map.merge! association.is_a?(Hash) ? association : {association => []}
          end
        end

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

        # Deletes cache of collection associated via many-to-many.
        #
        # @param [ ActiveRecord::Base ]
        def delete_association_cache_on record, reflection
          pk = record.class.primary_key

          joining = unless reflection.options[:source_type]
            reflection.through_reflection ? { reflection.through_reflection.name => reflection.source_reflection.name } : reflection.name
          else
            reflection.name
          end

          self.joins(joining).where(reflection.table_name => { pk => record.send(pk) }).find_each do |cache_source_record|
            cache_source_record.delete_cache_of reflection.name
          end
        end

        # Hooks association changes.
        #
        # @private
        def has_many(association_id, options = {}) #:nodoc:
          # Ensure what collection should be tracked.
          if (should_be_on_hook = self.cache_map.keys.include?(association_id)) && options[:through]
            # If relation is _many_to_many_ track collection changes.
            options[:after_add] = \
            options[:before_remove] = :delete_association_cache_on
          end
          super
          hook_cache_machine_on association_id if should_be_on_hook
        end

        # Hooks association changes.
        #
        # @private
        def has_and_belongs_to_many(association_id, options = {}) #:nodoc:

          # Ensure what collection should be tracked.
          if(should_be_on_hook = self.cache_map.keys.include?(association_id))

            # If relation is many-to-many track collection changes.
            options[:after_add] = \
            options[:before_remove] = :delete_association_cache_on
          end
          super
          hook_cache_machine_on association_id if should_be_on_hook
        end

        protected

          # Hooks Cache Machine.
          #
          # @param [ Symbol ] association_id
          def hook_cache_machine_on association_id
            reset_cache_proc = Proc.new do |reflection, target_class, &block|
              block ||= lambda { target_class.delete_association_cache_on self, reflection }

              reflection.klass.after_save     &block
              reflection.klass.before_destroy &block
            end

            case (reflection = (target_class = self).reflect_on_association association_id)
            when ActiveRecord::Reflection::ThroughReflection
              # If association is _many_to_many_ it should reset its cache for all associated objects with class +target_class+.
              reset_cache_proc.call(reflection, target_class)
            when ActiveRecord::Reflection::AssociationReflection
              if reflection.macro == :has_and_belongs_to_many
                reset_cache_proc.call(reflection, target_class)
              else
                # If association is _has_many_ or _has_one_ it should reset its cache for associated object with class +target_class+.
                reset_cache_proc.call(reflection) do
                  target_class.where((reflection.options[:primary_key] || :id) =>
                                 send(reflection.options[:foreign_key] || reflection.primary_key_name)).first.try(:delete_cache_of, association_id)
                end
              end
            end
          end
      end

      module InstanceMethods

        # Returns cache key of the member.
        #
        # @param [ Symbol ] _member
        # @param [ Hash ] options
        #
        # @return [ String ]
        def cache_key_of _member, options = {}
          timestamp = instance_eval(&options[:timestamp]) if options.has_key? :timestamp
          [self.class.name, self.to_param, _member, options[:format], options[:page] || 1, timestamp].compact.join '_'
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
          Rails.cache.fetch(cache_key_of(_member, options), :expires_in => expires_in, &block)
        end

        # Removes all caches using map.
        def delete_all_caches
          self.class.cache_map.to_a.flatten.uniq.each &method(:delete_cache_of)
        end

        # Recursively deletes cache by map starting from the member.
        #
        # @param [ Symbol ] _member
        def delete_cache_of _member
          delete_cache_of_only _member
          if chain = self.class.cache_map[_member]
            [*chain].each &method(:delete_cache_of)
          end
        end

        # Deletes cache of the only member ignoring cache map.
        #
        # @param [ Symbol ] _member
        def delete_cache_of_only _member
          CacheMachine::Cache.formats.each do |cache_format|
            page_nr = 0; begin
              cache_key = cache_key_of(_member, {:format => cache_format, :page => page_nr += 1})
              CacheMachine::Logger.info "CACHE_MACHINE (delete_cache_of_only): deleting '#{cache_key}'"
            end while Rails.cache.delete(cache_key)
          end
          reset_timestamp_of _member
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
          Rails.cache.fetch(key) { Time.now.to_i.to_s }
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
          Rails.cache.delete(cache_key)
        end

        protected

          # Deletes cache of associated collection what contains record.
          # Called only when many-to-many collection changed.
          #
          # @param [ ActiveRecord::Base ] record
          def delete_association_cache_on record

            # Find all associations with +record+ by its class.
            associations = self.class.reflect_on_all_associations.find_all { |association| association.klass == record.class }

            # Delete cache of each associated collection what may contain +record+.
            associations.map(&:name).each &method(:delete_cache_of)
          end
      end
    end
  end
end
