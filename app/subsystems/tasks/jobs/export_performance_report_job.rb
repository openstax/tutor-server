module Tasks
  module Jobs
    class ExportPerformanceReportJob < ActiveJob::Base
      queue_as :default

      def perform(role:, course:)
        ExportPerformanceReport[course: course, role: role]
      end
    end
  end
end
