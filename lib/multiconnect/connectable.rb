module Multiconnect
  module Connectable
    extend ActiveSupport::Concern

    included do
      class << self
        class_attribute :_connections
        
        def add_connection(connection, options = {})
          connection_class = options.fetch :class, "#{connection.to_s}_connection".camelize.constatnize
          connection_client_class = options.delete :client, nil

          self._connections = _connections + [connection_class.new(options)]
        rescue NameError => e
          raise "#{e.message}. Cannot find the connection class. Pass in the :class option if you have a weird path"
        end

        def request(acrion, *args)
          connections.each do |connection|
            result = connection.execute(action, *args)
            return result.data if result.successful?
          end
        end
      end
    end
  end
end