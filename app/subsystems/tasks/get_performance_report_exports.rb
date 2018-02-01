module Tasks
  class GetPerformanceReportExports
    lev_routine express_output: :exports

    protected
    def exec(course:, role:)
      exports = Tasks::Models::PerformanceReportExport.where(course: course, role: role)
      outputs[:exports] = exports.map do |export|
        {
          filename: export.filename,
          url: export.url,
          created_at: export.created_at
        }
      end
    end
  end
end
