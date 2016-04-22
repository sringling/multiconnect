# Multiconnect

Multiconnect is a way to manage your server connection fallbacks.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'multiconnect'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install multiconnect

## Example

Let's say you have a server you're connecting to whose uptime is not as reliable as you would like and you want to have a cache fallback. Multiconnect is a pretty easy way to deal with that systemwide.

Let's take a look at what such a class would look like to begin with:

```ruby
class Shoe

  def initialize(json)
    # populate object
  end

  def self.find(id)
    url = URI('http://example.com/shoes?id=#{id}')
    response = Net::HTTP.get(url)
    self.new response
  end

  def self.search(args)
    url = URI('http://example.com/shoes/search?#{args}')
    response = Net::HTTP.get(url)
    # parsing. whatever
  end
end
```

In order to add caching, you could certainly add a `rescue` block to your code, like

```ruby

  def self.find(id)
    url = URI('http://example.com/shoes?id=#{id}')

    begin
      response = Net::HTTP.get(url)
      self.new response

      # cache for later use
      Rails.cache.write url, response

    rescue SocketError => e
      json = Rails.fetch url
      self.new json
    end
  end

  def self.search(args)
    url = URI('http://example.com/shoes/search?#{args}')

    begin
      response = Net::HTTP.get(url)
      # parsing. whatever

      Rails.cache.write url, response

    rescue SocketError => e
      json = Rails.fetch url
      # more parsing
    end
  end
```

And that probably works, ok, but now you have to replicate that code in every model for every action. That's weaksauce. 

## Usage

Multiconnect handles the rescuing and looping through connections for you. Here's what the code above would look like with Multiconnect

Your 2 connections here would be the connection that talks to the server, and the one that does the cache fallback

```ruby
class ServerConnection < Multiconnect::Connection::Base

  # we'll assume that the URL strucure is example.com/:action?:args
  def request(action, *args)
    url = URI('http://example.com/#{action}?#{args}')

    response = Net::HTTP.get(url)
    
    # Still need to cache here
    Rails.cache.write url, response

    response
  end

  def report_error( e )
    # probably report to Honeybadger, or log it, or something.
  end
end

class CacheConnection < Multiconnect::Connection::Base
  def report_error(e)
    # don't care about cache misses
  end

  def request(action, *args)
    # this is a dumb key, obviously
    key = "#{action}/#{args}"
    Rails.cache.fetch key
  end
end
```

Now that we have the connections all set up, `Shoe` will look more like this:

```ruby
class Shoe
  include Multiconnect::Connectable

  add_connection ServerConnection
  add_connection CacheConnection

  class << self
    def find(id)
      self.new( execute( "shoes", id: id ) )
    end

    def search(args)
      json = execute( "shoes/search", args ) )
      # parsing here. You get the idea 
    end

    private

    def execute( action, opts )
      
      response = request( action, opts )
      self.new(response.data)

    rescue Multiconnect::Error::UnsuccessfulRequest => e
      
      # well, that was a total disaster
      Rails.logger.error(e)

    end
  end
end
```

And now you can add as many connections as you want, and your `find` and `search` methods will change none. 

## Objects and helpers

### Result object

Every connection returns a `Multiconnect::Connection::Result` obejct. It responds to `data`, `success?`, and `using_fallback?(connection)`. Method missing delegates just about everything else to the data object.

* `data` is the data returned from the call. a failed call will have `nil` as data
* `success?` will return whether the connection attempt succeeded
* `using_fallback?` takes a connection class, and returns whether it is the successful connection.

### request( action, *args )

Handles looping through the connections and returns the `Result` of the first one that succeeds.

### add_connection( connection, options = {} )

Adds a connecion to the list that `request` loops through.

### prepend_connection( connection, options = {} )

Prepends a connection to the front of the list. Useful if you have a generalized class that defines a set of connections and you want an inheriting model to hit a different connection first. e.g. try cache first strategy.

## Connection methods

### request( action, *args )

This is what does the actual request. This method should contain little to no logic. It should be just the very core connection code. For example, if you have scoping, it should be outside of this method.

For examples of more complex connections have a look in the [examples file](/example_connections.rb)

### report_error( e )

Whenever a connection encounters and error, it sends it here. 

### client

Normally the url structure would be more complex and there would be a client class that would handle the URL building and the actual call. 

For example, if you are wrapping a [JsonApiClient](https://github.com/chingor13/json_api_client), you would pass in the object that handles that particular object, like

```ruby
class Shoe
  # client class for requests, like where and search
  self.client_class = Example::Client::Shoe
  
  # client for self. requests, like save and update_attributes
  attr_accessor :client

  add_connection JsonApiServerConnection, client: self.client_class

  def initialize(client = nil)
    self.client = client || self.client_class.new
    # init
  end

  class << self
    def where(opts)
      self.new request(:where, opts)
    end

    def find(id)
      self.new request(:find, id: id)
    end
  end

  def save
    # execute is the method that the request helper method calls. 
    connection.execute(:save).success?
  end

  def update_attributes(opts)
    connection.execute(:update_attributes, opts).success?
  end

  private

  def connection
    @connection ||= JsonApiServerConnection.new(client)
  end
end
```

where `JsonApiServerConnection` looks something like

```ruby
class ServerConnection < Multiconnect::Connection::Base

  def request(action, *args)
    client.send action, *args

  # 404 is an empty set and a valid non-failed response
  rescue JsonApiClient::Errors::NotFound => e
    JsonApiClient::ResultSet.new([])
  end
end
```

For example usage of the exact scenario above, you can look at [JsonApiResource](https://github.com/avvo/json_api_resource) for a base client wrapper with a single connection, and [JsonApiResourceConnections](https://github.com/avvo/json_api_resource_connections) for circuitbreaker and cache connections.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

1. Fork it ( https://github.com/gaorlov/multiconnect/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
