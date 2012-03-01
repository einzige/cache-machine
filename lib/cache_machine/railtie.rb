module CacheMachine
  class Railtie < Rails::Railtie
    initializer 'cache-machine.initialize' do
      ActiveSupport.on_load(:action_view) do
        include CacheMachine::Helpers::CacheHelper
      end
    end

    config.after_initialize do
      CacheMachine::Cache::Map.registered_maps.each do |block|
        CacheMachine::Cache::Mapper.new.instance_eval(&block)
      end
    end

    rake_tasks do
      load 'cache_machine/tasks.rb'
    end
  end
end
