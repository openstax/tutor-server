require 'rails_helper'

RSpec.describe CollectJobsData, type: :routine do
  before(:each)             do
    Jobba.all.delete_all!
    expect(Jobba.all.count).to eq 0
  end

  let(:ecosystem_title)     do
    "Physics (334f8b61-30eb-4475-8e05-5260a4866b4b@7.42) - 2016-08-10 18:10:50 UTC"
  end

  let(:job_name)            { 'Cool background job' }

  let(:result)              { described_class.call(job_name: job_name) }
  let(:outputs)             { result.outputs }

  context "when there are no results" do
    it "doesn't blow up" do
      expect{ result }.to_not raise_error
    end

    it "returns an empty arrays" do
      expect(outputs.completed_jobs ).to eq []
      expect(outputs.incomplete_jobs).to eq []
      expect(outputs.failed_jobs    ).to eq []
    end
  end

  context "when there are some jobs" do
    let!(:school)           { FactoryGirl.build :school_district_school }
    let!(:course)           do
      FactoryGirl.create :course_profile_course, school: school, name: "Learn how to learn"
    end

    let(:num_jobs)          { 2 }
    let(:jobs)              { num_jobs.times.map { FactoryGirl.create :delayed_job } }
    let!(:statuses)         do
      jobs.map do |job|
        Jobba.create!.tap do |status|
          status.set_job_name('Cool background job')
          status.set_provider_job_id(job.id)
        end
      end
    end

    context "without data hashes" do
      it "doesn't blow up" do
        expect{ result }.to_not raise_error
      end

      context "and the jobs are completed" do
        before(:each) do
          jobs.each(&:destroy)
          expect(Delayed::Job.all.size).to eq 0
          statuses.each(&:succeeded!)
          expect(Jobba.where(state: :completed).count).to eq 2
        end

        let(:completed_jobs) { outputs.completed_jobs }

        it "returns the completed jobs with their associated data as an array of hashes" do
          expect(completed_jobs).to be_a Array
          expect(completed_jobs.size).to eq 2
          completed_jobs.each { |job| expect(job).to be_a Jobba::Status }
        end

        it "returns a hash with the specified keys for each item in the array" do
          expect(completed_jobs.map(&:id)).to match_array Jobba.where(state: :completed).map(&:id)
        end
      end

      context "and the jobs are incomplete (queued)" do
        before(:each) do
          expect(Delayed::Job.all.reject(&:failed?).size).to eq 2
          statuses.each(&:queued!)
          expect(Jobba.where(state: :queued).count).to eq 2
        end

        let(:incomplete_jobs) { outputs.incomplete_jobs }

        it "returns the incomplete jobs with their associated data as an array of hashes" do
          expect(incomplete_jobs).to be_a Array
          expect(incomplete_jobs.size).to eq 2
          incomplete_jobs.each { |job| expect(job).to be_a Jobba::Status }
        end

        it "returns a hash with the specified keys for each item in the array" do
          expect(incomplete_jobs.map(&:id)).to match_array Jobba.where(state: :incomplete).map(&:id)
        end
      end

      context "and the jobs have failed" do
        before(:each)         do
          jobs.each(&:fail!)
          expect(Delayed::Job.all.select(&:failed?).size).to eq 2
          statuses.each(&:failed!)
          expect(Jobba.where(state: :failed).count).to eq 2
        end

        let(:failed_jobs)     { outputs.failed_jobs }

        it "returns the failed jobs with their associated data as an array of hashes" do
          expect(failed_jobs).to be_a Array
          expect(failed_jobs.size).to eq 2
          failed_jobs.each { |job| expect(job).to be_a Jobba::Status }
        end

        it "returns a hash with the specified keys for each item in the array" do
          expect(failed_jobs.map(&:id)).to match_array Jobba.where(state: :failed).map(&:id)
        end
      end
    end

    context "with data hashes" do
      before(:each) do
        jobs.each do |job|
          job.save(course_id: course.name, course_ecosystem: ecosystem_title)
        end
      end

      it "doesn't blow up" do
        expect{ result }.to_not raise_error
      end

      context "and the jobs are completed" do
        before(:each) do
          jobs.each(&:destroy)
          expect(Delayed::Job.all.size).to eq 0
          statuses.each(&:succeeded!)
          expect(Jobba.where(state: :completed).count).to eq 2
        end

        let(:completed_jobs) { outputs.completed_jobs }

        it "returns the completed jobs with their associated data as an array of hashes" do
          expect(completed_jobs).to be_a Array
          expect(completed_jobs.size).to eq 2
          completed_jobs.each { |job| expect(job).to be_a Jobba::Status }
        end

        it "returns a hash with the specified keys for each item in the array" do
          expect(completed_jobs.map(&:id)).to match_array Jobba.where(state: :completed).map(&:id)
        end
      end

      context "and the jobs are incomplete (queued)" do
        before(:each) do
          expect(Delayed::Job.all.reject(&:failed?).size).to eq 2
          statuses.each(&:queued!)
          expect(Jobba.where(state: :queued).count).to eq 2
        end

        let(:incomplete_jobs) { outputs.incomplete_jobs }

        it "returns the incomplete jobs with their associated data as an array of hashes" do
          expect(incomplete_jobs).to be_a Array
          expect(incomplete_jobs.size).to eq 2
          incomplete_jobs.each { |job| expect(job).to be_a Jobba::Status }
        end

        it "returns a hash with the specified keys for each item in the array" do
          expect(incomplete_jobs.map(&:id)).to match_array Jobba.where(state: :incomplete).map(&:id)
        end
      end

      context "and the jobs have failed" do
        before(:each) do
          jobs.each(&:fail!)
          expect(Delayed::Job.all.select(&:failed?).size).to eq 2
          statuses.each(&:failed!)
          expect(Jobba.where(state: :failed).count).to eq 2
        end

        let(:failed_jobs)     { outputs.failed_jobs }

        it "returns the failed jobs with their associated data as an array of hashes" do
          expect(failed_jobs).to be_a Array
          expect(failed_jobs.size).to eq 2
          failed_jobs.each { |job| expect(job).to be_a Jobba::Status }
        end

        it "returns a hash with the specified keys for each item in the array" do
          expect(failed_jobs.map(&:id)).to match_array Jobba.where(state: :failed).map(&:id)
        end
      end
    end
  end
end
