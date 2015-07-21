require 'rails_helper'

describe InactivateStudent, type: :routine do
  it "inactivates but does not delete the given student" do
    role = Entity::Role.create!
    course = Entity::Course.create!
    period = CreatePeriod[course: course]
    student = CourseMembership::AddStudent[period: period, role: role]

    expect(student.active?).to eq true

    result = nil
    expect {
      result = InactivateStudent.call(student: student)
    }.not_to change{ CourseMembership::Models::Student.count }
    expect(result.errors).to be_empty

    expect(student.reload.course).to eq course
    expect(student.active?).to eq false
  end
end
