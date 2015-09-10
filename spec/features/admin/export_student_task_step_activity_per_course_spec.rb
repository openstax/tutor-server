require 'rails_helper'
require 'vcr_helper'
require 'feature_js_helper'

RSpec.feature 'Administration: export student task step activity per course',
              vcr: VCR_OPTS, js: true do
  scenario 'obtain CSV for a single course' do
    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    course = CreateCourse[name: 'Good Course']
    CreateStudentHistory[course: course]

    visit admin_root_path
    click_link 'Courses'

    time = Time.current
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
