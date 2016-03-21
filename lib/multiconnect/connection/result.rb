module Multiconnect
  module Connection
    class Result
      SUCCESS = :success
      FAILURE = :failure
      
      def initialize(opts = {})
        @status = opts.fetch :status, FAILURE
        @data = opts.fetch :data, nil
        @connection = opts.fetch :connection, nil
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