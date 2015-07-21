require 'rails_helper'

describe CourseMembership::AddEnrollment, type: :routine do
  context "when adding a new student role to a period" do
    it "succeeds" do
      role = Entity::Role.create!
      course = Entity::Course.create!
      period = CreatePeriod[course: course]
      student = CourseMembership::Models::Student.create(role: role, course: course)

      result = nil
      expect {
        result = CourseMembership::AddEnrollment.call(period: period, student: student)
      }.to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty
    end
  end

  context "when moving an existing student role to another period in the same course" do
    it "succeeds" do
      role = Entity::Role.create!
      course = Entity::Course.create!
      period_1 = CreatePeriod[course: course]
      period_2 = CreatePeriod[course: course]
      student = CourseMembership::AddStudent[period: period_1, role: role]

      result = nil
      expect {
        result = CourseMembership::AddEnrollment.call(period: period_2, student: student)
      }.to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(::Period.new(student.period)).to eq period_2

      expect {
        result = CourseMembership::AddEnrollment.call(period: period_1, student: student)
      }.to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(::Period.new(student.period)).to eq period_1
    end
  end

  context "when adding an existing student role to another period in a different course" do
    it "fails" do
      role = Entity::Role.create!
      course_1 = Entity::Course.create!
      course_2 = Entity::Course.create!
      period_1 = CreatePeriod[course: course_1]
      period_2 = CreatePeriod[course: course_2]
      student = CourseMembership::AddStudent[period: period_1, role: role]

      result = nil
      expect {
        result = CourseMembership::AddEnrollment.call(period: period_2, student: student)
      }.not_to change{ CourseMembership::Models::Enrollment.count }
      expect(result.errors).not_to be_empty

      expect(student.reload.course).to eq course_1
      expect(::Period.new(student.period)).to eq period_1
    end
  end
end
