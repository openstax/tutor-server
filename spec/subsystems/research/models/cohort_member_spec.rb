require 'rails_helper'

RSpec.describe Research::Models::CohortMember, type: :model do

  let(:study) { FactoryBot.create :research_study }
  let!(:cohort) { Research::Models::Cohort.create(name: "Main", study: study) }
  let(:students) { 5.times.map{ FactoryBot.create :course_membership_student }}

  it "does not allow a student to join a cohort more than once" do
    member_1 = described_class.create(cohort: cohort, student: students[0])
    member_2 = described_class.create(cohort: cohort, student: students[0])
    expect(member_2.errors.full_messages).to include(/has already been taken/)
  end

end
