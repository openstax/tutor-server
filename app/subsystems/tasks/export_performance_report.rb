module Tasks
  class ExportPerformanceReport
    lev_routine express_output: :filepath

    uses_routine GetCourseProfile,
      translations: { outputs: { type: :verbatim } },
      as: :get_course_profile

    uses_routine GetPerformanceReport,
      translations: { outputs: { type: :verbatim } },
      as: :get_performance_report

    protected
    def exec(role:, course:, format: :xlsx)
      run(:get_course_profile, course: course)
      run(:get_performance_report, course: course, role: role)

      outputs.filepath = generate_export_file!(format)

      export = Models::PerformanceReportExport.create!(
        course: course,
        role: role,
        export: File.open(outputs.filepath)
      )

      status.save({ url: export.url })
    end

    private
    def generate_export_file!(format)
      klass = "Tasks::PerformanceReport::WriteToFile::#{format.to_s.camelize}"
      exporter = klass.constantize
      filename = [outputs.profile.name,
                  'Performance',
                  Time.current.strftime("%Y%m%d-%H%M%S")].join('_')

      exporter[profile: outputs.profile,
               report: outputs.performance_report,
               filename: "./tmp/#{filename}"]
    end
  end
end
