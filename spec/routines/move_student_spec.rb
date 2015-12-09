require 'rails_helper'

describe MoveStudent, type: :routine do
  context "when moving an existing student role to another period in the same course" do
    it "succeeds" do
      role = Entity::Role.create!
      course = Entity::Course.create!
      period_1 = CreatePeriod.call(course: course)
      period_2 = CreatePeriod.call(course: course)
      student = CourseMembership::AddStudent.call(period: period_1, role: role)

      result = nil
      expect {
        result = MoveStudent.call(period: period_2, student: student)
      }.to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(student.period.id).to eq period_2.id

      expect {
        result = MoveStudent.call(period: period_1, student: student)
      }.to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(student.period.id).to eq period_1.id
    end
  end

  context "when adding an existing student role to another period in a different course" do
    it "fails" do
      role = Entity::Role.create!
      course_1 = Entity::Course.create!
      course_2 = Entity::Course.create!
      period_1 = CreatePeriod.call(course: course_1)
      period_2 = CreatePeriod.call(course: course_2)
      student = CourseMembership::AddStudent.call(period: period_1, role: role)

      result = nil
      expect {
        result = MoveStudent.call(period: period_2, student: student)
      }.not_to change{ CourseMembership::Models::Enrollment.count }
      expect(result.errors).not_to be_empty

      expect(student.reload.course).to eq course_1
      expect(student.period.id).to eq period_1.id
    end
  end
end
