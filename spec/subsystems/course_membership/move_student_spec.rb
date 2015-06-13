require 'rails_helper'

describe CourseMembership::MoveStudent, type: :routine do
  let!(:course)   { Entity::Course.create! }
  let!(:role)     { Entity::Role.create! }
  let!(:period_1) { CreatePeriod[course: course].to_model }
  let!(:period_2) { CreatePeriod[course: course].to_model }

  context "when moving a new student role to a period" do
    it "fails" do
      period_1_student_count = period_1.students.count
      period_2_student_count = period_2.students.count

      result = nil
      expect {
        result = CourseMembership::MoveStudent.call(period: period_2, role: role)
      }.not_to change{ CourseMembership::Models::Student.count }
      expect(result.errors).not_to be_empty

      expect(period_1.reload.students.count).to eq period_1_student_count
      expect(period_2.reload.students.count).to eq period_2_student_count
    end
  end

  context "when moving an existing student role to a period" do
    it "succeeds" do
      CourseMembership::AddStudent[period: period_1, role: role]
      period_1_student_count = period_1.students.count
      period_2_student_count = period_2.students.count

      student = CourseMembership::Models::Student.order(:created_at).last
      expect(student.period).to eq period_1

      result = nil
      expect {
        result = CourseMembership::MoveStudent.call(period: period_2, role: role)
      }.not_to change{ CourseMembership::Models::Student.count }
      expect(result.errors).to be_empty

      expect(period_1.reload.students.count).to eq period_1_student_count - 1
      expect(period_2.reload.students.count).to eq period_2_student_count + 1

      expect(student.reload.period).to eq period_2

      result = nil
      expect {
        result = CourseMembership::MoveStudent.call(period: period_1, role: role)
      }.not_to change{ CourseMembership::Models::Student.count }
      expect(result.errors).to be_empty

      expect(period_1.reload.students.count).to eq period_1_student_count
      expect(period_2.reload.students.count).to eq period_2_student_count

      expect(student.reload.period).to eq period_1
    end
  end
end
