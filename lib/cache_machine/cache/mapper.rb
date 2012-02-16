module CacheMachine
  module Cache
    require 'cache_machine/cache/collection'
    require 'cache_machine/cache/resource'
    require 'cache_machine/cache/timestamp'

    # CacheMachine::Cache::Map.draw do
    #   resource Venue, :timestamp => false do                                                                          # Says what Venue class should be used as a source of ids for map
    #     collection :events, :scope => :active, :formats => [:html, :json], :timestamp => true, :on => :after_save do  # Says what every event should fill the map with venue ids and use callback to reset cache for every venue.
    #       member :upcoming_events, :formats => [:xml]                                                                 # Says what this method also needs to be reset.
    #     end
    #   end
    #
    #   resource Event # Says what Event class should use timestamp on update (same as resource Event :timestamp => true)
    # end

    class Mapper
      DEFAULT_RESOURCE_OPTIONS   = { :timestamp => true        }
      DEFAULT_COLLECTION_OPTIONS = { :on        => :after_save }

      attr_reader :cache_resource

      def initialize
        change_scope! nil, :root
      end

      # Defines model as a source of ids for map.
      #
      # @param [Class] model
      # @param [Hash]options
      def resource(model, options = {})
        scoped :root, :resource do
          @cache_resource = model

          unless @cache_resource.include? CacheMachine::Cache::Resource
            @cache_resource.send :include, CacheMachine::Cache::Resource
          end

          options.reverse_merge! DEFAULT_RESOURCE_OPTIONS

          if options[:timestamp]
            @cache_resource.send(:include, CacheMachine::Cache::Timestamp)
          end

          yield if block_given?
        end
      end

      # Adds callbacks to fill the map with model ids and uses callback to reset cache for every instance of the model.
      #
      # @param [String, Symbol] collection_name
      # @param [Hash] options
      def collection(collection_name, options = {}, &block)
        scoped :resource, :collection do
          options.reverse_merge! DEFAULT_COLLECTION_OPTIONS

          collection_klass   = @cache_resource.reflect_on_association(collection_name).klass
          collection_members = get_members(&block)

          # map: Event#111 => :venue_ids => [1,2,3,4,5] (Venue.joins(:events).where("events.id = ?"))
          unless collection_klass.include? CacheMachine::Cache::Collection
            collection_klass.send :include, CacheMachine::Cache::Collection
          end

          collection_klass.register_cache_dependency @cache_resource, collection_name, { :scope   => options[:scope],
                                                                                         :members => collection_members,
                                                                                         :on      => options[:on] }
        end
      end

      # Appends member to the collection.
      #
      # @param [String] member_name
      # @param [Hash] options
      def member(member_name, options = {})
        scoped :collection, :member do
          (@members ||= {})[member_name] = options
        end
      end

      # Returns members of collection in scope.
      #
      # @return [Hash]
      def get_members
        @members = {}
        yield if block_given?
        @members
      end

      protected

        # Checks if method can be called from the scope.
        #
        # @param [Symbol] scope
        def validate_scope!(scope)
          raise "#{scope} can not be called in #{@scope} scope" if @scope != scope
        end
  
        # Changes scope from one to another.
        #
        # @param [Symbol] from
        # @param [Symbol] to
        def change_scope!(from, to)
          validate_scope!(from)
          @scope = to
        end
  
        # Runs code in the given scope.
        #
        # @param [Symbol] from
        # @param [Symbol] to
        def scoped(from, to)
          change_scope! from, to
          yield
          change_scope! to, from
        end
    end
  end
end