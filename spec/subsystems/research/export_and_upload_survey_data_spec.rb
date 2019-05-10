require 'rails_helper'

RSpec.describe Research::ExportAndUploadSurveyData, type: :routine do
  before(:all) do
    study_course = FactoryBot.create :research_study_course
    course = study_course.course
    period = FactoryBot.create :course_membership_period, course: course
    study = study_course.study
    @survey_plan = FactoryBot.create :research_survey_plan, study: study

    @teacher = FactoryBot.create :user

    @student_1 = FactoryBot.create :user
    @student_2 = FactoryBot.create :user
    @student_3 = FactoryBot.create :user
    @student_4 = FactoryBot.create :user

    AddUserAsCourseTeacher.call user: @teacher, course: course
    AddUserAsPeriodStudent.call user: @student_1, period: period
    AddUserAsPeriodStudent.call user: @student_2, period: period
    AddUserAsPeriodStudent.call user: @student_3, period: period
    AddUserAsPeriodStudent.call user: @student_4, period: period

    Research::PublishSurveyPlan.call survey_plan: @survey_plan

    @survey_plan.surveys.first(3).each_with_index do |survey, index|
      response = { question1: 18 + index, question2: index }
      response[:hah_users_can_add_their_own_fields] = true if index == 2

      Research::CompleteSurvey.call(survey: survey, response: response)
    end
  end

  it 'exports survey data to Box as a csv file' do
    # We replace the uploading of the survey data with the test case itself
    with_export_rows(survey_plan: @survey_plan) do |rows|
      headers = rows.first
      field_names = headers[1..-1]

      responses_by_research_identifier = @survey_plan.surveys
        .joins(student: :role)
        .pluck(Entity::Role.arel_table[:research_identifier], :survey_js_response)
        .to_h

      rows[1..-1].each do |row|
        data = headers.zip(row).to_h
        research_identifier = data['Student Research Identifier']
        response_hash = responses_by_research_identifier.fetch(research_identifier)

        if response_hash.nil?
          row[1..-1].each { |field_value| expect(field_value).to be_nil }
        else
          expect(response_hash.size).to be_in [2, 3]

          response_hash.each do |field_name, field_value|
            csv_value = case field_value
            when TrueClass
              1
            when FalseClass
              0
            else
              field_value
            end.to_s

            expect(data[field_name]).to eq csv_value
          end
        end
      end
    end
  end

  def with_export_rows(survey_plan:, &block)
    expect(Box).to receive(:upload_files) do |zip_filename:, files:|
      expect(files.size).to eq 1
      file = files.first
      expect(File.exist?(file)).to be true
      expect(file.ends_with? '.csv').to be true
      rows = CSV.read(file)
      block.call(rows)
    end

    described_class.call(survey_plan: survey_plan)
  end
end
