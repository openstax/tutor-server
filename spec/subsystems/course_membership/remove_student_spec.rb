require 'rails_helper'

describe CourseMembership::RemoveStudent, type: :routine do
  let!(:course)   { Entity::Course.create! }
  let!(:role)     { Entity::Role.create! }
  let!(:period)   { CreatePeriod[course: course].to_model }

  context "when removing a role that is not in a period" do
    it "fails" do
      period_student_count = period.students.count

      result = nil
      expect {
        result = CourseMembership::RemoveStudent.call(role: role)
      }.not_to change{ CourseMembership::Models::Student.count }
      expect(result.errors).not_to be_empty

      expect(period.reload.students.count).to eq period_student_count
    end
  end

  context "when removing an existing student role from a period" do
    it "succeeds" do
      CourseMembership::AddStudent[period: period, role: role]
      expect(role.reload.students).not_to be_empty
      period_student_count = period.students.count

      result = nil
      expect {
        result = CourseMembership::RemoveStudent.call(role: role)
      }.to change{ CourseMembership::Models::Student.count }
      expect(result.errors).to be_empty

      expect(period.reload.students.count).to eq period_student_count - 1
      expect(role.reload.students).to be_empty
    end
  end
end
