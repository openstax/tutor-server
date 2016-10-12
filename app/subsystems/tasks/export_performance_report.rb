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

      begin
        @temp_filepath = generate_temp_export_file!(format, course.is_concept_coach)

        export = File.open(@temp_filepath) do |file|
          Models::PerformanceReportExport.create!(
            course: course,
            role: role,
            export: file
          )
        end

        outputs.filepath = export.export.path
      ensure
        # Cleanup the temp file after it has been moved to the uploads folder
        File.delete(@temp_filepath) unless @temp_filepath.nil? || \
                                           @temp_filepath == outputs.filepath
      end

      status.save(url: export.url)
    end

    private

    def generate_temp_export_file!(format, is_cc)
      klass = "Tasks::PerformanceReport::Export#{is_cc ? 'Cc' : ''}#{format.to_s.camelize}"
      exporter = klass.constantize
      filename = [FilenameSanitizer.sanitize(outputs.profile.name),
                  'Scores',
                  Time.now.utc.strftime("%Y%m%d-%H%M%S")].join('_')

      exporter[profile: outputs.profile,
               report: outputs.performance_report,
               filename: "./tmp/#{filename}"]
    end
  end
end
