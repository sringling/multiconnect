module Multiconnect
  module Connectable
    extend ActiveSupport::Concern

    included do
      class << self
        class_attribute :_connections
        self._connections = []
        
        def add_connection(connection_class, options = {})
          self._connections = _connections + [connection_class.new(options)]
        end

        def prepend_connection(connection_class, options = {})
          self._connections = [connection_class.new(options)] + _connections
        end

        def request(action, *args)
          self._connections.each do |connection|
            result = connection.execute(action, *args)
            return result if result.success?
          end
          raise "Multiconnect Error: #{self} has failed to request #{action}"
        end
      end
    end
  end
end