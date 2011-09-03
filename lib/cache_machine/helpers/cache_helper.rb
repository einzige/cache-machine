require 'action_view/helpers/capture_helper'

module CacheMachine
  module Helpers
    module CacheHelper

      include ActionView::Helpers::CaptureHelper

      def cache_for record, cacheable, options = {}, &block
        record.fetch_cache_of(cacheable, options.merge(:format => :ehtml)) { capture &block }
      end
    end
  end
end
