require 'rails_helper'

RSpec.describe CourseMembership::GetTeachers do
  context "when there are no teachers for the given course" do
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:other_course)  { FactoryBot.create :course_profile_course }
    let(:other_role)    { FactoryBot.create :entity_role }

    before(:each) do
      CourseMembership::AddTeacher.call(course: other_course, role: other_role)
    end

    it "returns an empty array" do
      result = CourseMembership::GetTeachers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.teachers).to be_empty
    end
  end

  context "when there is one teacher for the given course" do
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:target_role)   { FactoryBot.create :entity_role }
    let(:other_course)  { FactoryBot.create :course_profile_course }
    let(:other_role)    { FactoryBot.create :entity_role }

    before(:each) do
      CourseMembership::AddTeacher.call(course: target_course, role: target_role)
      CourseMembership::AddTeacher.call(course: other_course,  role: other_role)
    end

    it "returns an array containing that teacher" do
      result = CourseMembership::GetTeachers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.teachers.size).to eq(1)
      expect(result.outputs.teachers).to include(target_role)
    end

    it "also works when called expressly" do
      expect(CourseMembership::GetTeachers[target_course]).to include(target_role)
    end
  end

  context "when there are multiple teachers for the given course" do
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:target_role1)  { FactoryBot.create :entity_role }
    let(:target_role2)  { FactoryBot.create :entity_role }
    let(:other_course)  { FactoryBot.create :course_profile_course }
    let(:other_role)    { FactoryBot.create :entity_role }

    before(:each) do
      CourseMembership::AddTeacher.call(course: target_course, role: target_role1)
      CourseMembership::AddTeacher.call(course: target_course, role: target_role2)
      CourseMembership::AddTeacher.call(course: other_course,  role: other_role)
    end

    it "returns an array containing those teachers" do
      result = CourseMembership::GetTeachers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.teachers.size).to eq(2)
      expect(result.outputs.teachers).to include(target_role1)
      expect(result.outputs.teachers).to include(target_role2)
    end
  end
end
