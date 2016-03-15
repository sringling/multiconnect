require "multiconnect/version"
require 'active_support'
require 'active_support/concern'
require 'active_support/core_ext/class/attribute'

module Multiconnect
  autoload :Connection,     'multiconnect/connection'
  autoload :Connectable,    'multiconnect/connectable'
end
