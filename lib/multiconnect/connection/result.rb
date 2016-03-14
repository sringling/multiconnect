module Multiconnect
  module Connection
    class Result
      SUCCESS = :success
      FAILURE = :failure
      
      def initialize(opts)
        @status = opts.fetch :status, FAILURE
        @data = opts.fetch :data, nil
        @connection = opts.fetch :connection
      end

      def successful?
        @status == SUCCESS
      end

      def failure?
        @status == FAILURE
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