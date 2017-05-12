require 'rails_helper'

RSpec.describe 'customer_service/courses/index', type: :view do
  let(:course_infos) { [] }
  let(:ecosystems)   { [] }

  before(:each)      do
    assign :course_infos, course_infos
    assign :job_path_proc, ->(job) { customer_service_job_path(job.id) }
    assign :ecosystems, ecosystems
  end

  context 'when there are no jobs' do
    it 'does not explode' do
      expect { render }.not_to raise_error

      expect(rendered).not_to be_blank
    end
  end

  context 'when there are incomplete and failed jobs' do
    let(:num_incomplete_jobs) { 2 }
    let(:incomplete_jobs)     do
      num_incomplete_jobs.times.map { FactoryGirl.create(:delayed_job) }
    end
    let(:incomplete_statuses) do
      incomplete_jobs.map do |job|
        Jobba.create!.tap do |status|
          status.set_job_name('Content::AddEcosystemToCourse')
          status.set_provider_job_id(job.id)
          status.queued!
        end
      end
    end

    let(:num_failed_jobs) { 2 }
    let(:failed_jobs)     do
      num_failed_jobs.times.map do
        FactoryGirl.create(:delayed_job).tap do |job|
          job.fail!
        end
      end
    end
    let(:failed_statuses) do
      failed_jobs.map do |job|
        Jobba.create!.tap do |status|
          status.set_job_name('Content::AddEcosystemToCourse')
          status.set_provider_job_id(job.id)
          status.failed!
        end
      end
    end

    before(:each) do
      assign :incomplete_jobs, incomplete_statuses
      assign :failed_jobs, failed_statuses
    end

    context 'with no data hashes' do
      it 'does not explode' do
        expect { render }.not_to raise_error

        expect(rendered).not_to be_blank
      end
    end

    context 'with data hashes' do
      before(:each) do
        incomplete_statuses.each do |status|
          status.save(
            course_id: 42,
            course_name: 'Course',
            ecosystem_id: 84,
            ecosystem_title: 'Ecosystem'
          )
        end

        failed_statuses.each do |status|
          status.save(
            course_id: 42,
            course_name: 'Course',
            ecosystem_id: 84,
            ecosystem_title: 'Ecosystem'
          )
        end
      end

      it 'does not explode' do
        expect { render }.not_to raise_error

        expect(rendered).not_to be_blank
      end
    end
  end
end
