module Multiconnect
  module Connection
    class Base

      attr_accessor :client

      def initialize(options = {})
        self.client = options.fetch :client, nil
        @except     = Array(options.fetch :except, []).map(&:to_sym)
        @only       = Array(options.fetch :only, []).map(&:to_sym)
      end

      def request(action, *args)
        raise NotImplementedError
      end

      def report_error(e)
        raise NotImplementedError
      end

      def execute(action, *args)
        if allowed?(action)
          Result.new status: Result::SUCCESS, data: request(action, *args), connection: self.class
        else
          Result.new 
        end

      rescue => e
        report_error(e)
        Result.new
      end

      private

      def allowed?(action)
        action = action.to_sym
        allowed_by_only   = @only.blank? || ( @only.present? && @only.include?( action ) )
        allowed_by_except = !@except.include?(action)

        allowed_by_only && allowed_by_except 
      end
    end
  end
end