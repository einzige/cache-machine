namespace :cache_machine do
  desc "Caches the map of associations."
  task :fill_associations_map, [:models] => :environment do
    models =   args[:models] ? args[:models].map(&:constantize) : CacheMachine::Cache::Map.registered_models
    models.each do |model|
      CacheMachine::Cache::Map.fill_associations_map model
    end
  end
end