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

      def empty?
        stats.values.all? {|v| v.to_i == 0 }
      end

    end
  end
end
