require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Administration of queued jobs', :js do
  let(:course) { CreateCourse[name: 'course time'] }
  let(:admin) { FactoryGirl.create(:user, :administrator) }
  let(:user) { FactoryGirl.create(:user) }
  let(:role) { AddUserAsCourseTeacher[course: course, user: user] }

  let(:job) { Lev::BackgroundJob.all.last }

  before(:all) do
    Delayed::Worker.delay_jobs = true
  end

  after(:all) do
    Delayed::Worker.delay_jobs = false
  end

  before(:each) do
    stub_current_user(admin)
    Tasks::ExportPerformanceReport.perform_later(course: course, role: role)
  end

  after(:each) do
    Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
      performance_report_export.try(:export).try(:file).try(:delete)
    end
  end

  scenario 'Viewing the status of jobs' do
    job.set_progress(0.5)

    visit admin_root_path
    click_link 'Jobs'

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
    expect(page).to have_css('.job_something_spectacular',
                             text: 'For all the good children')
  end

  scenario 'succeeded jobs are hidden' do
    job.succeeded!

    visit admin_root_path
    click_link 'Jobs'

    expect(page).not_to have_css('.succeeded')

    click_link 'all'
    expect(page).to have_css('.succeeded')

    click_link 'incomplete'
    expect(page).not_to have_css('.succeeded')
  end

  scenario 'statuses are filterable' do
    job.queued!
    visit admin_jobs_path

    click_link 'killed'
    expect(page).not_to have_css('.queued')
    click_link 'queued'
    expect(page).to have_css('.queued')


    job.working!
    visit admin_jobs_path

    click_link 'killed'
    expect(page).not_to have_css('.working')
    click_link 'working'
    expect(page).to have_css('.working')


    job.failed!
    visit admin_jobs_path

    click_link 'killed'
    expect(page).not_to have_css('.failed')
    click_link 'failed'
    expect(page).to have_css('.failed')


    job.killed!
    visit admin_jobs_path

    click_link 'failed'
    expect(page).not_to have_css('.killed')
    click_link 'killed'
    expect(page).to have_css('.killed')


    job.unknown!
    visit admin_jobs_path

    click_link 'killed'
    expect(page).not_to have_css('.unknown')
    click_link 'unknown'
    expect(page).to have_css('.unknown')


    job.queued!
    visit admin_jobs_path

    click_link 'all'
    click_link 'incomplete'
    expect(page).to have_css('.queued')
  end

  scenario 'search by id' do
    visit admin_jobs_path

    expect(page).to have_css('#jobs tbody tr')

    fill_in 'filter_id', with: 'not-here'
    expect(page).not_to have_css('#jobs tbody tr')

    fill_in 'filter_id', with: job.id[4..7] # partial matching works
    expect(page).to have_css('.job_id', text: job.id)
  end
end
