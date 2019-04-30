require 'rails_helper'

RSpec.describe CourseMembership::AddTeacher, type: :routine do
  let(:role)     { FactoryBot.create :entity_role, role_type: :teacher }
  let(:course)   { FactoryBot.create :course_profile_course }

  context "when adding a new teacher role to a course" do
    it "succeeds" do
      result = nil
      expect do
        result = described_class.call(course: course, role: role)
      end.to change { CourseMembership::Models::Teacher.count }.by(1)
      expect(result.errors).to be_empty
    end
  end

  context "when adding a existing teacher role to a course" do
    it "fails" do
      result = nil
      expect do
        result = described_class.call(course: course, role: role)
      end.to change { CourseMembership::Models::Teacher.count }.by(1)
      expect(result.errors).to be_empty

      expect do
        result = described_class.call(course: course, role: role)
      end.to_not change { CourseMembership::Models::Teacher.count }
      expect(result.errors).to_not be_empty
    end
  end
end
