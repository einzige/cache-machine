#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:kgoslar@partyearth.com
#++
ActiveRecord::Base.send :include, CacheMachine::Cache

module CacheMachine
  extend ActiveSupport::Autoload; autoload :Helpers
end
