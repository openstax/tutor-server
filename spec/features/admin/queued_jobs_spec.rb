require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Administration of queued jobs', :js do
  let(:course) { FactoryGirl.create :entity_course }
  let(:admin)  { FactoryGirl.create(:user, :administrator) }
  let(:user)   { FactoryGirl.create(:user) }
  let(:role)   { AddUserAsCourseTeacher[course: course, user: user] }

  let(:status) { Jobba.find(@job_id) }

  before(:all) do
    Jobba.all.to_a.each { |status| status.delete! }
    Delayed::Worker.delay_jobs = true
  end

  after(:all) do
    Delayed::Worker.delay_jobs = false
    Jobba.all.to_a.each { |status| status.delete! }
  end

  before(:each) do
    stub_current_user(admin)
    @job_id = Tasks::ExportPerformanceReport.perform_later(course: course, role: role)
  end

  after(:each) do
    Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
      performance_report_export.try(:export).try(:file).try(:delete)
    end
  end

  scenario 'Viewing the status of jobs' do
    status.set_progress(0.5)

    visit admin_root_path
    click_link 'Jobs'

    expect(current_path).to eq(admin_jobs_path)
    expect(page).to have_css('.job_status', text: 'queued')
    expect(page).to have_css('.job_progress', text: '50%')
  end

  scenario 'Viewing a job without any custom data' do
    visit admin_jobs_path
    click_link status.id
    expect(current_path).to eq(admin_job_path(status.id))

    # set the job as completed and refresh the page
    status.succeeded!
    status.set_job_name('Export performance report')
    visit admin_job_path(status.id)

    expect(page).to have_css('.job_name', text: 'Export performance report')
    expect(page).to have_css('.job_args', text: '{}')
    expect(page).to have_css('.job_progress', text: '100%')
    expect(page).to have_css('.job_errors', text: '')
    expect(page).to have_css('.job_custom', text: '')
  end

  scenario 'Getting more details about a job' do
    error = Lev::Error.new(code: 'bad', message: 'awful')
    status.add_error(error)
    status.save(something_spectacular: 'For all the good children')

    visit admin_jobs_path
    click_link status.id

    expect(current_path).to eq(admin_job_path(status.id))
    expect(page).to have_css('.job_errors', text: 'bad - awful')
    expect(page).to have_css('.job_something_spectacular',
                             text: 'For all the good children')
  end

  scenario 'succeeded jobs are hidden' do
    status.succeeded!

    visit admin_root_path
    click_link 'Jobs'

    expect(page).not_to have_css('.succeeded')

    click_link 'all'
    expect(page).to have_css('.succeeded')

    click_link 'incomplete'
    expect(page).not_to have_css('.succeeded')
  end

  scenario 'statuses are filterable' do
    status.queued!
    visit admin_jobs_path

    click_link 'killed'
    expect(page).not_to have_css('.queued')
    click_link 'queued'
    expect(page).to have_css('.queued')


    status.started!
    visit admin_jobs_path

    click_link 'killed'
    expect(page).not_to have_css('.started')
    click_link 'started'
    expect(page).to have_css('.started')


    status.failed!
    visit admin_jobs_path

    click_link 'killed'
    expect(page).not_to have_css('.failed')
    click_link 'failed'
    expect(page).to have_css('.failed')


    status.killed!
    visit admin_jobs_path

    click_link 'failed'
    expect(page).not_to have_css('.killed')
    click_link 'killed'
    expect(page).to have_css('.killed')


    status.unknown!
    visit admin_jobs_path

    click_link 'killed'
    expect(page).not_to have_css('.unknown')
    click_link 'unknown'
    expect(page).to have_css('.unknown')


    status.queued!
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

    fill_in 'filter_id', with: status.id[4..7] # partial matching works
    expect(page).to have_css('.job_id', text: status.id)
  end
end
