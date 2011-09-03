module ActionView
  module Helpers
    module CacheHelper
      module CacheMachine
        def cache_for record, cacheable, options = {}, &block
          record.fetch_cache_of(cacheable, options) { capture &block }
        end
      end
    end
  end
end
ActionView::Helpers::CacheHelper.send :include, ActionView::Helpers::CacheHelper::CacheMachine
