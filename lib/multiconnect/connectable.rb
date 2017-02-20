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
          errors = []

          self._connections.each do |connection|
            begin
              result = connection.execute(action, *args)
              return result if result.success?
            rescue => e
              errors << e
            end
          end

          raise Multiconnect::Error::UnsuccessfulRequest.new( class: self, action: action, errors: errors )
        end
      end
    end
  end
end