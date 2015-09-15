require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'


module Tasks
  RSpec.describe GetStudentActivity do
    let!(:course) { CreateCourse[name: 'Physics 101'] }
    let!(:period) { CreatePeriod[course: course] }

    let(:time) { Time.current }
    let(:reading_due_at) { time + 1.week }
    let(:homework1_due_at) { time + 1.day }
    let(:homework2_due_at) { time + 2.weeks }

    let(:student_1) { FactoryGirl.create :user_profile,
                                         first_name: 'Student',
                                         last_name: 'One',
                                         full_name: 'Student One' }

    let(:student_2) { FactoryGirl.create :user_profile,
                                         first_name: 'Student',
                                         last_name: 'Two',
                                         full_name: 'Student Two' }

    before(:all) do
      DatabaseCleaner.start

      VCR.use_cassette("GetStudentActivity", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    before do
      allow(Tasks::Assistants::HomeworkAssistant).to receive(:k_ago_map).with(1) {
        [ [1,1] ]
      }

      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)

      Timecop.freeze(time) do
        SetupPerformanceReportData[course: course,
                                   teacher: FactoryGirl.create(:user_profile),
                                   students: [student_1, student_2],
                                   ecosystem: @ecosystem]
      end
    end


    it 'returns all the student task step activity' do
      results = GetStudentActivity[course: course]

      expect(results).to include({
        headers: ['title', 'type', 'status', 'exercise count', 'recovered exercise count',
                  'due at', 'last worked', 'can be recovered', 'url', 'free response',
                  'answer id', 'book location', 'first name', 'last name']
      })

      expect(results['data']).to include(
        ["Homework task plan", "homework", "completed", 6, nil, homework1_due_at.to_s,
         nil, nil, nil, nil, nil, nil, "Student", "One"]
      )

      expect(results['data']).to include(
        ["Homework task plan", "homework", "in_progress", 6, nil, homework1_due_at.to_s,
         nil, nil, nil, nil, nil, nil, "Student", "Two"]
      )

      expect(results['data']).to include(
        ["Reading task plan", "reading", "completed", 4, nil, reading_due_at.to_s, nil,
         nil, nil, nil, nil, nil, "Student", "One"]
      )

      expect(results['data']).to include(
        [nil, nil, nil, nil, nil, "", nil, false,
         "https://exercises-dev.openstax.org/exercises/152@2",
         "A sentence explaining all the things!", "23094", nil, nil, nil]
      )
    end
  end
end
