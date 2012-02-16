module CacheMachine
  module Cache
    require 'cache_machine/cache/mapper'

    class Map

      # Draws cache dependency graph.
      #
      # @return [ nil ]
      def draw &block
        Mapper.new.instance_eval(&block)
        nil
      end
    end
  end
end
