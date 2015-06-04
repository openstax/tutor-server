require 'rails_helper'

describe CourseMembership::AddStudent do
  context "when adding a new student role to a period" do
    it "succeeds" do
      role = Entity::Role.create!
      course = Entity::Course.create!
      CourseMembership::AddPeriod(course: course, name: 'dummy')

      result = nil
      expect {
        result = CourseMembership::AddStudent.call(course: course, role: role,
                                                   period_name: 'dummy')
      }.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty
    end
  end

  context "when adding a existing student role to a course" do
    it "fails" do
      role = Entity::Role.create!
      course = Entity::Course.create!
      CourseMembership::AddPeriod(course: course, name: 'dummy')
      CourseMembership::AddPeriod(course: course, name: 'dummier')

      result = nil
      expect {
        result = CourseMembership::AddStudent.call(course: course, role: role,
                                                   period_name: 'dummy')
      }.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty
      student = CourseMembership::Models::Student.order(:created_at).last
      expect(student.course).to eq course
      expect(student.period.name).to eq 'dummy'

      expect {
        result = CourseMembership::AddStudent.call(course: course, role: role,
                                                   period_name: 'dummier')
      }.to_not change{ CourseMembership::Models::Student.count }
      expect(result.errors).to be_empty
      expect(student.reload.course).to eq course
      expect(student.period.name).to eq 'dummier'
    end
  end
end
