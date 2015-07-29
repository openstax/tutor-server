require 'rails_helper'

RSpec.feature 'Administration of queued jobs' do
  before(:all) do
    ActiveJob::Base.queue_adapter = :resque
  end

  after(:all) do
    ActiveJob::Base.queue_adapter = :inline
  end

  scenario 'Viewing the status of jobs' do
    admin = FactoryGirl.create(:user_profile, :administrator)
    course = CreateCourse[name: 'course time']
    user = Entity::User.create!
    role = AddUserAsCourseTeacher[course: course, user: user]

    Tasks::ExportPerformanceReport.perform_later(course: course, role: role)

    stub_current_user(admin)
    visit admin_root_path
    click_link 'Queued jobs'

    expect(current_path).to eq(admin_jobs_path)
    expect(page).to have_css('.job_status', text: 'queued')
  end
end
