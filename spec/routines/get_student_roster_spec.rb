require 'rails_helper'

RSpec.describe GetCourseRoster, type: :routine do
  let(:course)   { FactoryBot.create :course_profile_course }
  let(:period_1) { FactoryBot.create :course_membership_period, course: course }
  let(:period_2) { FactoryBot.create :course_membership_period, course: course }

  let(:other_course) { FactoryBot.create :course_profile_course }
  let(:other_period) { FactoryBot.create :course_membership_period, course: other_course }

  let(:student_1_user) { FactoryBot.create(:user) }
  let(:student_1_role) do
    AddUserAsPeriodStudent.call(period: period_1, user: student_1_user).outputs[:role]
  end
  let!(:student_1)     { student_1_role.student }

  let(:student_2_user) { FactoryBot.create(:user) }
  let(:student_2_role) do
    AddUserAsPeriodStudent.call(period: period_1, user: student_2_user).outputs[:role]
  end
  let!(:student_2)     { student_2_role.student }

  let(:student_3_user) { FactoryBot.create(:user) }
  let(:student_3_role) do
    AddUserAsPeriodStudent.call(period: period_2, user: student_3_user).outputs[:role]
  end
  let!(:student_3)     { student_3_role.student }

  let(:student_4_user) { FactoryBot.create(:user) }
  let(:student_4_role) do
    AddUserAsPeriodStudent.call(period: other_period, user: student_4_user).outputs[:role]
  end
  let!(:student_4)     { student_4_role.student }

  it 'returns all the students in the course' do
    students = GetCourseRoster.call(course: course).outputs.roster[:students].to_a.sort_by(&:id)
    expect(students).to match a_collection_containing_exactly(student_1, student_2, student_3)
  end

  it 'does not blow up when a period has been deleted' do
    period_2.to_model.enrollments.each { |en| en.student.destroy }
    expect { period_2.to_model.destroy }.to(
      change{ period_2.to_model.archived? }.from(false).to(true)
    )

    students = GetCourseRoster.call(course: course).outputs.roster[:students].to_a.sort_by(&:id)

    expect(students).to match a_collection_containing_exactly(student_1, student_2, student_3)
  end
end
