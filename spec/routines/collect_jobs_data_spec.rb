require 'rails_helper'

RSpec.describe CollectJobsData, type: :routine do
  context "when there are any" do
    let(:school) { FactoryGirl.build :school_district_school }
    let!(:course) { FactoryGirl.create :course_profile_profile, school: school }

    context "incomplete (queued) jobs" do
      let(:result) { described_class[state: :incomplete] }

      before(:each) do
        3.times{
          job = Jobba.create!
          job.save({ course_id: course.id })
          Jobba.find(job.id).queued!
        }
      end

      it "returns the incomplete jobs with their associated data as an array of hashes" do
        expect(result.count).to eq 3
        expect(result).to be_a Array
        expect(result.first).to be_a Hash
      end

      it "returns a hash with the specified keys for each item in the array" do
        first_jobba = Jobba.find(1)
        expected_hash = { id: first_jobba.id, state_name: first_jobba.state.name }
        expect(result.first).to include(:id, :state_name, :course_ecosystem, :course_profile_profile_name)
      end
    end

    context "failed jobs" do
      it "returns the failed jobs with their associated data as an array of hashes" do

      end
    end
  end

  context "when there are no results" do
    before(:all) do
      Jobba.all.delete_all!
      expect(Jobba.where(state: :incomplete).count).to eq 0
    end

    it "doesn't blow up" do
      expect{described_class[state: :incomplete]}.to_not raise_error
    end

    it "returns an empty array" do
      result = described_class[state: :incomplete]
      expect(result).to eq []
    end
  end
end
