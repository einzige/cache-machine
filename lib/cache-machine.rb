#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:szinin@partyearth.com
#++
require "cache_machine/cache/scope"
require "cache_machine/cache/timestamp_builder"
require "cache_machine/cache/associations"
require "cache_machine/cache/mapper"
require "cache_machine/cache"
require "cache_machine/helpers/cache_helper"
require "cache_machine/logger"
require "cache_machine/railtie"

ActiveRecord::Base.send :include, CacheMachine::Cache