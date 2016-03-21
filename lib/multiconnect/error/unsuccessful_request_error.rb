module Multiconnect
  module Error
    class UnsuccessfulRequestError < StandardError
      def initialize(opts = {})
        @class    = opts.fetch :class, nil
        @action   = opts.fetch :action, nil
      end

      def message
        "#{@class}: Failed to request #{@action}"
      end
    end
  end
end