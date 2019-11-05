module Stats
  module Models
    class Interval < ApplicationRecord

      attr_reader :courses

      after_initialize do
        @courses = OpenStruct.new
      end

      def range
        @range ||= (starts_at ... ends_at)
      end
      #   super(interval:)
      #   @interval = interval
      #   @stats = OpenStruct.new
      # end

    end
  end
end
