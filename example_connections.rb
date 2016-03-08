

# crude implementation without resource helpers
class Object << JsonApiResource::Resource
  add_connection :cache_first, client: client_class # no autmatic fallthrough to the server IN the connection. No client_class because it'll use Rails.cache
                                  # Solicitor::Client::Lawyer
  add_connection :server, client: client_class, class: CircuitBreakerServerConnection
  add_connection :cache_fallback # no use trying to hit the client now. We laready know the server is unresponsive
  add_connection :default_values, client: self
end


module JsonApiResource
  module Connection
    class ServerConnection < Multiconnect::Connection::Base
      
      def report_error(e)
        Honeybadger.notify(e)
      end

      def request(action, *args)
        client.send action, *args

      catch JsonApiClient::Errors::NotFound => e
        result = JsonApiClient::ResultSet.new

        result.meta = {status: status}

        result.errors = ActiveModel::Errors.new(result)
        result.errors.add("NofFound", e.message)

        result
      end
    end
  end
end
      

module JsonApiResource
  module Connection
    class CacheFallbackConnection < Multiconnect::Connection::Base

      def report_error(e)
      end

      def request(action, *args)
        key = sorted_args(args)
        Rails.cache.fetch key
      end
    end
  end
end


module JsonApiResource
  module Connection
    class CacheFirstToCircuitBreakerServerConnection < CircuitBreakerServerConnection

      def report_error(e)
        Honeybadger.notify(e)
        InfluxDB.notify(e)
      end

      def request(action, *args)
        key = key_from_args(args)
        Rails.cache.fetch key do
          super
        end
      end

      private

      def key_from_args(args)
        # downcase everything and sort the keys alpabetically so that {q: "dui", loc: "seattle"} is the same as {loc:"seattle", q: "dui"}
      end
    end
  end
end

module JsonApiResource
  module Connection
    class CircuitBreakerServerConnection < Multiconnect::Connection::Base

      def report_error(e)
        Honeybadger.notify(e)
        InfluxDB.notify(e)
      end

      def request(action, *args)
        if ready_for_request?
          client.send(action, *args)
        else
          raise "fall through!"
        end

      catch JsonApiClient::Errors::NotFound => e
        result = JsonApiClient::ResultSet.new

        result.meta = {status: status}

        result.errors = ActiveModel::Errors.new(result)
        result.errors.add( "FileNotFound", e.message )

        result
      catch => e
        @responding = false
        # default circuit broken for 30 seconds. This should probably be 1 - 2 - 5 - 15 - 30 - 1 min - 2 min*
        @timeout = 30.seconds.from.

        # propagate the error up to be handled by Connection::Base
        raise e
      end

      private 

      def ready_for_request?
        @responding || Time.now > @timeout
      end
    end
  end
end