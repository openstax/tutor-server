module Tasks
  class GetPerformanceReportExports
    lev_routine outputs: { exports: :_self }

    protected
    def exec(course:, role:)
      exports = Models::PerformanceReportExport.where(course: course, role: role)
      set(exports: exports.collect do |export|
        {
          filename: export.filename,
          url: export.url,
          created_at: export.created_at
        }
      end)
    end
  end
end
