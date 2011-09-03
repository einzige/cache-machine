module CacheMachine
  class Railtie < Rails::Railtie
    initializer 'cache-machine.initialize' do
      ActiveSupport.on_load(:action_view) do
        include CacheMachine::Helpers::CacheHelper
      end
    end
  end
end