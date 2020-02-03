require 'rails_helper'

RSpec.describe GetCourseRoster, type: :routine do
  let(:course)   { FactoryBot.create :course_profile_course }
  let(:period_1) { FactoryBot.create :course_membership_period, course: course }
  let(:period_2) { FactoryBot.create :course_membership_period, course: course }

  let(:other_course) { FactoryBot.create :course_profile_course }
  let(:other_period) { FactoryBot.create :course_membership_period, course: other_course }

  let(:student_1) { FactoryBot.create(:user_profile) }
  let!(:student_1_role) {
    AddUserAsPeriodStudent.call(period: period_1, user: student_1).outputs[:role]
  }

  let(:student_2) { FactoryBot.create(:user_profile) }
  let!(:student_2_role) {
    AddUserAsPeriodStudent.call(period: period_1, user: student_2).outputs[:role]
  }

  let(:student_3) { FactoryBot.create(:user_profile) }
  let!(:student_3_role) {
    AddUserAsPeriodStudent.call(period: period_2, user: student_3).outputs[:role]
  }

  let(:student_4) { FactoryBot.create(:user_profile) }
  let!(:student_4_role) {
    AddUserAsPeriodStudent.call(period: other_period, user: student_4).outputs[:role]
  }

  it 'returns all the students in the course' do
    students = GetCourseRoster.call(course: course).outputs.roster[:students]
    students.sort! { |a, b| a.id <=> b.id }
    expect(students).to match a_collection_containing_exactly(
      a_hash_including(
        'id' => students[0].id,
        'first_name' => student_1.first_name,
        'last_name' => student_1.last_name,
        'name' => student_1.name,
        'course_membership_period_id' => period_1.id,
        'entity_role_id' => student_1_role.id,
        'username' => student_1.username,
        'student_identifier' => student_1_role.student.student_identifier,
        'dropped?' => false
      ),
      a_hash_including(
        'id' => students[1].id,
        'first_name' => student_2.first_name,
        'last_name' => student_2.last_name,
        'name' => student_2.name,
        'course_membership_period_id' => period_1.id,
        'entity_role_id' => student_2_role.id,
        'username' => student_2.username,
        'student_identifier' => student_2_role.student.student_identifier,
        'dropped?' => false
      ),
      a_hash_including(
        'id' => students[2].id,
        'first_name' => student_3.first_name,
        'last_name' => student_3.last_name,
        'name' => student_3.name,
        'course_membership_period_id' => period_2.id,
        'entity_role_id' => student_3_role.id,
        'username' => student_3.username,
        'student_identifier' => student_3_role.student.student_identifier,
        'dropped?' => false
      )
    )
  end

  it 'does not blow up when a period has been deleted' do
    period_2.enrollments.each { |en| en.student.destroy }
    expect { period_2.destroy }.to change{ period_2.archived? }.from(false).to(true)

    students = GetCourseRoster.call(course: course).outputs.roster[:students]
    students.sort! { |a, b| a.id <=> b.id }

    expect(students).to match a_collection_containing_exactly(
      a_hash_including(
        'id' => students[0].id,
        'first_name' => student_1.first_name,
        'last_name' => student_1.last_name,
        'name' => student_1.name,
        'course_membership_period_id' => period_1.id,
        'entity_role_id' => student_1_role.id,
        'username' => student_1.username,
        'student_identifier' => student_1_role.student.student_identifier,
        'dropped?' => false
      ),
      a_hash_including(
        'id' => students[1].id,
        'first_name' => student_2.first_name,
        'last_name' => student_2.last_name,
        'name' => student_2.name,
        'course_membership_period_id' => period_1.id,
        'entity_role_id' => student_2_role.id,
        'username' => student_2.username,
        'student_identifier' => student_2_role.student.student_identifier,
        'dropped?' => false
      ),
      a_hash_including(
        'id' => students[2].id,
        'first_name' => student_3.first_name,
        'last_name' => student_3.last_name,
        'name' => student_3.name,
        'course_membership_period_id' => period_2.id,
        'entity_role_id' => student_3_role.id,
        'username' => student_3.username,
        'student_identifier' => student_3_role.student.student_identifier,
        'dropped?' => true
      )
    )
  end
end
