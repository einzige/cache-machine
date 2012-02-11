module CacheMachine

  require "cache_machine/logger"

  # Adapter provides base functionality to deal with cache maps.
  class Adapter
    def initialize *options
      raise "cannot be called directly"
    end

    def fetch key, options = {}, &block
      raise "cannot be called directly"
    end

    def delete key
      raise "cannot be called directly"
    end

    def append_id_to_map target, association, id
      raise "cannot be called directly"
    end

    def association_ids target, association, primary_key = 'id'
      raise "cannot be called directly"
    end

    def write_timestamp name, &block
      raise "cannot be called directly"
    end

    def fetch_timestamp name, options = {}, &block
      raise "cannot be called directly"
    end

    def reset_timestamp name
      raise "cannot be called directly"
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
