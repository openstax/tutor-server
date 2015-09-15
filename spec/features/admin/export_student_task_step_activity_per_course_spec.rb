require 'rails_helper'
require 'vcr_helper'
require 'feature_js_helper'
require 'database_cleaner'

RSpec.feature 'Administration: export student task step activity per course', js: true do
  let!(:course) { CreateCourse[name: 'Physics 101'] }
  let!(:period) { CreatePeriod[course: course] }

  let(:student_1) { FactoryGirl.create :user_profile,
                                       first_name: 'Student',
                                       last_name: 'One',
                                       full_name: 'Student One' }

  let(:student_2) { FactoryGirl.create :user_profile,
                                       first_name: 'Student',
                                       last_name: 'Two',
                                       full_name: 'Student Two' }

  let(:time) { Time.current }

  before(:all) do
    DatabaseCleaner.start

    VCR.use_cassette("Admin/ExportStudentActivity", VCR_OPTS) do
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

  scenario 'obtain CSV for a single course' do
    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    visit admin_root_path
    click_link 'Courses'

    formatted_time = time.strftime('%Y-%m-%d-%H-%M-%S-%L')
      # year - month - day - 24-hour clock hour - minute - second - millisecond
    allow(Time).to receive(:current) { time }
      # Timecop won't freeze the subsequent controller action
    click_link 'Export activity'

    expect(page).not_to have_link('Export activity')
    expect(page).to have_link('Download',
                              href: "/admin/exports/good_course_#{formatted_time}.csv")
  end

  scenario 'obtain CSVs in a Zip file for multiple courses'
end
