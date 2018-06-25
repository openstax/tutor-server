require 'rails_helper'

RSpec.describe Research::Models::Cohort, type: :model do

  let(:study) { FactoryBot.create :research_study }
  let!(:cohort) { described_class.create(name: "Main", study: study) }
  let(:students) { 5.times.map{ FactoryBot.create :course_membership_student }}

  it "increments the member count when members are added" do
    expect{
      expect(cohort.cohort_members_count).to eq 0
    }.to make_database_queries(count: 0)

    Research::Models::CohortMember.create(cohort: cohort, student: students[0])

    expect {
      expect(cohort.cohort_members_count).to eq 1
    }.to make_database_queries(count: 0)

    Research::Models::CohortMember.create(cohort: cohort, student: students[1])
    expect(cohort.cohort_members_count).to eq 2
    Research::Models::CohortMember.create(cohort: cohort, student: students[2])
  end

  xit "cannot be created for an active study" do

  end

end
