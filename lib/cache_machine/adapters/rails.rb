module CacheMachine
  module Adapters
    require "cache_machine/adapter"

    class Rails < CacheMachine::Adapter

      def initialize(*options)
        CacheMachine::Logger.info "CACHE_MACHINE: initialized default Rails adapter"
      end

      def append_id_to_map(target, association, id)
        key = get_map_key(target, association)
        ::Rails.cache.write(key, (::Rails.cache.read(key) || []) | [id])
      end

      def append_id_to_reverse_map(resource, association, target, id)
        key = get_reverse_map_key(resource, association, target)
        ::Rails.cache.write(key, (::Rails.cache.read(key) || []) | [id])
      end

      def association_ids(target, association)
        ::Rails.cache.fetch(get_map_key(target, association)) do
          target.association_ids(association)
        end
      end

      def fetch(key, options = {}, &block)
        ::Rails.cache.fetch(get_content_key(key), options, &block)
      end

      def fetch_timestamp(name, options = {}, &block)
        ::Rails.cache.fetch(get_timestamp_key(name), options, &block)
      end

      def delete(key)
        ::Rails.cache.delete(get_content_key(key))
      end

      def reset_timestamp(name)
        ::Rails.cache.delete(get_timestamp_key(name))
      end

      def reverse_association_ids(resource, association, target)
        ::Rails.cache.fetch(get_reverse_map_key(resource, association, target)) do
          target.cache_map_ids(resource, association)
        end
      end

      def write_timestamp(name, &block)
        ::Rails.cache.write(get_timestamp_key(name), &block)
      end
    end
  end
end