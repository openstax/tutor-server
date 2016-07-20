require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe ExportAndUploadResearchData, type: :routine do
  let!(:course) { CreateCourse[
    name: 'Physics 101',
    time_zone: ::TimeZone.new(name: 'Central Time (US & Canada)')
  ] }
  let!(:period) { CreatePeriod[course: course] }
  let(:teacher) { FactoryGirl.create(:user) }
  let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                                           resource_owner_id: teacher.id }
  let(:student_1) { FactoryGirl.create(:user, first_name: 'Student',
                                              last_name: 'One',
                                              full_name: 'Student One') }
  let(:student_1_token) { FactoryGirl.create :doorkeeper_access_token,
                                             resource_owner_id: student_1.id }

  let(:student_2) { FactoryGirl.create(:user, first_name: 'Student',
                                              last_name: 'Two',
                                              full_name: 'Student Two') }

  let(:student_3) { FactoryGirl.create(:user, first_name: 'Student',
                                              last_name: 'Three',
                                              full_name: 'Student Three') }

  let(:student_4) { FactoryGirl.create(:user, first_name: 'Student',
                                              last_name: 'Four',
                                              full_name: 'Student Four') }

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
      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:k_ago_map).with(1) { [ [1,1] ] }
      )

      SetupPerformanceReportData[course: course,
                                 teacher: teacher,
                                 students: [student_1, student_2, student_3, student_4],
                                 ecosystem: @ecosystem]
      end

    it 'exports research data as a csv file' do
      # We replace the uploading of the research data with the test case itself
      expect_any_instance_of(described_class).to receive(:upload_export_file) do |routine|
        filepath = routine.send :filepath
        expect(File.exists?(filepath)).to be true
        expect(filepath.ends_with? '.csv').to be true

        rows = CSV.read(filepath)
        headers = rows.first
        values = rows.second
        data = Hash[headers.zip(values)]
        step = Tasks::Models::TaskStep.first
        student = CourseMembership::Models::Student.first

        expect(data['Student']).to eq(student.deidentifier)
        expect(data['Course ID']).to eq(course.id.to_s)
        expect(data['Period ID']).to eq(period.id.to_s)
        expect(data['Step ID']).to eq(step.id.to_s)
        expect(data['Step Type']).to eq('Reading')
        expect(data['Group']).to eq(step.group_name)
        expect(data['First Completed At']).to eq(step.first_completed_at.utc.iso8601)
        expect(data['Last Completed At']).to eq(step.last_completed_at.utc.iso8601)
        expect(data['Opens At']).to eq(step.task.opens_at.utc.iso8601)
        expect(data['Due At']).to eq(step.task.due_at.utc.iso8601)
        expect(data['URL']).to eq(step.tasked.url)
        expect(data['Correct Answer ID']).to eq(nil)
        expect(data['Answer ID']).to eq(nil)
        expect(data['Correct?']).to eq(nil)
        expect(data['Free Response']).to eq(nil)
        expect(data['Tags']).to eq(nil)
      end

      # Trigger the data export
      capture_stdout{ described_class.call }
    end

    it 'uploads the exported data to owncloud' do
      # We simply test that the call to HTTParty is made properly
      file_regex_string = 'export_\d+T\d+Z.csv'
      webdav_url_regex = Regexp.new "#{described_class::WEBDAV_BASE_URL}/#{file_regex_string}"
      expect(HTTParty).to receive(:put).with(
        webdav_url_regex,
        basic_auth: { username: a_kind_of(String).or(be_nil),
                      password: a_kind_of(String).or(be_nil) },
        body_stream: a_kind_of(File),
        headers: { 'Transfer-Encoding' => 'chunked' }
      ).and_return OpenStruct.new(success?: true)

      # Trigger the data export
      capture_stdout{ described_class.call }
    end
  end
end
