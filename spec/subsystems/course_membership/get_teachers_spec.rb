require 'rails_helper'

describe CourseMembership::GetTeachers do
  context "when there are no teachers for the given course" do
    let(:target_course) { Entity::Course.create! }
    let(:other_course)  { Entity::Course.create! }
    let(:other_role)    { Entity::Role.create! }

    before(:each) do
      CourseMembership::AddTeacher.call(course: other_course, role: other_role)
    end

    it "returns an empty array" do
      result = CourseMembership::GetTeachers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.teachers).to be_empty
    end
  end

  context "when there is one teacher for the given course" do
    let(:target_course) { Entity::Course.create! }
    let(:target_role)   { Entity::Role.create! }
    let(:other_course)  { Entity::Course.create! }
    let(:other_role)    { Entity::Role.create! }

    before(:each) do
      CourseMembership::AddTeacher.call(course: target_course, role: target_role)
      CourseMembership::AddTeacher.call(course: other_course,  role: other_role)
    end

    it "returns an array containing that teacher" do
      result = CourseMembership::GetTeachers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.teachers.size).to eq(1)
      expect(result.teachers).to include(target_role)
    end

    it "also works when called expressly" do
      expect(CourseMembership::GetTeachers[target_course]).to include(target_role)
    end
  end

  context "when there are multiple teachers for the given course" do
    let(:target_course) { Entity::Course.create! }
    let(:target_role1)  { Entity::Role.create! }
    let(:target_role2)  { Entity::Role.create! }
    let(:other_course)  { Entity::Course.create! }
    let(:other_role)    { Entity::Role.create! }

    before(:each) do
      CourseMembership::AddTeacher.call(course: target_course, role: target_role1)
      CourseMembership::AddTeacher.call(course: target_course, role: target_role2)
      CourseMembership::AddTeacher.call(course: other_course,  role: other_role)
    end

    it "returns an array containing those teachers" do
      result = CourseMembership::GetTeachers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.teachers.size).to eq(2)
      expect(result.teachers).to include(target_role1)
      expect(result.teachers).to include(target_role2)
    end
  end
end
