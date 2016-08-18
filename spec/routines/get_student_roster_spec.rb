require 'rails_helper'

describe GetCourseRoster, type: :routine do
  let(:course) { CreateCourse[name: 'Physics 101'] }
  let(:period_1) { CreatePeriod[course: course] }
  let(:period_2) { CreatePeriod[course: course] }

  let(:other_course) { CreateCourse[name: 'Other Course'] }
  let(:other_period) { CreatePeriod[course: other_course] }

  let(:student_1) { FactoryGirl.create(:user) }
  let!(:student_1_role) {
    AddUserAsPeriodStudent.call(period: period_1, user: student_1).outputs[:role]
  }

  let(:student_2) { FactoryGirl.create(:user) }
  let!(:student_2_role) {
    AddUserAsPeriodStudent.call(period: period_1, user: student_2).outputs[:role]
  }

  let(:student_3) { FactoryGirl.create(:user) }
  let!(:student_3_role) {
    AddUserAsPeriodStudent.call(period: period_2, user: student_3).outputs[:role]
  }

  let(:student_4) { FactoryGirl.create(:user) }
  let!(:student_4_role) {
    AddUserAsPeriodStudent.call(period: other_period, user: student_4).outputs[:role]
  }

  it 'returns all the students in the course' do
    students = GetCourseRoster.call(course: course).outputs.roster[:students]
    students.sort! { |a, b| a.id <=> b.id }
    expect(students).to eq([
      {
        'id' => students[0].id,
        'first_name' => student_1.first_name,
        'last_name' => student_1.last_name,
        'name' => student_1.name,
        'course_membership_period_id' => period_1.id,
        'entity_role_id' => student_1_role.id,
        'username' => student_1.username,
        'student_identifier' => student_1_role.student.student_identifier,
        'deidentifier' => student_1_role.student.deidentifier,
        'deleted?' => false
      },
      {
        'id' => students[1].id,
        'first_name' => student_2.first_name,
        'last_name' => student_2.last_name,
        'name' => student_2.name,
        'course_membership_period_id' => period_1.id,
        'entity_role_id' => student_2_role.id,
        'username' => student_2.username,
        'student_identifier' => student_2_role.student.student_identifier,
        'deidentifier' => student_2_role.student.deidentifier,
        'deleted?' => false
      },
      {
        'id' => students[2].id,
        'first_name' => student_3.first_name,
        'last_name' => student_3.last_name,
        'name' => student_3.name,
        'course_membership_period_id' => period_2.id,
        'entity_role_id' => student_3_role.id,
        'username' => student_3.username,
        'student_identifier' => student_3_role.student.student_identifier,
        'deidentifier' => student_3_role.student.deidentifier,
        'deleted?' => false
      }
    ])
  end

  it 'does not blow up when a period has been deleted' do
    period_2.to_model.enrollments.each{ |en| en.student.destroy }
    expect{ period_2.to_model.destroy }.to(
      change{ CourseMembership::Models::Period.count }.by(-1)
    )

    students = GetCourseRoster.call(course: course).outputs.roster[:students]
    students.sort! { |a, b| a.id <=> b.id }

    expect(students).to eq([
      {
        'id' => students[0].id,
        'first_name' => student_1.first_name,
        'last_name' => student_1.last_name,
        'name' => student_1.name,
        'course_membership_period_id' => period_1.id,
        'entity_role_id' => student_1_role.id,
        'username' => student_1.username,
        'student_identifier' => student_1_role.student.student_identifier,
        'deidentifier' => student_1_role.student.deidentifier,
        'deleted?' => false
      },
      {
        'id' => students[1].id,
        'first_name' => student_2.first_name,
        'last_name' => student_2.last_name,
        'name' => student_2.name,
        'course_membership_period_id' => period_1.id,
        'entity_role_id' => student_2_role.id,
        'username' => student_2.username,
        'student_identifier' => student_2_role.student.student_identifier,
        'deidentifier' => student_2_role.student.deidentifier,
        'deleted?' => false
      },
      {
        'id' => students[2].id,
        'first_name' => student_3.first_name,
        'last_name' => student_3.last_name,
        'name' => student_3.name,
        'course_membership_period_id' => period_2.id,
        'entity_role_id' => student_3_role.id,
        'username' => student_3.username,
        'student_identifier' => student_3_role.student.student_identifier,
        'deidentifier' => student_3_role.student.deidentifier,
        'deleted?' => true
      }
    ])
  end
end
