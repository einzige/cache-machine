module CacheMachine
  require "cache_machine/logger"

  # Adapter provides base functionality to deal with cache maps.
  class Adapter
    def initialize *options
      raise 'not implemented yet'
    end

    def fetch key, options = {}, &block
      raise 'not implemented yet'
    end

    def delete key
      raise 'not implemented yet'
    end

    def append_id_to_map target, association, id
      raise 'not implemented yet'
    end

    def association_ids target, association, primary_key = 'id'
      raise 'not implemented yet'
    end

    def write_timestamp name, &block
      raise 'not implemented yet'
    end

    def fetch_timestamp name, options = {}, &block
      raise 'not implemented yet'
    end

    def reset_timestamp name
      raise 'not implemented yet'
    end

    def get_content_key key
      "Content##{key}"
    end

    def get_map_key target, association
      "Map##{target.class.name}|#{target.to_param}|#{association}"
    end

    def get_timestamp_key name
      "Timestamp##{name}"
    end
  end
end
