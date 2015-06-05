module Tasks
  class GetPerformanceReportExports
    lev_routine express_output: :exports

    protected
    def exec(course:, role:)
      exports = Models::PerformanceReportExport.where(course: course, role: role)
      outputs[:exports] = exports.collect do |export|
        {
          filename: export.filename,
          url: export.url,
          created_at: export.created_at
        }
      end
    end
  end
end
