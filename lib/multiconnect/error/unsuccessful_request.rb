module Multiconnect
  module Error
    class UnsuccessfulRequest < StandardError
      def initialize(opts = {})
        @class    = opts.fetch :class, nil
        @action   = opts.fetch :action, nil
        @errors   = opts.fetch :errors, []
      end

      def message
        "#{@class}: Failed to request #{@action}#{error_details}"
      end

      private

      def error_details
        if @errors.present?
          " - #{@errors.map(&:message).join(', ')}"
        end
      end

    end
  end
end