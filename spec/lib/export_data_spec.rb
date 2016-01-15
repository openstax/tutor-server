require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

require 'export_data'

RSpec.describe ExportData do
  let!(:course) { CreateCourse[name: 'Physics 101'] }
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
      DatabaseCleaner.start

      VCR.use_cassette("Api_V1_PerformanceReportsController/with_book", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    before(:each) do
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)
      allow(Tasks::Assistants::HomeworkAssistant).to receive(:k_ago_map).with(1) {
        [ [1,1] ]
      }

      SetupPerformanceReportData[course: course,
                                 teacher: teacher,
                                 students: [student_1, student_2, student_3, student_4],
                                 ecosystem: @ecosystem]
      end

    after(:all) do
      DatabaseCleaner.clean
    end

    after(:each) do
      File.delete(@output_filename) if !@output_filename.nil? && File.exists?(@output_filename)
    end

    it 'exports data as a xlsx file' do
      @output_filename = ExportData.call
      expect(File.exists?(@output_filename)).to be true
      expect(@output_filename.ends_with? '.xlsx').to be true

      doc = SimpleXlsxReader.open(@output_filename)
      headers = doc.sheets.last.rows.first
      values = doc.sheets.last.rows[1]
      data = Hash[headers.zip(values)]
      step = Tasks::Models::TaskStep.first
      student = CourseMembership::Models::Student.first

      expect(data['Student']).to eq(student.deidentifier)
      expect(data['Course ID']).to eq(course.id)
      expect(data['Period ID']).to eq(period.id)
      expect(data['Step ID']).to eq(step.id)
      expect(data['Step Type']).to eq('Reading')
      expect(data['Group']).to eq(step.group_name)
      expect(data['First Completed At'].beginning_of_minute).to eq(
        step.first_completed_at.beginning_of_minute)
      expect(data['Last Completed At'].beginning_of_minute).to eq(
        step.last_completed_at.beginning_of_minute)
      expect(data['URL']).to eq(step.tasked.url)
      expect(data['Correct Answer ID']).to eq(nil)
      expect(data['Answer ID']).to eq(nil)
      expect(data['Correct?']).to eq(nil)
      expect(data['Free Response']).to eq(nil)
      expect(data['Tags']).to eq(nil)
    end
  end
end
