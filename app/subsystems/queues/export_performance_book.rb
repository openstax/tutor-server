module Queues
  class ExportPerformanceBook
    lev_routine

    protected
    def exec(course:, role:)
      Jobs::ExportPerformanceBookJob.perform_later(course: course, role: role)
    end
  end
end
