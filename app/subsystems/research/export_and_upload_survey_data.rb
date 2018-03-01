class Research::ExportAndUploadSurveyData

  lev_routine active_job_enqueue_options: { queue: :lowest_priority },
              express_output: :filename,
              transaction: :no_transaction

  def exec(survey_plan:, filename: nil)
    filename = FilenameSanitizer.sanitize(filename) ||
               "survey_#{survey_plan.id}_#{Time.current.strftime("%Y%m%dT%H%M%SZ")}.csv"

    nested_transaction = ActiveRecord::Base.connection.transaction_open?
    file = ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(
        'SET TRANSACTION ISOLATION LEVEL SERIALIZABLE READ ONLY DEFERRABLE'
      ) unless nested_transaction

      create_survey_export_file survey_plan: survey_plan, filename: filename
    end

    zip_filename = "#{filename.gsub(File.extname(filename), '')}.zip"
    Box.upload_files zip_filename: zip_filename, files: [ file ]

    File.delete(file) if File.exist?(file)

    outputs.filename = filename
  end

  protected

  def create_survey_export_file(survey_plan:, filename:)
    surveys = survey_plan.surveys
      .select(:id, '"entity_roles"."research_identifier"', :survey_js_response)
      .joins(student: :role)

    field_names = results.map(&:survey_js_response).flat_map(&:keys).uniq

    File.join('tmp', 'exports', filename).tap do |filepath|
      CSV.open(filepath, 'w') do |file|
        file << [ 'Student Research Identifier' ] + field_names

        surveys.each do |survey|
          begin
            response_hash = survey.survey_js_response

            row = [ survey.research_identifier ] + field_names.map do |field_name|
              response = response_hash[field_name]

              case response
              when TrueClass
                1
              when FalseClass
                0
              else
                response
              end
            end

            file << row
          rescue StandardError => ex
            raise ex if !Rails.env.production? || ex.is_a?(Timeout::Error)

            Rails.logger.error do
              "Skipped survey #{survey.id} due to #{ex.inspect} @ #{ex.backtrace.first}"
            end
          end
        end
      end
    end
  end

end
