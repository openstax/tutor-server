require 'rails_helper'

describe GetStudentRoster do
  let!(:course) { CreateCourse[name: 'Physics 101'] }
  let!(:period_1) { CreatePeriod[course: course] }
  let!(:period_2) { CreatePeriod[course: course] }

  let!(:other_course) { CreateCourse[name: 'Other Course'] }
  let!(:other_period) { CreatePeriod[course: other_course] }

  let!(:student_1) { FactoryGirl.create :user_profile }
  let!(:student_1_role) {
    AddUserAsPeriodStudent.call(
      period: period_1, user: student_1.entity_user
    ).outputs[:role]
  }

  let(:student_2) { FactoryGirl.create :user_profile }
  let!(:student_2_role) {
    AddUserAsPeriodStudent.call(
      period: period_1, user: student_2.entity_user
    ).outputs[:role]
  }

  let(:student_3) { FactoryGirl.create :user_profile }
  let!(:student_3_role) {
    AddUserAsPeriodStudent.call(
      period: period_2, user: student_3.entity_user
    ).outputs[:role]
  }

  let!(:student_4) { FactoryGirl.create :user_profile }
  let!(:student_4_role) {
    AddUserAsPeriodStudent.call(
      period: other_period, user: student_4.entity_user
    ).outputs[:role]
  }

  it 'returns all the students in the course' do
    students = GetStudentRoster[course: course]
    students.sort! { |a, b| a.id <=> b.id }
    expect(students).to eq([
      {
        'id' => students[0].id,
        'first_name' => student_1.first_name,
        'last_name' => student_1.last_name,
        'name' => student_1.full_name,
        'period_id' => period_1.id,
        'role_id' => student_1_role.id,
      },
      {
        'id' => students[1].id,
        'first_name' => student_2.first_name,
        'last_name' => student_2.last_name,
        'name' => student_2.full_name,
        'period_id' => period_1.id,
        'role_id' => student_2_role.id,
      },
      {
        'id' => students[2].id,
        'first_name' => student_3.first_name,
        'last_name' => student_3.last_name,
        'name' => student_3.full_name,
        'period_id' => period_2.id,
        'role_id' => student_3_role.id,
      }
    ])
  end
end
