class ServerConnection < Multiconnect::Connection::Base
  
  def report_error(e)
    Honeybadger.notify(e)
  end

  def request(action, *args)
    client_args = args.deep_dup
    result = self.client.send action, *client_args

    if result.is_a? JsonApiClient::Scope
      result = result.all
    end

    result

  rescue JsonApiClient::Errors::NotFound => e
    result = JsonApiClient::ResultSet.new

    result.meta = {status: status}

    result.errors = ActiveModel::Errors.new(result)
    result.errors.add("NofFound", e.message)

    result
  end
end
  

class CacheFallbackConnection < Multiconnect::Connection::Base

  def report_error(e)
  end

  def request(action, *args)
    key = sorted_args(args)
    Rails.cache.fetch key
  end
end


class CacheFirstToCircuitBreakerServerConnection < CircuitBreakerServerConnection

  def report_error(e)
    Honeybadger.notify(e)
    InfluxDB.notify(e)
  end

  def request(action, *args)
    key = key_from_args( *args )
    Rails.cache.fetch key do
      super
    end
  end

  private

  def key_from_args( *args )
    # downcase everything and sort the keys alpabetically so that {q: "dui", loc: "seattle"} is the same as {loc:"seattle", q: "dui"}
  end
end

class CircuitBreakerServerConnection < Multiconnect::Connection::Base

  def report_error(e)
    Honeybadger.notify(e)
    InfluxDB.notify(e)
  end

  def request(action, *args)
    if ready_for_request?
      client_args = args.deep_dup
      result = self.client.send action, *client_args

      if result.is_a? JsonApiClient::Scope
        result = result.all
      end

      result
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
