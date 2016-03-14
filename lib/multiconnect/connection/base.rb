module Multiconnect
  module Connection
    class Base

      def initialize(options)
        @client = options.fetch :client, nil
        @except = options.fetch :except, []
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
        if @except.include? action
          Result.new 
        else
          Result.new status: Result::SUCCESS, data: request(action, *args), connection: self.class
        end

      rescue => e
        report_error(e)
        Result.new
      end
    end
  end
end