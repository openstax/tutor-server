require 'rails_helper'

RSpec.describe Research::CohortMembershipManager do

  let(:study) { Research::Models::Study.create(name: "A Study") }

  context "#add_student_to_a_cohort" do
    it "adds students evenly to a study's cohorts" do
      3.times.map{|ii| Research::Models::Cohort.create(name: "#{ii}", study: study)}
      instance = described_class.new(study)

      8.times do
        student = FactoryBot.create :course_membership_student
        instance.add_student_to_a_cohort(student)
      end

      expect(study.cohorts(true).map(&:cohort_members_count)).to match a_collection_including(2,3,3)
    end

    it "does not add to cohorts not accepting members" do
      cohorts = 3.times.map{|ii| Research::Models::Cohort.create(name: "#{ii}", study: study)}
      cohorts[2].update_attributes(is_accepting_members: false)
      instance = described_class.new(study)

      8.times do
        student = FactoryBot.create :course_membership_student
        instance.add_student_to_a_cohort(student)
      end

      expect(study.cohorts(true).map(&:cohort_members_count)).to match a_collection_including(4,4,0)
    end
  end

  context "#reassign_cohort_members" do
    let!(:cohort_to_reassign_from) { Research::Models::Cohort.create(name: "0", study: study) }

    before do
      instance = described_class.new(study)

      5.times do
        student = FactoryBot.create :course_membership_student
        instance.add_student_to_a_cohort(student)
      end

      expect(cohort_to_reassign_from.reload.cohort_members_count).to eq 5
    end

    it "reassigns a cohort's members to new cohorts evenly" do
      # Make 2 new cohorts
      new_cohorts = 2.times.map{|ii| Research::Models::Cohort.create(name: "#{ii+1}", study: study)}

      instance = described_class.new(study)
      instance.reassign_cohort_members(cohort_to_reassign_from)

      expect(study.cohorts(true).map(&:cohort_members_count)).to match a_collection_including(0,3,2)
    end

    it "does not reassign to cohorts not accepting members" do
      # Make 2 new cohorts
      new_cohorts = 2.times.map{|ii| Research::Models::Cohort.create(name: "#{ii+1}", study: study)}
      new_cohorts[1].update_attributes(is_accepting_members: false)

      instance = described_class.new(study)
      instance.reassign_cohort_members(cohort_to_reassign_from)

      expect(new_cohorts.map(&:reload).map(&:cohort_members_count)).to match a_collection_including(0,5)
    end
  end

end
