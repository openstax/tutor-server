module Tasks
  class ExportPerformanceReport
    lev_routine express_output: :output_filename

    uses_routine GetCourseProfile,
      translations: { outputs: { type: :verbatim } },
      as: :get_course_profile

    uses_routine GetPerformanceReport,
      translations: { outputs: { type: :verbatim } },
      as: :get_performance_report

    protected
    def exec(role:, course:, format: :xlsx)
      export_file_writer = const_get("PerformanceReport::WriteToFile::#{format.camelize}")

      run(:get_course_profile, course: course)
      run(:get_performance_report, course: course, role: role)

      outputs.filepath = tmp_file_path

      export_file_writer[profile: outputs.profile,
                         report: outputs.performance_report,
                         filepath: outputs.filepath]

      export = Models::PerformanceReportExport.create!(
        course: course,
        role: role,
        export: File.open(outputs.filepath)
      )

      status.save({ url: export.url })
    end

    private
    def tmp_file_path
      @tmp_file_path ||= ['./tmp/', generate_file_name, '.xlsx'].join('')
    end

    def generate_file_name
      [outputs.profile.name, '_Performance_',
       Time.current.strftime("%Y%m%d-%H%M%S")].join('')
    end
  end
end
