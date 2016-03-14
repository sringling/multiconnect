module Multiconnect
  module Connectable
    extend ActiveSupport::Concern

    included do
      class << self
        class_attribute :_connections
        
        def add_connection(connection_class, options = {})
          
          self._connections = _connections + [connection_class.new(options)]

        end

        def request(action, *args)
          connections.each do |connection|
            result = connection.execute(action, *args)
            return result if result.successful?
          end
          raise "all connections failed"
        end
      end
    end
  end
end