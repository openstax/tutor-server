require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe ExportAndUploadResearchData, type: :routine do
  let(:course) do
    FactoryGirl.create :course_profile_course,
                       :with_assistants,
                       time_zone: ::TimeZone.new(name: 'Central Time (US & Canada)')
  end
  let!(:period) { FactoryGirl.create :course_membership_period, course: course }

  let(:teacher) { FactoryGirl.create(:user) }
  let(:teacher_token) do
    FactoryGirl.create :doorkeeper_access_token, resource_owner_id: teacher.id
  end

  let(:student_1) do
    FactoryGirl.create :user, first_name: 'Student', last_name: 'One', full_name: 'Student One'
  end
  let(:student_1_token) do
    FactoryGirl.create :doorkeeper_access_token, resource_owner_id: student_1.id
  end

  let(:student_2) do
    FactoryGirl.create :user, first_name: 'Student', last_name: 'Two', full_name: 'Student Two'
  end

  let(:student_3) do
    FactoryGirl.create :user, first_name: 'Student', last_name: 'Three', full_name: 'Student Three'
  end

  let(:student_4) do
    FactoryGirl.create :user, first_name: 'Student', last_name: 'Four', full_name: 'Student Four'
  end

  let(:all_task_types) { Tasks::Models::Task.task_types.values }

  context 'with book' do
    before(:all) do
      VCR.use_cassette("Api_V1_PerformanceReportsController/with_book", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    before(:each) do
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)

      SetupPerformanceReportData[course: course,
                                 teacher: teacher,
                                 students: [student_1, student_2, student_3, student_4],
                                 ecosystem: @ecosystem]
      end

    it 'exports research data as a csv file' do
      # We replace the uploading of the research data with the test case itself
      with_export_rows(all_task_types) do |rows|
        headers = rows.first

        step_id_index = headers.index('Step ID')
        step_ids = rows.map { |row| row[step_id_index] }
        steps_by_id = Tasks::Models::TaskStep
          .where(id: step_ids)
          .preload(:tasked, task: [ :time_zone, taskings: :role ])
          .index_by(&:id)

        period_ids = course.periods.map { |period| period.id.to_s }

        rows[1..-1].each do |row|
          data = headers.zip(row).to_h
          step = steps_by_id.fetch(data['Step ID'].to_i)
          task = step.task
          tasked = step.tasked
          url = tasked.respond_to?(:url) ? tasked.url : nil
          correct_answer_id = step.exercise? ? tasked.correct_answer_id : nil
          answer_id = step.exercise? ? tasked.answer_id : nil
          correct = step.exercise? ? tasked.is_correct?.to_s : nil
          free_response = step.exercise? ? tasked.free_response : nil
          tags = step.exercise? ? tasked.tags.join(',') : nil

          expect(data['Student']).to eq(task.taskings.first.role.research_identifier)
          expect(data['Course ID']).to eq(course.id.to_s)
          expect(data['CC?']).to eq("FALSE")
          expect(data['Period ID']).to be_in(period_ids)
          expect(data['Step Type']).to eq(step.tasked_type.match(/Tasked(.+)\z/).try!(:[], 1))
          expect(data['Group']).to eq(step.group_name)
          expect(data['First Completed At']).to eq(format_time(step.first_completed_at))
          expect(data['Last Completed At']).to eq(format_time(step.last_completed_at))
          expect(data['Opens At']).to eq(format_time(task.opens_at))
          expect(data['Due At']).to eq(format_time(task.due_at))
          expect(data['URL']).to eq(url)
          expect(data['Correct Answer ID']).to eq(correct_answer_id)
          expect(data['Answer ID']).to eq(answer_id)
          expect(data['Correct?']).to eq(correct)
          expect(data['Free Response']).to eq(free_response)
          expect(data['Tags']).to eq(tags)
        end
      end
    end

    it 'uploads the exported data to Box' do
      # We simply test that the call to HTTParty is made properly
      file_regex_string = 'export_\d+T\d+Z.csv'
      webdav_url_regex = Regexp.new "#{described_class::WEBDAV_URL}/#{file_regex_string}"
      expect(HTTParty).to receive(:put).with(
        webdav_url_regex,
        basic_auth: {
          username: a_kind_of(String).or(be_nil),
          password: a_kind_of(String).or(be_nil)
        },
        body_stream: a_kind_of(File),
        headers: { 'Transfer-Encoding' => 'chunked' }
      ).and_return OpenStruct.new(success?: true)

      # Trigger the data export
      capture_stdout{ described_class.call(task_types: all_task_types) }
    end


  end

  context "data to export can be filtered" do
    before(:each) do
      cc_tasks = 2.times.map do
        FactoryGirl.create :tasks_task, task_type: :concept_coach,
                                        step_types: [:tasks_tasked_exercise],
                                        num_random_taskings: 1
      end

      reading_task = FactoryGirl.create :tasks_task, task_type: :reading,
                                                     step_types: [:tasks_tasked_reading],
                                                     num_random_taskings: 1

      (cc_tasks + [reading_task]).each do |task|
        role = task.taskings.first.role

        FactoryGirl.create :course_membership_student, course: course, role: role
      end
    end

    specify "by date range" do
      Timecop.freeze(Date.today - 30) do
        old_reading_task = FactoryGirl.create :tasks_task, step_types: [:tasks_tasked_reading],
                                                           num_random_taskings: 1

        role = old_reading_task.taskings.first.role

        FactoryGirl.create :course_membership_student, course: course, role: role
      end

      with_export_rows(all_task_types, Date.today - 10, Date.tomorrow) do |rows|
        expect(Tasks::Models::TaskStep.count).to eq 4
        expect(rows.count - 1).to eq(3)
      end
    end

    context "by application" do
      let(:tutor_task_types) do
        Tasks::Models::Task.task_types.values_at(
          :homework, :reading, :chapter_practice, :page_practice,
          :mixed_practice, :external, :event, :extra
        )
      end
      let(:cc_task_types) { Tasks::Models::Task.task_types.values_at(:concept_coach) }

      specify "only Concept Coach" do
        with_export_rows(cc_task_types) do |rows|
          expect(Tasks::Models::TaskStep.count).to eq 3
          expect(rows.count - 1).to eq(2)
        end
      end

      specify "only Tutor" do
        with_export_rows(tutor_task_types) do |rows|
          expect(Tasks::Models::TaskStep.count).to eq 3
          expect(rows.count - 1).to eq(1)
        end
      end

      specify "Tutor and Concept Coach" do
        with_export_rows(all_task_types) do |rows|
          expect(Tasks::Models::TaskStep.count).to eq 3
          expect(rows.count - 1).to eq(3)
        end
      end
    end
  end
end

def with_export_rows(task_types = [], from = nil, to = nil, &block)
  expect_any_instance_of(described_class).to receive(:upload_export_file) do |routine|
    filepath = routine.send :filepath
    expect(File.exist?(filepath)).to be true
    expect(filepath.ends_with? '.csv').to be true
    rows = CSV.read(filepath)
    block.call(rows)
  end

  capture_stdout{ described_class.call(task_types: task_types, from: from, to: to) }
end

def format_time(time)
  return time if time.blank?
  time.utc.iso8601
end
