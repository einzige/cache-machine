module CacheMachine
  module Adapters
    require "cache_machine/adapter"
    require "redis"

    class Redis < CacheMachine::Adapter
      attr_accessor :redis

      def initialize *options
        @redis = ::Redis.new(*options)
        CacheMachine::Logger.info "CACHE_MACHINE: initialized Redis adapter"
      end

      def association_ids target, association, primary_key = 'id'
        result = []
        key = get_map_key(target, association)

        if @redis.exists(key)
          result = @redis.smembers(key)
        elsif (result = target.send(association).map &primary_key.to_sym).any? # TODO(!#): REPLACE WITH FIELD INSTEAD OF TO_PARAM
          @redis.multi { result.each { |id| @redis.sadd key, id } }   # TODO(!#): INVESTIGATE WHY ID CANNOT BE PASSED AS AN ARRAY
        end

        result
      end

      def fetch key, options = {}, &block
        key = get_content_key(key)
        block_given? ? exec_multi_command(:setnx, key, options, &block) : @redis.get(key)
      end

      def delete key
        @redis.del(get_content_key(key)).to_i > 0
      end

      def append_id_to_map target, association, id
        @redis.sadd(get_map_key(target, association), id)
      end

      def write_timestamp name, options = {}, &block
        exec_multi_command(:set, get_timestamp_key(name), options, &block)
      end

      def fetch_timestamp name, options = {}, &block
        exec_multi_command(:setnx, get_timestamp_key(name), options, &block)
      end

      def reset_timestamp name
        @redis.del(get_timestamp_key(name))
      end

      protected

        def exec_multi_command command, key, options, &block
          content = block.call

          @redis.multi do
            @redis.send(command, key, content) # TODO(#!) CHECK IF YIELD CAME FROM &BLOCK
            @redis.expire(key, options[:expires_in].to_i) if options[:expires_in]
          end

          content
        end
    end
  end
end