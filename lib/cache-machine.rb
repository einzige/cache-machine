#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:kgoslar@partyearth.com
#++
require "cache_machine/logging"
require "cache_machine/cache"
require "cache_machine/helpers/cache_helper"

ActiveRecord::Base.send :include, CacheMachine::Cache
ActionView::Helpers::CacheHelper.send :extend, CacheMachine::Helpers::CacheHelper
CacheMachine.send :include, CacheMachine::Logging
