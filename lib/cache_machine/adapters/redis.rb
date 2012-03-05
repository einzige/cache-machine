module CacheMachine
  module Adapters
    require "cache_machine/adapter"
    require "redis"

    class Redis < CacheMachine::Adapter
      attr_accessor :redis

      def initialize(*options)
        @redis = ::Redis.new(*options)
        CacheMachine::Logger.info "CACHE_MACHINE: initialized Redis adapter"
      end

      def append_id_to_map(target, association, id)
        @redis.sadd(get_map_key(target, association), id)
      end

      def append_id_to_reverse_map(resource, association, target, id)
        @redis.sadd(get_reverse_map_key(resource, association, target), id)
      end

      def association_ids(target, association)
        get_ids(get_map_key(target, association)) { target.association_ids(association) }
      end

      def delete(key)
        @redis.del(key).to_i > 0
      end

      def delete_content(key)
        delete(get_content_key(key))
      end

      def fetch(key, options = {}, &block)
        key = get_content_key(key)
        block_given? ? exec_multi_command(:setnx, key, options, &block) : @redis.get(key)
      end

      def fetch_timestamp(name, options = {}, &block)
        exec_multi_command(:setnx, get_timestamp_key(name), options, &block)
      end

      def reset_timestamp(name)
        @redis.del(get_timestamp_key(name))
      end

      def reverse_association_ids(resource, association, target)
        get_ids(get_reverse_map_key(resource, association, target)) { target.cache_map_ids(resource, association) }
      end

      def write_timestamp(name, options = {}, &block)
        exec_multi_command(:set, get_timestamp_key(name), options, &block)
      end

      protected

        def exec_multi_command(command, key, options)
          content = yield

          @redis.multi do
            @redis.send(command, key, content)
            @redis.expire(key, options[:expires_in].to_i) if options[:expires_in]
          end

          content
        end

        def get_ids(key)
          if @redis.exists(key)
            @redis.smembers(key)
          else
            # TODO(!#): INVESTIGATE WHY ID CANNOT BE PASSED AS AN ARRAY
            result = yield
            @redis.multi { result.each { |id| @redis.sadd key, id } }
            result
          end
        end
    end
  end
end