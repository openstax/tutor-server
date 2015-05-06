module Queues
  module Jobs
    class ExportPerformanceBookJob < ActiveJob::Base
      queue_as :default

      def perform(role:, course:)
        Tasks::ExportPerformanceBook[course: course, role: role]
      end
    end
  end
end
