module Queues
  class ExportPerformanceBook
    lev_routine

    protected
    def exec
      Jobs::ExportPerformanceBookJob.perform_later
    end
  end
end
