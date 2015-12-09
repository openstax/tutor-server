module Tasks
  class ExportPerformanceReport
    lev_routine outputs: { filepath: :_self },
                uses: [GetCourseProfile, GetPerformanceReport]

    protected
    def exec(role:, course:, format: :xlsx)
      profile = run(:get_course_profile, course: course).profile
      report = run(:get_performance_report, course: course, role: role).performance_report

      begin
        @temp_filepath = generate_temp_export_file!(profile, report, format)

        export = File.open(@temp_filepath) do |file|
          Models::PerformanceReportExport.create!(
            course: course,
            role: role,
            export: file
          )
        end

        set(filepath: export.export.path)
      ensure
        # Cleanup the temp file after it has been moved to the uploads folder
        File.delete(@temp_filepath) unless @temp_filepath.nil? || \
                                           @temp_filepath == result.filepath
      end

      job.save(url: export.url)
    end

    private
    def generate_temp_export_file!(profile, report, format)
      klass = "Tasks::PerformanceReport::Export#{format.to_s.camelize}"
      exporter = klass.constantize
      filename = [profile.name,
                  'Scores',
                  Time.current.strftime("%Y%m%d-%H%M%S")].join('_')

      exporter.call(profile: profile,
                    report: report,
                    filename: "./tmp/#{filename}").filepath
    end
  end
end
