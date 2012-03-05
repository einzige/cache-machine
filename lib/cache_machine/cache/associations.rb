module CacheMachine
  module Cache
    module Associations
      extend ActiveSupport::Concern

      included do
        # Returns ids of an association.
        #
        # @param [ String, Symbol ] association
        #
        # @return [ Array ]
        def association_ids(association)
          pk = self.class.reflect_on_association(association).klass.primary_key.to_sym
          send(association).map &pk
        end

        # Returns associated relation from cache.
        #
        # @param [ String, Symbol ] association_name
        #
        # @return [ ActiveRecord::Relation ]
        def associated_from_cache(association_name)
          klass = self.class.reflect_on_association(association_name).klass
          klass.where(klass.primary_key => CacheMachine::Cache::map_adapter.association_ids(self, association_name))
        end
      end
    end
  end
end