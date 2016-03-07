module Multiconnect
  module Connection
    class Base

      def initialize(client)
        @client = client
      end

      def client
        @client
      end

      def request(action, *args)
        raise NotImplementedError
      end

      def report_error(e)
        raise NotImplementedError
      end

      def execute(action, *args)

        Result.new status: Result::SUCCESS, data: request(action, *args)

      rescue => e
        report_error(e)
        Result.new
      end
    end
  end
end
