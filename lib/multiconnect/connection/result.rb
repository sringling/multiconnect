module Multiconnect
  module Connection
    class Result
      instance_methods.each do |m|
        undef_method(m) if m.to_s !~ /(?:^__|^nil?$|^send$|^object_id$|^success?$|^data$|^using_fallback?$)/
      end

      SUCCESS = :success
      FAILURE = :failure

      def initialize(opts = {})
        @status     = opts.fetch :status, FAILURE
        @connection = opts.fetch :connection, nil
        @data       = opts.fetch :data, nil
      end

      def success?
        @status == SUCCESS
      end

      def data
        @data
      end

      def using_fallback?(connection)
        @connection == connection
      end

      def method_missing(method, *args, &block)
        @data.send method, *args, &block
      end
    end
  end
end