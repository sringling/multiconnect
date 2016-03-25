require "multiconnect/version"
require 'active_support'
require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'

module Multiconnect
  autoload :Connection,     'multiconnect/connection'
  autoload :Connectable,    'multiconnect/connectable'
  autoload :Error,          'multiconnect/error'
end
