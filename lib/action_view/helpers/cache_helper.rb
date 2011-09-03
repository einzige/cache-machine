module ActionView
  module Helpers
    module CacheMachineHelper
      def cache_for record, cacheable, options = {}, &block
        record.fetch_cache_of(cacheable, options) { capture &block }
      end
    end
  end
  ActionView::Helpers.autoload :CacheMachineHelper
  ActionView::Helpers.send(:include, Helpers::CacheMachineHelper)
end
