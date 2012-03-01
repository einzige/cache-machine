module CacheMachine
  require "cache_machine/logger"

  # API to your cache storage.
  class Adapter

    def initialize(*options)
      raise 'not implemented yet'
    end

    # Appends an id to map of associations.
    #
    # @param target ActiveRecord object
    # @param [ String, Symbol ] association Name of an association from target
    # @param id Uniq identifier of any member from association of target
    def append_id_to_map(target, association, id)
      raise 'not implemented yet'
    end

    # Appends an id to map of associations in reverse-direction to used association.
    #
    # @param [ Class ] resource
    # @param [ String, Symbol ] association Name of an association from target
    # @param target
    # @param id Uniq identifier of any member having class _resource_ of target association
    def append_id_to_reverse_map(resource, association, target, id)
      raise 'not implemented yet'
    end

    # Returns ids from cache.
    #
    # @param target
    # @param [ String, Symbol ] association Collection name where we fetch ids.
    #
    # @return [ Array ]
    def association_ids(target, association)
      raise 'not implemented yet'
    end

    # Deletes key in cache.
    #
    # @param key
    def delete(key)
      raise 'not implemented yet'
    end

    # Fetches cache.
    #
    # @param key
    # @param [ Hash ] options
    #
    # @return [ Object ]
    def fetch(key, options = {}, &block)
      raise 'not implemented yet'
    end

    # Fetches timestamp from cache.
    #
    # @param [ String, Symbol ] name
    # @param [ Hash ] options
    #
    # @return [ String ]
    def fetch_timestamp(name, options = {}, &block)
      raise 'not implemented yet'
    end

    # Returns content key used for fetch blocks.
    #
    # @param [ String, Symbol ] key
    #
    # @return String
    def get_content_key(key)
      "Content##{key}"
    end

    # Returns key used for associations map.
    #
    # @param target
    # @param [ String, Symbol ] association
    #
    # @return String
    def get_map_key(target, association)
      "Map##{target.class.name}|#{target.send(target.class.primary_key)}|#{association}"
    end

    # Returns key to fetch timestamp from cache.
    #
    # @param [ String, Symbol ] name
    #
    # @return String
    def get_timestamp_key(name)
      "Timestamp##{name}"
    end

    # Returns key used for reversed associations map.
    #
    # @param [ Class ] resource
    # @param [ String, Symbol ] association
    # @param target
    #
    # @return String
    def get_reverse_map_key(resource, association, target)
      "ReverseMap##{resource}|#{target.send(target.class.primary_key)}|#{association}"
    end

    # Resets timestamp by name.
    #
    # @param [ String, Symbol ] name
    def reset_timestamp(name)
      raise 'not implemented yet'
    end

    # Writes timestamp in cache.
    #
    # @param [ String, Symbol ] name
    def write_timestamp(name, &block)
      raise 'not implemented yet'
    end
  end
end
