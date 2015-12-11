require 'rails_helper'

describe CourseMembership::IsCourseStudent do

  context "when not a student of the given course" do
    let(:target_course)       { Entity::Course.create! }
    let(:target_period)       { CreatePeriod.call(course: target_course).period }
    let(:other_course)        { Entity::Course.create! }
    let(:other_period)        { CreatePeriod.call(course: other_course).period }
    let(:target_student_role) { Entity::Role.create! }
    let(:other_student_role)  { Entity::Role.create! }

    before(:each) do
      CourseMembership::AddStudent.call(period: other_period,  role: target_student_role)
      CourseMembership::AddStudent.call(period: target_period, role: other_student_role)
    end

    context "when a single role is given" do
      it "returns false" do
        result = CourseMembership::IsCourseStudent.call(course: target_course, roles: target_student_role)
        expect(result.errors).to be_empty
        expect(result.is_course_student).to be_falsey
      end
    end
    context "multiple roles are given" do
      it "returns false" do
        other_role1 = Entity::Role.create!
        other_role2 = Entity::Role.create!
        roles = [target_student_role, other_role1, other_role2]

        result = CourseMembership::IsCourseStudent.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.is_course_student).to be_falsey
      end
    end
    context "when expressed called" do
      it "returns false" do
        is_course_student = CourseMembership::IsCourseStudent[
          course: target_course,
          roles: target_student_role
        ]
        expect(is_course_student).to be_falsey
      end
    end
  end

  context "when a student of the given course" do
    let(:target_course)       { Entity::Course.create! }
    let(:target_period)       { CreatePeriod.call(course: target_course).period }
    let(:target_student_role) { Entity::Role.create! }

    before(:each) do
      CourseMembership::AddStudent.call(period: target_period, role: target_student_role)
    end

    context "when a single role is given" do
      it "returns true" do
        result = CourseMembership::IsCourseStudent.call(course: target_course, roles: target_student_role)
        expect(result.errors).to be_empty
        expect(result.is_course_student).to be_truthy
      end
    end
    context "multiple roles are given" do
      it "returns true" do
        other_role1 = Entity::Role.create!
        other_role2 = Entity::Role.create!
        roles = [target_student_role, other_role1, other_role2]

        result = CourseMembership::IsCourseStudent.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.is_course_student).to be_truthy
      end
    end
    context "when expressed called" do
      it "returns false" do
        is_course_student = CourseMembership::IsCourseStudent[
          course: target_course,
          roles: target_student_role
        ]
        expect(is_course_student).to be_truthy
      end
    end
  end

end
