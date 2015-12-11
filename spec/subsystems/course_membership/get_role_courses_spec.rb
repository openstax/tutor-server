require 'rails_helper'

describe CourseMembership::GetRoleCourses do
  let!(:course_1) { Entity::Course.create! }
  let!(:course_1_period) { CreatePeriod.call(course: course_1).period }

  let!(:course_2) { Entity::Course.create! }
  let!(:course_2_period) { CreatePeriod.call(course: course_2).period }

  let!(:course_3) { Entity::Course.create! }
  let!(:course_3_period) { CreatePeriod.call(course: course_3).period }

  let!(:role_a) { Entity::Role.create! }
  let!(:role_b) { Entity::Role.create! }
  let!(:role_c) { Entity::Role.create! }

  before {
    CourseMembership::AddTeacher.call(course: course_1,        role: role_a)
    CourseMembership::AddStudent.call(period: course_1_period, role: role_a)

    CourseMembership::AddStudent.call(period: course_2_period, role: role_b)

    CourseMembership::AddTeacher.call(course: course_3,        role: role_c)
  }

  it 'can find courses for student roles given a singular role' do
    courses = described_class.call(roles: role_a, types: :student)
    expect(courses).to contain_exactly(course_1)
  end

  it 'can find courses for multiple student roles' do
    courses = described_class.call(roles: [role_a, role_b], types: :student)
    expect(courses).to contain_exactly(course_1, course_2)

    courses = described_class.call(roles: [role_a, role_c], types: :student)
    expect(courses).to contain_exactly(course_1)
  end

  it 'can find courses for roles without restrict type' do
    courses = described_class.call(roles: [role_a], types: [:student, :teacher, :any])
    expect(courses).to contain_exactly(course_1)
  end

  it 'can find courses for roles limited to teacher types' do
    courses = described_class.call(roles: [role_a, role_b, role_c], types: [:teacher])
    expect(courses).to contain_exactly(course_1, course_3)
  end

  it 'does not find courses where the role is an inactive student' do
    role_b.student.inactivate.save!
    courses = described_class.call(roles: [role_a, role_b], types: [:student])
    expect(courses).to contain_exactly(course_1)
  end

end
