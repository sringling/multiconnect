module Multiconnect
  module Connection
    class Result
      SUCCESS = :success
      FAILURE = :failure
      attr_accessor :status, :data

      def initialize(opts)
        self.status = opts.fetch :status, FAILURE
        self.status = opts.fetch :data, nil
      end

      def successful?
        status == SUCCESS
      end

      def failure?
        status == FAILURE
      end
    end
  end
end