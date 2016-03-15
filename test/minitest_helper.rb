$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'multiconnect'

require 'minitest/autorun'

class PrimaryConnection < Multiconnect::Connection::Base
  
  def report_error(e)
    $errors ||=[]
    $errors << e.class
  end

  def request(action, *args)
    self.client.send action, *args
    [{id: 1, name: "Bob"}]
  end

end

class SecondaryConnection < Multiconnect::Connection::Base
  def report_error(e)
    $errors ||=[]
    $errors << e.class
  end

  def request(action, *args)
    [{id: 1, name: "Bob"}]
  end
end

class TertiaryConnection < Multiconnect::Connection::Base
  def report_error(e)
    $errors ||=[]
    $errors << e.class
  end

  def request(action, *args)
    [{id: 1, name: "Bob"}]
  end
end

class DummyObject

  def self.method_missing(action, *args, &block)
    raise "lol, nope" if action == :explode
    $log ||= []
    $log << { action: action, args: args }
  end

end

class User

  include Multiconnect::Connectable

  def self.client_class
    DummyObject
  end

  add_connection PrimaryConnection, client: self.client_class, except: :create
  add_connection SecondaryConnection, client: self.client_class, except: [:where, :search]

  def self.find(id)
    request :find, id
  end

  def self.where(args)
    request :where, args
  end

  def self.explode(args)
    request :explode, args
  end
end

class SadClass
  include Multiconnect::Connectable

  add_connection PrimaryConnection, client: DummyObject

  def self.explode(args)
    request :explode, args
  end
end
