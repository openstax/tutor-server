require 'rails_helper'

describe CourseMembership::AddStudent, type: :routine do
  context "when adding a new student role to a period" do
    it "succeeds" do
      role = Entity::Role.create!
      course = Entity::Course.create!
      period = CreatePeriod[course: course]

      result = nil
      expect {
        result = CourseMembership::AddStudent.call(period: period, role: role)
      }.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty
    end
  end

  context "when adding an existing student role to a course" do
    it "fails" do
      role = Entity::Role.create!
      course = Entity::Course.create!
      period_1 = CreatePeriod[course: course]
      period_2 = CreatePeriod[course: course]

      result = nil
      expect {
        result = CourseMembership::AddStudent.call(period: period_1, role: role)
      }.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty
      student = CourseMembership::Models::Student.order(:created_at).last
      expect(student.course).to eq course
      expect(student.period.id).to eq period_1.id

      expect {
        result = CourseMembership::AddStudent.call(period: period_2, role: role)
      }.to_not change{ CourseMembership::Models::Student.count }
      expect(result.errors).to_not be_empty
      expect(student.reload.course).to eq course
      expect(student.period.id).to eq period_1.id
    end
  end
end
