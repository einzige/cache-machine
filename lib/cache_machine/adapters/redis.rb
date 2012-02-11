module CacheMachine
  module Adapters
    require "cache_machine/adapter"
    require "redis"

    class Redis < CacheMachine::Adapter
      attr_accessor :redis

      def initialize *options
        @redis = ::Redis.new(options)
        CacheMachine::Logger.info "CACHE_MACHINE: initialized Redis adapter"
      end

      def fetch key, options = {}, &block
        @redis.setnx(get_content_key(key), yield)
      end

      def delete key
        @redis.del(get_content_key(key))
      end

      def append_id_to_map target, association, id
        @redis.sadd(get_map_key(target, association), id)
      end

      def write_timestamp name, &block
        @redis.set(get_timestamp_key(name), yield)
      end

      def fetch_timestamp name, options = {}, &block
        @redis.setnx(get_timestamp_key(name), yield)
      end

      def reset_timestamp name
        @redis.del(get_timestamp_key(name))
      end
    end
  end
end