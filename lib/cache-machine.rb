#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:kgoslar@partyearth.com
#++
# = Cache Machine
#
# Provides smart caching for collections or method results of any +ActiveRecord+ object.
#
# === EXAMPLES
#
#   # Fetch cache of venues collection on model_instance.
#   @model_instance.fetch_cache_of :venues { @neighborhood.venues.to_html }
#
#   # Specify format.
#   @model_instance.fetch_cache_of :venues, :json { @neighborhood.venues.to_json }
#
#   # Paginated content.
#   @model_instance.fetch_cache_of :venues, :json, page { @neighborhood.venues.to_json }
#
# In you target model:
#
#   acts_as_cache_machine_for :venues  => [:hotspots, :today_events],
#                             :cities  => [:venues],
#                             :streets => :hotspots,
#                             :users
#
# This example shows you how changes of one collection affect on invalidation process:
# - Users cache is invalidated when changing the _users_ collection (_add_, _delete_, _update_)
# - Venues cache is invalidated when changing the _venues_ collection
# - Venues cache is invalidated when changing the _cities_ collection. In this case machine automatically invalidates _hotspots_ and _today_events_
# - Cities cache is invalidated when changing the _cities_ collection
# - Hotspots cache is invalidated when changing the _venues_ collection
# - Hotspots cache is invalidates when changing the _streets_ collection
# - TodayEvents cache is invalidated when changing the _venues_ collection
# <b>Keys in cache-map hash is your ActiveRecord collections, values is whatever you want (methods, collections, variables etc).</b>
#
# === Custom cache keys
#
# For example you need to cache _upcoming_events_ from 11/11/11 to 12/12/12 by date.
#
# [Use timestamps] <tt>Rails.cache.fetch("upcoming_events_#{@city.timestamp_of :upcoming_events}_11/11/11-12/12/12")</tt>
#
# +timestamp_of+ generates timestamp for you. This timestamp changes on any change in _upcoming_events_ collection.
# TODO: write more. We have a lot of features for timestamps.
#
# === Timestamps as cache keys on ActiveRecord classes:
#
#   UpcomingEvents.timestamp
#
# Timestamp automatically changed when changing collection.


module ActiveRecord
  module CacheMachine
    extend ActiveSupport::Concern

    # Supported cache formats. You can add your own.
    CACHE_FORMATS = [nil, :ehtml, :json, :xml]

    included do
      after_save { self.class.reset_timestamps }
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
        include ActiveRecord::CacheMachine::AssociatonMachine
        cache_associated(associations)
      end

      # Returns timestamp of class collection.
      def timestamp format = :ehtml
        Rails.cache.fetch(timestamp_key format) { Time.now.to_i.to_s }
      end

      # Returns cache key to fetch timestamp from memcached.
      def timestamp_key format = :ehtml
        [self.name, format, 'timestamp'].join '_'
      end

      # Returns cache key of +anything+ with timestamp attached.
      def timestamped_key format = :ehtml
        [timestamp_key(format), timestamp(format)].join '_'
      end

      # Resets timestamp of class collection.
      def reset_timestamp format = :ehtml
        Rails.cache.delete(timestamp_key format)
      end

      def reset_timestamps
        CACHE_FORMATS.each { |format| reset_timestamp format }
      end
    end

    # Module to write and expire association cache by given map.
    module AssociatonMachine
      extend ActiveSupport::Concern

      included do
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
        def define_timestamp timestamp_name, options = {}
          define_method timestamp_name do
            _timestamp_key = self.timestamp_key_of(timestamp_name)

            fetch_cache_of(_timestamp_key, options) do
              delete_cache_of _timestamp_key # Case when cache expired by time.
              Time.now.to_i.to_s
            end
          end
        end

        # Deletes cache of collection with name +association_id+ for each object associated with +record+
        # Called only when <tt>has_many :through</tt> collection changed.
        def delete_association_cache_on record, association_id
          # Find all associations  between +record+ class and current class.
          associations = record.class.reflect_on_all_associations.find_all { |association| association.klass == self }
          associations.each do |association|
            record.send(association.name).reload.each do |cache_source_record|
              # Reset cache of association with name +association_id+ for each object associated with +record+.
              cache_source_record.delete_cache_of association_id
            end
          end
        end

        # Overwrites +has_many+ of +ActiveRecord+ class to hook Cache Machine.
        def has_many(association_id, options = {})
          # Ensure what collection should be tracked.
          if (should_be_on_hook = self.cache_map.keys.include?(association_id)) && options[:through]
            # If relation is _many_to_many_ track collection changes.
            options[:before_add] = \
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
            options[:before_add] = \
            options[:before_remove] = :delete_association_cache_on
          end
          super
          hook_cache_machine_on association_id if should_be_on_hook
        end

        protected

          # Hooks Cache Machine on association with name +association_id+.
          def hook_cache_machine_on association_id
            case (reflection = (target_class = self).reflect_on_association association_id)
            when ActiveRecord::Reflection::ThroughReflection
              # If association is _many_to_many_ it should reset its cache for all associated objects with class +target_class+.
              reflection.klass.after_save     { target_class.delete_association_cache_on self, association_id }
              reflection.klass.before_destroy { target_class.delete_association_cache_on self, association_id }
            when ActiveRecord::Reflection::AssociationReflection
              if reflection.macro == :has_and_belongs_to_many
                reflection.klass.after_save     { target_class.delete_association_cache_on self, association_id }
                reflection.klass.before_destroy { target_class.delete_association_cache_on self, association_id }
              else
                # If association is _has_many_ or _has_one_ it should reset its cache for associated object with class +target_class+.
                reflection.klass.after_save     { target_class.find_by_id(send reflection.primary_key_name).try(:delete_cache_of, association_id) }
                reflection.klass.before_destroy { target_class.find_by_id(send reflection.primary_key_name).try(:delete_cache_of, association_id) }
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
        def fetch_cache_of _member, options = {}
          cache_key = if timestamp = options[:timestamp]
            # Make key dependent on collection timestamp and optional timestamp.
            [timestamped_key_of(_member, options), send(timestamp)].join '_'
          else
            cache_key_of(_member, options)
          end
          Rails.cache.fetch(cache_key, :expires_in => options[:expires_in]) { yield }
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
          ActiveRecord::CacheMachine::CACHE_FORMATS.each do |cache_format|
            page_nr = 0
            while Rails.cache.delete(cache_key_of(_member, {:format => cache_format, :page => page_nr += 1})); end
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
          Rails.cache.delete(timestamp_key_of anything)
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
ActiveRecord::Base.send :include, ActiveRecord::CacheMachine
