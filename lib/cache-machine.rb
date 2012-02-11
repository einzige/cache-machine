#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:kgoslar@partyearth.com
#++
require "cache_machine/cache/mapper"
require "cache_machine/cache"
require "cache_machine/helpers/cache_helper"
require "cache_machine/logger"
require "cache_machine/railtie"

ActiveRecord::Base.send :include, CacheMachine::Cache
