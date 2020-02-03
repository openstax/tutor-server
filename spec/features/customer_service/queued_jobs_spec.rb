# coding: utf-8
require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Viewing queued jobs as Customer Service', :js do
  let(:course)           { FactoryBot.create :course_profile_course }
  let(:customer_service) { FactoryBot.create(:user_profile, :customer_service) }
  let(:user)             { FactoryBot.create(:user_profile) }
  let(:role)             { AddUserAsCourseTeacher[course: course, user: user] }

  let(:status)           { Jobba.find(@job_id) }

  before(:all) do
    Jobba.all.to_a.each(&:delete!)
    Delayed::Worker.delay_jobs = true
  end

  after(:all) do
    Delayed::Worker.delay_jobs = false
    Jobba.all.to_a.each(&:delete!)
  end

  before(:each) do
    stub_current_user(customer_service)
    @job_id = Tasks::ExportPerformanceReport.perform_later(course: course, role: role)
  end

  after(:each) do
    Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
      performance_report_export.try!(:export).try!(:file).try!(:delete)
    end
  end

  scenario 'Viewing the status of jobs' do
    status.set_progress(0.5)

    visit customer_service_root_path
    click_link 'Jobs'

    expect(current_path).to eq(customer_service_jobs_path)
    expect(page).to have_css('.job_status', text: 'queued')
    expect(page).to have_css('.job_progress', text: '50%')
  end

  scenario 'Viewing a job without any custom data' do
    visit customer_service_jobs_path
    click_link status.id
    expect(current_path).to eq(customer_service_job_path(status.id))

    # set the job as completed and refresh the page
    status.succeeded!
    visit customer_service_job_path(status.id)

    expect(page).to have_css('.job_name', text: 'Tasks::ExportPerformanceReport')
    expect(page).to have_css('.job_args', text: '{}')
    expect(page).to have_css('.job_progress', text: '100%')
    expect(page).to have_css('.job_errors', text: '')
    expect(page).to have_css('.job_custom', text: '')
  end

  scenario 'Getting more details about a job' do
    error = Lev::Error.new(code: 'bad', message: 'awful')
    status.add_error(error.as_json)
    status.save(something_spectacular: 'For all the good children')

    visit customer_service_jobs_path
    click_link status.id

    expect(current_path).to eq(customer_service_job_path(status.id))
    expect(page).to have_css('.job_errors', text: 'bad - awful')
    expect(page).to have_css('.job_something_spectacular',
                             text: 'For all the good children')
  end

  scenario 'Filtering by statuses' do
    status.queued!
    visit customer_service_jobs_path

    select 'killed', from: 'state'
    click_button 'Search'
    expect(page).to have_no_css('.queued')
    select 'queued', from: 'state'
    click_button 'Search'
    expect(page).to have_css('.queued')

    status.started!
    visit customer_service_jobs_path

    select 'killed', from: 'state'
    click_button 'Search'
    expect(page).to have_no_css('.started')
    select 'started', from: 'state'
    click_button 'Search'
    expect(page).to have_css('.started')

    status.failed!
    visit customer_service_jobs_path

    select 'killed', from: 'state'
    click_button 'Search'
    expect(page).to have_no_css('.failed')
    select 'failed', from: 'state'
    click_button 'Search'
    expect(page).to have_css('.failed')

    status.killed!
    visit customer_service_jobs_path

    select 'failed', from: 'state'
    click_button 'Search'
    expect(page).to have_no_css('.killed')
    select 'killed', from: 'state'
    click_button 'Search'
    expect(page).to have_css('.killed')

    status.unknown!
    visit customer_service_jobs_path

    select 'killed', from: 'state'
    click_button 'Search'
    expect(page).to have_no_css('.unknown')
    select 'unknown', from: 'state'
    click_button 'Search'
    expect(page).to have_css('.unknown')
  end

  scenario 'Paginating jobs' do
    extra_jobs = 10.times.map { Jobba.create! }

    visit customer_service_jobs_path
    expect(page).to have_no_css('.pagination')

    select 10, from: 'per_page'
    click_button 'Search'
    expect(page).to have_css('.pagination')
    expect(page).to have_css('.next_page:not(.disabled)')
    expect(page).to have_css('.previous_page.disabled')

    click_link 'Next →'
    expect(page).to have_css('.pagination')
    expect(page).to have_css('.next_page.disabled')
    expect(page).to have_css('.previous_page:not(.disabled)')

    extra_jobs.each(&:delete!)
  end
end
