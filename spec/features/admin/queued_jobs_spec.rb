require 'rails_helper'

RSpec.feature 'Administration of queued jobs' do
  let(:course) { CreateCourse[name: 'course time'] }
  let(:admin) { FactoryGirl.create(:user_profile, :administrator) }
  let(:user) { Entity::User.create! }
  let(:role) { AddUserAsCourseTeacher[course: course, user: user] }

  let(:job) { Lev::BackgroundJob.all.last }

  before(:all) do
    ActiveJob::Base.queue_adapter = :resque
  end

  after(:all) do
    ActiveJob::Base.queue_adapter = :inline
  end

  before do
    stub_current_user(admin)
    Tasks::ExportPerformanceReport.perform_later(course: course, role: role)
  end

  scenario 'Viewing the status of jobs' do
    job.set_progress(0.5)

    visit admin_root_path
    click_link 'Queued jobs'

    expect(current_path).to eq(admin_jobs_path)
    expect(page).to have_css('.job_status', text: 'queued')
    expect(page).to have_css('.job_progress', text: '50%')
  end

  scenario 'Getting more details about a job' do
    error = Lev::Error.new(code: 'bad', message: 'awful')
    job.add_error(error)
    job.save(something_spectacular: 'For all the good children')

    visit admin_jobs_path
    click_link job.id

    expect(current_path).to eq(admin_job_path(job.id))
    expect(page).to have_css('.job_errors', text: 'bad - awful')
    expect(page).to have_css('.job_something_spectacular', text: 'For all the good children')
  end
end
