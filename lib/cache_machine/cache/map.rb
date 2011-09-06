module CacheMachine
  module Cache

    # Module to write and expire association cache by given map.
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
        def cache_associated associations
          [*associations].each do |association|
            self.cache_map.merge! association.is_a?(Hash) ? association : {association => []}
          end
        end

        # Defines timestamp for object.
        def define_timestamp timestamp_name, options = {}, &block
          options[:timestamp] = block if block

          define_method timestamp_name do
            fetch_cache_of(timestamp_key_of(timestamp_name), options) do
              CacheMachine::Logger.info "CACHE_MACHINE: define_timestamp: deleting #{timestamp_name}"
              delete_cache_of timestamp_name # Case when cache expired by time.
              Time.now.to_i.to_s
            end
          end
        end

        # Deletes cache of collection with name +association_id+ for each object associated with +record+
        # Called only when <tt>has_many :through</tt> collection changed.
        def delete_association_cache_on record, reflection
          pk = record.class.primary_key
          self.joins(reflection.name).where(reflection.table_name => { pk => record.send(pk) }).each do |cache_source_record|
            cache_source_record.delete_cache_of reflection.name
          end
        end

        # Overwrites +has_many+ of +ActiveRecord+ class to hook Cache Machine.
        def has_many(association_id, options = {})
          # Ensure what collection should be tracked.
          if (should_be_on_hook = self.cache_map.keys.include?(association_id)) && options[:through]
            # If relation is _many_to_many_ track collection changes.
            options[:after_add] = \
            options[:before_remove] = :delete_association_cache_on
          end
          super
          hook_cache_machine_on association_id if should_be_on_hook
        end

        # Overwrites +has_and_belongs_to_many+ of +ActiveRecord+ class to hook Cache Machine.
        def has_and_belongs_to_many(association_id, options = {})
          # Ensure what collection should be tracked.
          if(should_be_on_hook = self.cache_map.keys.include?(association_id))
            # If relation is _many_to_many_ track collection changes.
            options[:after_add] = \
            options[:before_remove] = :delete_association_cache_on
          end
          super
          hook_cache_machine_on association_id if should_be_on_hook
        end

        protected

          # Hooks Cache Machine on association with name +association_id+.
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
        # Returns cache key of +_member+.
        # TODO: describe options.
        def cache_key_of _member, options = {}
          [self.class.name, self.to_param, _member, options[:format], options[:page] || 1].compact.join '_'
        end

        # Fetches cache of +_member+ from cache map.
        # TODO: Describe options.
        # TODO: Describe timestamp features (we can pass methods or fields as timestamps too).
        #       Or we can use define_timestamp +:expires_in => 20.hours+.
        def fetch_cache_of _member, options = {}, &block
          cache_key = if timestamp = options[:timestamp]
            # Make key dependent on collection timestamp and optional timestamp.
            [timestamped_key_of(_member, options), instance_eval(&timestamp)].join '_'
          else
            cache_key_of(_member, options)
          end

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

          Rails.cache.fetch(cache_key, :expires_in => expires_in, &block)
        end

        # Recursively deletes cache by map for +_member+.
        def delete_cache_of _member
          delete_cache_of_only _member
          if chain = self.class.cache_map[_member]
            [*chain].each &method(:delete_cache_of)
          end
        end

        # Deletes cache of only +_member+ ignoring cache map.
        def delete_cache_of_only _member
          CacheMachine::Cache::FORMATS.each do |cache_format|
            page_nr = 0; begin
              cache_key = cache_key_of(_member, {:format => cache_format, :page => page_nr += 1})
              CacheMachine::Logger.info "CACHE_MACHINE: delete_cache_of_only: deleting #{cache_key}"
            end while Rails.cache.delete(cache_key)
          end
          reset_timestamp_of _member
        end

        # Returns timestamp cache key for +anything+.
        def timestamp_key_of anything
          [self.class.name, self.to_param, anything, 'timestamp'].join '_'
        end

        # Returns timestamp of +anything+ from memcached.
        def timestamp_of anything
          Rails.cache.fetch(timestamp_key_of anything) { Time.now.to_i.to_s }
        end

        # Returns cache key of +anything+ with timestamp attached.
        def timestamped_key_of anything, options = {}
          [cache_key_of(anything, options), timestamp_of(anything)].join '_'
        end

        # Deletes cache of +anything+ from memory.
        def reset_timestamp_of anything
          cache_key = timestamp_key_of anything
          CacheMachine::Logger.info "CACHE_MACHINE: reset_timestamp_of: deleting #{cache_key}"
          Rails.cache.delete(cache_key)
        end

        protected

          # Deletes cache of associated collection what contains +record+.
          # Called only when <tt>has_many :through</tt> collection changed.
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
