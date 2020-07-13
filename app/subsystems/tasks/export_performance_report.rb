module Tasks
  class ExportPerformanceReport
    lev_routine express_output: :filepath, use_jobba: true

    uses_routine Tasks::GetPerformanceReport, as: :get_performance_report

    protected
    def exec(course:, role:, performance_report: nil, format: :xlsx, current_time: Time.current)
      if course.frozen_scores?(current_time)
        # PerformanceReportExport has default_scope { order created_at: :desc }
        outputs.filepath = Tasks::Models::PerformanceReportExport.where(
          course: course, role: role
        ).first&.export&.path

        return unless outputs.filepath.nil?
      end

      performance_report ||= run(
        :get_performance_report, course: course, role: role, is_frozen: false
      ).outputs.performance_report

      begin
        @temp_filepath = generate_temp_export_file! course, format, performance_report

        export = File.open(@temp_filepath) do |file|
          Tasks::Models::PerformanceReportExport.create!(
            course: course,
            role: role,
            export: file
          )
        end

        outputs.filepath = export.export.path
      ensure
        # Cleanup the temp file after it has been moved to the uploads folder
        File.delete(@temp_filepath) unless @temp_filepath.nil? || @temp_filepath == outputs.filepath
      end

      status.save(url: export.url)
    end

    private

    def generate_temp_export_file!(course, format, performance_report)
      klass = "Tasks::PerformanceReport::Export#{
        course.pre_wrm_scores? ? 'PreWrm' : ''
      }#{format.to_s.camelize}"
      exporter = klass.constantize
      filename = [
        FilenameSanitizer.sanitize(course.name.first(200)),
        'Scores',
        Time.now.utc.strftime("%Y%m%d-%H%M%S")
      ].join('_')

      exporter.call(
        course: course,
        report: performance_report,
        filename: "./tmp/#{filename}"
      ).outputs.filename
    end
  end
end
