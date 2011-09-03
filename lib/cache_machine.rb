#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:kgoslar@partyearth.com
#++
module CacheMachine
  extend ActiveSupport::Autoload; autoload :Helpers
  include Logging
end
ActiveRecord::Base.send :include, CacheMachine::Cache

