

# crude implementation without resource helpers
class Object << JsonApiResource::Resource
  add_connection CacheFirstToCircuitBreakerServerConnection, client: client_class # no autmatic fallthrough to the server IN the connection. No client_class because it'll use Rails.cache
                                  # Solicitor::Client::Lawyer
  add_connection CircuitBreakerServerConnection, client: client_class
  add_connection CacheFallbackConnection # no use trying to hit the client now. We laready know the server is unresponsive
  add_connection DefaultValueConnection, client: self
end


module JsonApiResource
  module Connection
    class ServerConnection < Multiconnect::Connection::Base
      
      def report_error(e)
        Honeybadger.notify(e)
      end

      def request(action, *args)
        client.send action, *args

      rescue JsonApiClient::Errors::NotFound => e
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
          client.send :find, args
        else
          raise "fall through!"
        end

      rescue JsonApiClient::Errors::NotFound => e
        result = JsonApiClient::ResultSet.new

        result.meta = {status: status}

        result.errors = ActiveModel::Errors.new(result)
        result.errors.add( "FileNotFound", e.message )

        result
      rescue => e
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


class Shoe
  self.client_class = Faraday

  include Multiconnect::Connectable

  # block of connections

  # try to hit the server directly. If the server fails, disallow calls for 30 seconds
  add_connection :server, client: Solicitor::Client::Lawyer, class: CircuitBreakerServerConnection

  # If the server call failed, try to fetch the value from cache. This assumes you cache that somewhere
  add_connection :cache_fallback


  # whatever your client calling code is
  def self.where(opts)
    request opts do
      client.where
  end

  def self.find(opts)
    request(:find, opts).data
  end
end


Shoe.request(key: 'asdf') do |connection_client|
  connection_client.where(foo: 'bar').first
end


class Lawyer < JsonApiResource::Resource
  wraps Solicitor::Client::Lawyer

  self.legal_zoom_client = LZ::Client::Lawyer

  add_connection :avvo_api, client: Faraday
  add_connection :legal_zoom, client: legal_zoom_client

  def self.find(*args)
    request = request( :find, args )
    connection_status = request.connection
    request.data
  end

end

# controler

def show
  @lawyer = Lawyer.find(params[:id])
  render_500 if @lawyer.using_fallback(:cache_fallback)?
end

def search
  @lawyers = Lawyer.search(params)
  
  @lawyers.using_fallback(:cache_fallback)?

end

def index
  @lawyers = Lawyer.where(params[:whatever], per_page: 4, order: :created_at)
end